extends SceneTree
## P2 real hitframe combat. Do not certify melee if attacks still spawn invisible 600px kunai.
const Combat=preload("res://scripts/combat/alpha_melee.gd")
var failures:Array[String]=[]
var tests:int=0
func check(ok:bool,message:String)->void:
 tests+=1
 if not ok:failures.append(message);push_error("ALPHA_P2 "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 for hero in ["rock_lee","neji"]:
  g.alpha.choose(hero)
  g._start(9001)
  g.enemies.clear()
  var near_actor=g._enemy_actor("sound_heavy",Vector2(70,0),Color.WHITE)
  var far_actor=g._enemy_actor("sound_heavy",Vector2(475,0),Color.WHITE)
  var near={"pos":Vector2(70,0),"hp":1000.0,"max_hp":1000.0,"actor":near_actor,
   "kind":"sound_heavy","elite":false,"stagger":0.0}
  var far={"pos":Vector2(475,0),"hp":1000.0,"max_hp":1000.0,"actor":far_actor,
   "kind":"sound_heavy","elite":false,"stagger":0.0}
  g.enemies.append(near);g.enemies.append(far)
  g.player_pos=Vector2.ZERO
  g.player.position=g.player_pos
  g.player_facing=1.0
  check(Combat.uses_melee(hero),hero+" mode melee")
  check(Combat.begin(g),hero+" attack started near valid target")
  check(g.shots.is_empty(),hero+" did not spawn ranged auto projectiles")
  check(float(near["hp"])==1000.0,hero+" startup does not deal damage")
  for frame in range(40):Combat.tick(g,1.0/120.0)
  check(float(near["hp"])<1000.0,hero+" melee made direct hit")
  check(float(far["hp"])==1000.0,hero+" distant target untouched")
  g.enemies.clear()
  g.melee_cast.clear()
  check(not Combat.begin(g),hero+" cannot swing at far-only target")
  if hero=="neji":
   g.enemies.append(near)
   near["hp"]=1000.0
   check(Combat.start_palms(g,false),"64 Palms has a close locked target")
   for frame in range(100):Combat.tick(g,1.0/120.0)
   check(g.melee_64.is_empty(),"64 Palms finishes")
   check(float(near["hp"])<1000.0,"64 Palms deals close range damage")
   check(float(far["hp"])==1000.0,"64 Palms cannot touch far targets")
  near_actor.queue_free();far_actor.queue_free()
 g.queue_free()
 print("ALPHA_P2_MELEE_QA: %d assertions; %d failed"%[tests,failures.size()])
 quit(1 if not failures.is_empty() else 0)
