extends SceneTree
## Real Godot CI: exercise every hero, every signature and every apex.
const Moves=preload("res://scripts/combat/alpha_abilities.gd")
var failures:Array[String]=[]
var assertions:=0
class MockBuild:
 extends RefCounted
 func max_hp()->float:return 200.0
class MockBattle:
 extends RefCounted
 var player_pos:=Vector2(100,100)
 var player_facing:=1.0
 var player_hp:=120.0
 var invulnerable:=0.0
 var dash_cooldown:=1.0
 var clone_cooldown:=2.0
 var boss_active:=false
 var boss:Dictionary={}
 var enemies:Array[Dictionary]=[
  {"pos":Vector2(225,100),"hp":200.0,"stagger":0.0},
  {"pos":Vector2(270,165),"hp":180.0,"stagger":0.0},
  {"pos":Vector2(330,205),"hp":140.0,"stagger":0.0}
 ]
 var build=MockBuild.new()
 var hits:=0
 var effects:=0
 var sounds:=0
 var summons:=0
 func _closest_target(_at:Vector2,_range:float)->Dictionary:
  return enemies[0] if not enemies.is_empty() else {}
 func _aoe_damage(_at:Vector2,_radius:float,power:float)->void:
  if power>0.0:hits+=1
 func _add_blast(_at:Vector2,_radius:float,_kind:String="chakra_blast")->void:effects+=1
 func _sfx(_id:String)->void:sounds+=1
 func _spawn_clones()->void:summons+=1
func check(condition:bool,message:String)->void:
 assertions+=1
 if not condition:failures.append(message);push_error(message)
func _initialize()->void:call_deferred("_test")
func _test()->void:
 var alpha=get_root().get_node_or_null("AlphaProgress")
 check(alpha!=null,"autoload AlphaProgress")
 if alpha==null:quit(1);return
 check(Moves.PATTERNS.size()==6,"six hero ability registries")
 var registered:=0
 for hero in alpha.IDS:
  check(Moves.PATTERNS.has(hero),"registered "+hero)
  check(Moves.PATTERNS[hero].size()==6,"six signatures per hero")
  alpha.choose(hero)
  for tree in range(6):
   registered+=1
   var kind:String=Moves.ability_type(hero,tree)
   check(not kind.is_empty(),"nonempty pattern "+hero+"/"+str(tree))
   var game=MockBattle.new()
   check(Moves.activate(game,hero,tree,false,1.0),"cast "+hero+"/"+str(tree))
   check(game.sounds>0,"audio "+hero+"/"+str(tree))
   check(game.hits>0 or game.summons>0,"real mechanic "+hero+"/"+str(tree))
   var advanced=MockBattle.new()
   check(Moves.activate(advanced,hero,tree,true,1.3),"apex cast "+hero+"/"+str(tree))
   check(advanced.hits>=game.hits or advanced.summons>=game.summons,"apex doesn't remove attacks "+hero+"/"+str(tree))
  alpha.reset_run();alpha.level_awarded=20;alpha.points=40
  check(alpha.buy(0,0),"root "+hero)
  check(alpha.buy(0,1),"left fork "+hero)
  check(not alpha.buy(0,2),"exclusive fork "+hero)
  check(alpha.buy(0,3),"left followup "+hero)
  check(alpha.buy(0,5),"signature "+hero)
  check(alpha.buy(0,6),"apex "+hero)
 check(registered==36,"36 runtime-validated class signatures")
 print("ALPHA_ABILITIES_QA: %d checks; %d failures"%[assertions,failures.size()])
 quit(1 if failures.size()>0 else 0)
