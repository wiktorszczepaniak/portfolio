extends SceneTree
const Heroes=preload("res://scripts/alpha/roster.gd")
const Patterns=preload("res://scripts/alpha/combat_patterns.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
class MockHost:
 extends RefCounted
 var sounds:Array=[]
 var distance:=0.0
 func skill_sound(name:String)->void:sounds.append(name)
 func skill_origin() -> Vector2:return Vector2.ZERO
 func skill_dash(v:Vector2,_max_dist:float) -> void:distance+=v.length()
class MockRuntime:
 extends RefCounted
 var host=MockHost.new()
 var mode:="duel"
 var render_scale:=1.0
 var counter_time:=0.0
 var damage:=0.0
 var events:Array=[]
 func area(pos:Vector2,r:float,dmg:float,id:String,stagger:float=0.0,push:Vector2=Vector2.ZERO) -> void:
  events.append("area");damage+=dmg
 func projectile(id:String,art:String,pos:Vector2,dir:Vector2,speed:float,dmg:float,radius:float,life:float,extra:Dictionary={}) -> void:
  events.append("projectile");damage+=dmg
 func trap(pos:Vector2,delay:float,radius:float,dmg:float,id:String,art:String,evo:String="") -> void:
  events.append("trap");damage+=dmg
 func effect(art:String,pos:Vector2,width:float,life:float,angle:float=0.0)->void:
  events.append("effect")
var checks:=0
var errors:Array=[]
func verify(ok:bool,message:String)->void:
 checks+=1
 if not ok:errors.append(message)
func _initialize()->void:
 for id in Heroes.IDS:
  if id=="naruto":continue
  for family in Heroes.SLOT_IDS:
   for path in [-1,0,1]:
    var rt=MockRuntime.new()
    var evo=""
    if path>=0:evo=Registry.DATA[family].evolutions[path]
    var cast={"id":family,"point":Vector2(100,40),"origin":Vector2.ZERO,"dir":Vector2.RIGHT,"lv":3,"evo":evo,"power":1.3}
    Patterns.activate(rt,cast,id)
    verify(not rt.events.is_empty(),"no combat events %s/%s/%d"%[id,family,path])
    verify(rt.damage>0,"zero damage %s/%s/%d"%[id,family,path])
    verify(rt.host.sounds.size()==1,"missing synchronized SFX %s/%s/%d"%[id,family,path])
    if family in ["kunai_kibaku","kuchiyose"]:verify("trap" in rt.events,"missing timed trap %s/%s"%[id,family])
    if family in ["fuma_shuriken","shuriken_barrage","gama_teppo"]:verify("projectile" in rt.events,"missing real projectile %s/%s"%[id,family])
 var rt=MockRuntime.new()
 Patterns.activate(rt,{"id":"rasengan","point":Vector2.ZERO,"origin":Vector2.ZERO,"dir":Vector2.RIGHT,"lv":3,"evo":"","power":1.0},"naruto")
 verify(rt.events.is_empty(),"original Naruto implementation must remain owner")
 print("ALPHA COMBAT QA %d checks / %d failures"%[checks,errors.size()])
 for msg in errors:push_error(msg)
 quit(0 if errors.is_empty() else 1)
