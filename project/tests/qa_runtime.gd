extends SceneTree
const Registry=preload("res://scripts/core/jutsu_registry.gd")
const Draft=preload("res://scripts/core/upgrade_draft.gd")
const Runtime=preload("res://scripts/combat/skill_runtime.gd")
const Resolver=preload("res://scripts/combat/combat_resolver.gd")
var checks:=0
var failures:Array=[]
var state
class Dummy:
 extends Node2D
 var targets:Array=[]
 var origin=Vector2(300,582)
 var damage:=0.0
 func skill_origin():return origin
 func skill_facing():return 1.0
 func skill_targets():return targets
 func skill_pose(_a,_b):pass
 func skill_sound(_a):pass
 func skill_spend(_a):return true
 func skill_dash(v,_b):origin+=v
 func skill_hit(_e,d,_id,_s,_p):damage+=d
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 state=root.get_node("RunBuild");state.muted=true
 for seed_value in [17,42,2026]:
  for a in range(6):
   for b in range(a+1,7):
    for c in range(b+1,8):
     state.reset(seed_value)
     for index in [a,b,c]:state.grant(Registry.OFFENSIVE[index])
     var draft=Draft.new(state)
     for n in range(12):
      var offer=draft.offer();var seen={}
      for id in offer:check(state.legal(id),"legal "+id);seen[id]=true
      check(seen.size()==offer.size(),"unique draft");check(state.owned().size()==3,"three slots")
      state.grant(offer[0])
 state.reset(1);check(state.owned().is_empty(),"empty start")
 var dummy=Dummy.new();root.add_child(dummy)
 var target=Node2D.new();dummy.add_child(target)
 var skill=Runtime.new();dummy.add_child(skill)
 var damage_results={}
 for mode in ["survival","duel"]:
  for id in Registry.OFFENSIVE:
   for evo in [""]+Registry.DATA[id].evolutions:
    state.reset(5)
    for i in range(3):state.grant(id)
    if evo!="":state.grant(id+":"+evo)
    dummy.origin=Vector2(300,582);dummy.damage=0;dummy.targets=[{"actor":target,"pos":Vector2(550,582),"hp":100000.0}]
    skill.setup(dummy,state,mode);skill.reset();check(skill.cast(id),"cast "+mode+id+evo)
    for i in range(240):skill.tick(1.0/60)
    check(dummy.damage>0,"damage "+mode+id+evo);damage_results[mode+"/"+id+"/"+evo]=dummy.damage
 for id in Registry.UTILITY:
  state.reset(1);state.grant(id);skill.reset();skill.setup(dummy,state,"duel")
  check(skill.utility(),"utility "+id);check(not skill.utility(),"utility cooldown "+id)
  if id=="gamakichi_support":check(skill.intercept(dummy.origin),"support intercept")
 check(Resolver.swept_hit(Vector2.ZERO,Vector2(1000,0),Vector2(500,0),5),"swept collision")
 dummy.queue_free();await process_frame
 var duel=load("res://scenes/boss_duel.tscn").instantiate();root.add_child(duel);duel.set_process(false)
 state.godmode=false;duel.start_fight();duel.invulnerable=0;duel.block=true;duel.block_age=0.05
 var hp=duel.player_hp;duel.hurt(50);check(duel.player_hp==hp and duel.parries==1,"perfect block")
 duel.invulnerable=0;duel.block_age=1;duel.hurt(50);check(is_equal_approx(hp-duel.player_hp,12),"block chip")
 duel.finished=true;duel.victory=false;state.retry_used=false;var snapshot=state.offensive_slots.duplicate();duel.retry();check(state.retry_used and not duel.finished and snapshot==state.offensive_slots,"retry keeps build")
 duel.finished=true;duel.retry();check(duel.finished,"retry once")
 duel.queue_free();await process_frame
 var teams=[["naruto_rendan","henge_feint","kuchiyose"],["fuma_shuriken","shuriken_barrage","gama_teppo"],["rasengan","kunai_kibaku","henge_feint"]]
 var battles=[]
 for team in teams:
  state.reset(42);state.godmode=true;state.muted=true;state.form_branch="sage";state.form_stage=2
  for id in team:
   for i in range(3):state.grant(id)
   state.grant(id+":"+Registry.DATA[id].evolutions[0])
  state.grant("kage_bunshin")
  duel=load("res://scenes/boss_duel.tscn").instantiate();root.add_child(duel);duel.set_process(false);duel.start_fight()
  for i in range(36000):
   var distance=duel.boss.pos.x-duel.player_pos.x
   duel.step(1.0/60,{"move":signf(distance) if absf(distance)>90 else 0.0,"combo":true,"slot":int(i/30)%3,"utility":i%60==0})
   if duel.finished:break
  check(duel.victory,"two phases team "+str(team));check(duel.phase_damage[0]>0 and duel.phase_damage[1]>0,"both phases damage")
  battles.append({"team":team,"won":duel.victory,"seconds":duel.elapsed,"patterns":duel.ai.history})
  duel.queue_free();await process_frame
 var missions=[]
 for fps in [30,60,120]:
  var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game;game.set_process(false);game._start();game.godmode=true;game.muted=true;state.rng_seed=fps
  var iterations=0
  while game.transition_time<0 and iterations<fps*530:
   if game.form_choice:game._choose_form(1 if fps==60 else 0)
   if game.picking:game._choose_card(0)
   if game.gacha_active:game.gacha_revealed=true;game._choose_chest_reward(0)
   game._process(1.0/fps);iterations+=1
   if iterations%240==0:await process_frame
  check(game.transition_time>=0,"480s transition "+str(fps));check(state.owned().size()==3 and state.utility_id!="" and state.form_stage==2,"full mission build "+str(fps))
  var before=state.snapshot();game._process(2.2);await process_frame;await process_frame
  check(current_scene!=null and current_scene.has_method("start_fight"),"actual scene switch")
  if current_scene!=null and current_scene.has_method("start_fight"):
   current_scene.set_process(false);check(current_scene.before_duel==before,"identical transfer "+str(fps));current_scene.queue_free();current_scene=null;await process_frame
  missions.append({"fps":fps,"build":before})
 var result={"checks":checks,"failures":failures,"damage":damage_results,"battles":battles,"missions":missions}
 var args=OS.get_cmdline_user_args();var output=args[0] if args.size()>0 else "user://qa_runtime.json"
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print("QA_DONE checks=",checks," failures=",failures.size()," output=",output);quit(0 if failures.is_empty() else 1)
