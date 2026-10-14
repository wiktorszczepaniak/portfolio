extends SceneTree
const Move=preload("res://scripts/duel/move_state_machine.gd")
const Controls=preload("res://scripts/duel/duel_input.gd")
const Draft=preload("res://scripts/core/upgrade_draft.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var build=root.get_node("RunBuild");build.muted=true
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
 duel.queue_free();await process_frame
 print("QA_V11_DONE checks=",checks," failures=",failures.size()," list=",failures)
 quit(0 if failures.is_empty() else 1)
