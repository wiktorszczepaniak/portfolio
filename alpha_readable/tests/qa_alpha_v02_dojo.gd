extends SceneTree
## P9 training room headless smoke test. No forced boss/automatic enemy waves.
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error("DOJO_QA "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var alpha=root.get_node_or_null("AlphaProgress")
 alpha.choose("rock_lee")
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 g.start_training()
 check(g.playing and g.training_mode,"dojo starts from character menu")
 check(g.godmode,"training is invulnerable")
 check(g.enemies.size()==3,"three target mannequins")
 check(g.build.owned().size()==3,"three equipped test jutsu")
 check(alpha.points>=75,"skill constellation test budget")
 var before:float=g.clock
 g.speed_index=5
 for n in range(6):g._process(1.0/60.0)
 check(g.clock>before+0.3,"clock simulation and x5 active in dojo")
 check(not g.form_choice and not g.gacha_active,"no involuntary scroll prompts in dojo")
 check(not g.boss_active,"no forced boss in dojo")
 check(g.enemies.size()==3,"test targets persist")
 g.training_form("sage",1)
 check(g.player_form==1,"form one manual preview")
 g.training_form("kyubi",2)
 check(g.player_form==2,"form two manual preview")
 check(g.has_method("return_to_menu"),"safe menu return path")
 g.queue_free()
 print("ALPHA_DOJO_QA: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if not failures.is_empty() else 0)
