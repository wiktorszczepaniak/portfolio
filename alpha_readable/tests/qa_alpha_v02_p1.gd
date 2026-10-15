extends SceneTree
## Alpha 0.2 P1 native regression: controlled speed and defective MUGEN idle manifest.
var errors:Array[String]=[]
var assertions:int=0
func check(ok:bool,what:String)->void:
 assertions+=1
 if not ok:errors.append(what);push_error("ALPHA_02_P1 "+what)
func _initialize()->void:call_deferred("run_p1")
func run_p1()->void:
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/mugen/sasuke/manifest.json"))
 check(manifest is Dictionary,"Sasuke manifest parses")
 if manifest is Dictionary:
  var idle:Array=manifest.get("actions",{}).get("0",[])
  check(not idle.is_empty(),"Sasuke idle frames")
  for frame in idle:check(not bool(frame.get("flip_h",false)),"Sasuke neutral idle cannot flip horizontally")
 var actor_script=FileAccess.get_file_as_string("res://scripts/combat/ninja_fx.gd")
 check(not actor_script.contains("Color(.22,.24,.29,alpha)"),"old gray sand renderer removed")
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 var expected:Array=[1.0,1.5,2.0,3.0,4.0,5.0]
 check(g.speeds.size()==expected.size(),"six speeds including x5")
 for i in range(expected.size()):check(absf(float(g.speeds[i])-float(expected[i]))<0.001,"speed value "+str(i))
 check(g.has_method("return_to_menu"),"return to menu available")
 g._start(912345)
 g.muted=true
 g.godmode=true
 g.speed_index=5
 var before:float=g.clock
 for i in range(10):g._process(1.0/60.0)
 var elapsed:float=g.clock-before
 check(elapsed>=0.7 and elapsed<=0.95,"fivefold game clock should advance about 0.833s in 10 rendered frames, got "+str(elapsed))
 check(g.simulation_accumulator>=0 and g.simulation_accumulator<0.035,"no accumulating speed backlog")
 g.paused=true
 var old_clock:float=g.clock
 g._process(1.0/60.0)
 check(is_equal_approx(g.clock,old_clock),"time frozen in pause")
 var duel_script=FileAccess.get_file_as_string("res://scripts/duel/boss_duel.gd")
 check(duel_script.contains("func return_to_menu"),"duel also has return-to-menu")
 g.queue_free()
 print("ALPHA_02_P1: %d assertions, %d failures"%[assertions,errors.size()])
 quit(1 if not errors.is_empty() else 0)
