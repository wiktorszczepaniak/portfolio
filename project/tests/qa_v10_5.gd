extends SceneTree
const Art=preload("res://scripts/combat/combat_art.gd")
const Runtime=preload("res://scripts/combat/skill_runtime.gd")
var checks:=0
var failures:Array=[]
class Dummy:
 extends Node2D
 var targets:Array=[]
 var origin=Vector2(285,582)
 func skill_origin():return origin
 func skill_facing():return 1.0
 func skill_targets():return targets
 func skill_pose(_name,_duration):pass
 func skill_sound(_name):pass
 func skill_spend(_name):return true
 func skill_hit(_e,_d,_id,_stagger,_push):pass
 func skill_dash(_movement,_limit):pass
func check(ok:bool,n:String) -> void:
 checks+=1
 if not ok:failures.append(n);push_error("QA_V10_5_FAIL "+n)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var state=root.get_node("RunBuild")
 state.reset(714);state.muted=true;state.godmode=true
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
 check(game.selected_map=="desert","default desert")
 check(game.stage_ground.get_width()==1024,"desert ground loaded")
 game.select_map("forest")
 check(game.selected_map=="forest" and game.stage_ground.get_width()==256,"forest selection")
 game.select_map("desert")
 check(game.selected_map=="desert" and game.stage_ground.get_width()==1024,"desert reselection")
 game.muted=false
 game._sfx("clone.wav")
 var first_voice:float=float(game.voice_last.get("clone.wav",-1))
 game._sfx("clone.wav")
 check(first_voice>0 and is_equal_approx(first_voice,float(game.voice_last.get("clone.wav",-2))),"no clone voice spam on repeated casts")
 game.queue_free();await process_frame
 check(Art.frames("water_dragon").size()==9,"9-frame true MUGEN Suiryuudan")
 check(Art.frames("hit").size()>=7 and Art.frames("blast").size()>=6,"full hit/explosion animation sets")
 check(FileAccess.file_exists("res://assets/audio/impact.wav"),"physical hit sound")
 var d=Dummy.new();root.add_child(d);var run=Runtime.new();d.add_child(run)
 for lv in range(1,4):
  state.reset(27)
  for j in range(lv):state.grant("oiroke")
  run.setup(d,state,"duel");run.reset()
  check(run.oiroke_points().size()==1+2*(lv-1),"oiroke figures for level "+str(lv))
  run.tick(1.0/60.0)
  check(run.oiroke_time>0 and run.utility_cd>0,"oiroke activates without X level "+str(lv))
 d.queue_free();await process_frame
 state.reset(714);state.godmode=true;state.muted=true
 var duel=load("res://scenes/boss_duel.tscn").instantiate();root.add_child(duel);duel.set_process(false);duel.start_fight()
 check(duel.jumps_remaining==2,"two jumps available")
 duel.jump();check(duel.jumps_remaining==1 and duel.velocity.y<0,"first jump")
 duel.jump();check(duel.jumps_remaining==0 and duel.velocity.y<0,"double jump")
 var before:float=duel.velocity.y;duel.jump();check(duel.jumps_remaining==0 and duel.velocity.y==before,"third jump blocked")
 for i in range(300):duel.step(1.0/60.0,{"move":0.0})
 check(duel.jumps_remaining==2,"jumps restored on landing")
 state.godmode=false
 duel.player_pos=Vector2(285,582);duel.boss.pos=Vector2(970,582);duel.block=false;duel.invulnerable=0.0
 duel.step(1.0/60.0,{"move":-1.0})
 check(duel.retreat_window>0,"retreat direction recognized in physics")
 var guard_hp=duel.player_hp;duel.hurt(50.0)
 check(duel.auto_guard_time>0 and duel.player_hp<guard_hp and duel.player_hp>guard_hp-50,"automatic retreat guard reduces damage without perfect parry")

 state.grant("gama_teppo");state.grant("gama_teppo");state.grant("gama_teppo");state.grant("gama_teppo:suiton_wave")
 duel.skills.reset();check(duel.skills.cast("gama_teppo"),"suiton final cast")
 for i in range(45):duel.skills.tick(1.0/60)
 check(duel.skills.cast_history.has("gama_teppo"),"suiton in arcade independent of melee")
 duel.queue_free();await process_frame
 print("QA_V10_5_DONE checks=",checks," failures=",failures.size()," list=",failures)
 root.get_node("AudioDirector").silence()
 await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)
