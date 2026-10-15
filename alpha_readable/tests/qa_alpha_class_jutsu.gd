extends SceneTree
## Tests ALL eight jutsu slots for all five non-Naruto heroes.
## Regression: every non-Naruto hero casts four personal jutsu through real Godot SkillRuntime.
const Runtime=preload("res://scripts/combat/skill_runtime.gd")
class MockHost:
 extends Node2D
 var actor:=Node2D.new()
 var victims:Array[Dictionary]=[{"pos":Vector2(180,100),"hp":900.0,"actor":Node2D.new()}]
 var sounds:Array[String]=[]
 func skill_origin()->Vector2:return Vector2(100,100)
 func skill_facing()->float:return 1.0
 func skill_targets()->Array:return victims
 func skill_pose(_pose:String,_time:float)->void:pass
 func skill_sound(sound:String)->void:sounds.append(sound)
 func skill_dash(_distance:Vector2,_limit:float)->void:pass
 func skill_hit(enemy:Dictionary,damage:float,_id:String,_stagger:float,_push:Vector2)->void:
  enemy["hp"]=float(enemy["hp"])-damage
var checks:=0
var errors:Array[String]=[]
func verify(ok:bool,desc:String)->void:
 checks+=1
 if not ok:errors.append(desc);push_error("ALPHA_CLASS_QA "+desc)
func _initialize()->void:call_deferred("_run")
func _run()->void:
 var alpha=get_root().get_node_or_null("AlphaProgress")
 var build=get_root().get_node_or_null("RunBuild")
 verify(alpha!=null and build!=null,"autoloads")
 if alpha==null or build==null:quit(1);return
 var saved:String=alpha.selected
 var host=MockHost.new()
 get_root().add_child(host)
 var runtime=Runtime.new()
 get_root().add_child(runtime)
 runtime.setup(host,build,"survival")
 var tested:int=0
 for hero in ["sasuke","kakashi","rock_lee","neji","gaara"]:
  verify(alpha.choose(hero),"choose "+hero)
  for spell in ["rasengan","naruto_rendan","fuma_shuriken","shuriken_barrage","kunai_kibaku","kuchiyose","henge_feint","gama_teppo"]:
   runtime.reset()
   var command:Dictionary={
    "id":spell,"origin":Vector2(100,100),"point":Vector2(180,100),
    "dir":Vector2.RIGHT,"lv":2,"evo":"","power":1.0
   }
   runtime.activate(command)
   var actions:int=runtime.effects.size()+runtime.traps.size()+runtime.projectiles.size()
   verify(actions>0,"working cast "+hero+"/"+spell)
   for fx in runtime.effects:
    verify(str(fx.art) not in ["frog","bunta","oiroke"],"no wrong MUGEN art "+hero+"/"+spell)
   if hero in ["rock_lee","neji"]:
    verify(runtime.projectiles.is_empty(),"no auto ranged ninja weapon in melee class "+hero+"/"+spell)
   for bullet in runtime.projectiles:
    verify(str(bullet.art) not in ["water","water_dragon"],"no mismatched water "+hero+"/"+spell)
   tested+=1
 verify(tested==40,"40 class-specific slot casts")
 alpha.choose(saved)
 print("ALPHA_CLASS_JUTSU_QA: %d checks, %d failed, %d casts"%[checks,errors.size(),tested])
 quit(1 if errors.size()>0 else 0)
