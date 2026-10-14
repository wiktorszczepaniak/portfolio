extends SceneTree
const Move=preload("res://scripts/duel/move_state_machine.gd")
const Controls=preload("res://scripts/duel/duel_input.gd")
const Draft=preload("res://scripts/core/upgrade_draft.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
const Runtime=preload("res://scripts/combat/skill_runtime.gd")
const Actor=preload("res://scripts/mugen_actor.gd")
class Dummy:
 extends Node2D
 var targets:Array=[]
 var damage:=0.0
 func skill_origin():return Vector2(300,582)
 func skill_facing():return 1.0
 func skill_targets():return targets
 func skill_pose(_a,_b):pass
 func skill_sound(_a):pass
 func skill_spend(_a):return true
 func skill_dash(_a,_b):pass
 func skill_hit(_e,d,_id,_s,_p):damage+=d
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var build=root.get_node("RunBuild");build.muted=true
 var dummy=Dummy.new();root.add_child(dummy)
 var target=Node2D.new();dummy.add_child(target)
 dummy.targets=[{"actor":target,"pos":Vector2(550,582),"hp":100000.0}]
 var runtime=Runtime.new();dummy.add_child(runtime)
 for a in range(6):
  for b in range(a+1,7):
   for c in range(b+1,8):
    for branch in ["sage","kyubi"]:
     build.reset(99+a*37+b*11+c)
     for i in [a,b,c]:
      for lv in range(3):build.grant(Registry.OFFENSIVE[i])
     build.grant("kage_bunshin");build.form_branch=branch;build.form_stage=2
     var before=build.snapshot();var offer=Draft.new(build).offer()
     check(build.restore(JSON.parse_string(JSON.stringify(before))),"restore valid snapshot")
     check(build.snapshot()==before,"snapshot JSON round trip")
     check(Draft.new(build).offer()==offer,"draft replay")
     for mode in ["survival","duel"]:
      runtime.setup(dummy,build,mode);runtime.reset();dummy.damage=0
      for i in range(3):
       runtime.lock_time=0;check(runtime.cast_slot(i),"combination slot casts")
      for i in range(150):runtime.tick(1.0/60)
      check(dummy.damage>0,"combination damage "+mode+branch)
 dummy.queue_free();await process_frame
 var intact=build.snapshot();var invalid=intact.duplicate(true);invalid.offensive_slots=["rasengan","rasengan",null]
 check(not build.restore(invalid) and build.snapshot()==intact,"reject invalid atomically")
 for fps in [30,60,120]:
  for stage in range(1,4):
   var move=Move.new();move.start(stage)
   var hits=0
   for i in range(fps):
    var before=move.age
    if move.advance(1.0/fps):
     check(move.age*60>=float(move.definition.startup) and before*60<float(move.definition.startup+move.definition.active),"active interval only")
     move.connected=true;hits+=1
   check(hits==1,"single contact per move")
 check(Controls.retreat(-1,100,200) and Controls.retreat(1,200,100),"guard relative to opponent")
 check(not Controls.retreat(1,100,200) and not Controls.retreat(-1,200,100),"forward never guards")
 build.reset(444);build.muted=true;build.godmode=true
 var duel=load("res://scenes/boss_duel.tscn").instantiate();root.add_child(duel);duel.set_process(false);duel.start_fight()
 duel.player_pos.x=700;duel.boss.pos.x=780;duel.player_facing=1;duel.start_combo()
 var hp=float(duel.boss.hp)
 duel.step(1.0/60,{"move":0.0})
 check(float(duel.boss.hp)==hp,"no startup damage")
 for i in range(15):duel.step(1.0/60,{"move":0.0})
 check(float(duel.boss.hp)<hp,"active melee damage")
 check(duel.action_log.any(func(e):return e.event=="contact"),"contact log")
 duel.hitstop=0;duel.hurt_time=0;duel.invulnerable=0;build.godmode=false;duel.start_combo();duel.hurt(10)
 check(duel.attack_time==0 and duel.melee.stage==0,"hurt interrupts melee")
 duel.invulnerable=0;duel.hurt_time=0;duel.player_facing=1;duel.block=true;duel.block_age=0.4
 var hp_front=duel.player_hp;duel.hurt(30,false,false,duel.player_pos.x+100)
 var front_damage=hp_front-duel.player_hp
 duel.invulnerable=0;duel.block=true;duel.block_age=0.4
 var hp_back=duel.player_hp;duel.hurt(30,false,false,duel.player_pos.x-100)
 check(hp_back-duel.player_hp>front_damage*2,"behind attack bypasses guard")
 duel.queue_free();await process_frame
 for pack in ["naruto_base","naruto_kyubi","naruto_kcm","naruto_sage","naruto_sennin"]:
  var actor=Actor.new();actor.pack_name=pack;root.add_child(actor)
  for action in ["200","210","220"]:
   actor.play_pose(action,0.6)
   var visited={}
   for i in range(35):actor.tick(1.0/60);visited[actor.atlas_frame]=true
   check(visited.size()==actor.actions[action].size(),"complete melee sequence "+pack+action)
  actor.pose_action="41";actor.pose_time=0.1;actor.tick(1.0/60)
  var progressed=false
  for i in range(30):
   actor.pose_time=0.1;actor.tick(1.0/60)
   if actor.atlas_frame>0:progressed=true
  check(progressed or actor.actions["41"].size()==1,"sustained jump never restarts")
  actor.queue_free();await process_frame
 print("QA_V11_DONE checks=",checks," failures=",failures.size()," list=",failures)
 quit(0 if failures.is_empty() else 1)
