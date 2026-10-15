extends RefCounted
## Native melee class controller. No invisible ranged damage or default kunai for Lee / Neji.
const RANGE={"rock_lee":110.0,"neji":104.0}
const BASIC_ACTIONS=["200","210","220"]
static func uses_melee(hero:String)->bool:return hero in ["rock_lee","neji"]
static func begin(g)->bool:
 var hero:String=str(g.alpha.selected)
 if not uses_melee(hero) or not g.melee_64.is_empty():return false
 var reach:float=RANGE[hero]+minf(20.0,float(g.player_form)*7.0)
 var target:Dictionary=g._closest_target(g.player_pos,reach)
 if target.is_empty():return false
 var delta:Vector2=Vector2(target["pos"])-g.player_pos
 if delta.length_squared()>0.01:g.player_facing=-1.0 if delta.x<0 else 1.0
 g.player.facing=g.player_facing
 g.melee_combo=(g.melee_combo+1)%3
 var pose:String=BASIC_ACTIONS[g.melee_combo]
 var duration:float=0.31 if hero=="rock_lee" else 0.35
 var impact:float=duration*(0.38 if hero=="rock_lee" else 0.43)
 g.melee_cast={"hero":hero,"time":0.0,"impact":impact,"duration":duration,"reach":reach,
  "combo":g.melee_combo,"pose":pose,"did_hit":false}
 g.player.play_pose(pose,duration)
 g.kunai_sequence+=1
 return true
static func tick(g,dt:float)->void:
 if not g.melee_64.is_empty():_tick_palms(g,dt)
 if g.melee_cast.is_empty():return
 g.melee_cast["time"]=float(g.melee_cast["time"])+dt
 var data:Dictionary=g.melee_cast
 if not bool(data["did_hit"]) and float(data["time"])>=float(data["impact"]):
  g.melee_cast["did_hit"]=true
  _contact(g,str(data["hero"]),float(data["reach"]),int(data["combo"]))
 if float(g.melee_cast.get("time",0.0))>=float(g.melee_cast.get("duration",0.0)):
  g.melee_cast.clear()
static func _contact(g,hero:String,reach:float,combo:int)->void:
 var contact:Vector2=g.player_pos+Vector2(g.player_facing*47.0,-14)
 var facing:Vector2=Vector2(g.player_facing,0.0)
 var candidates:Array=[]
 for e in g.enemies.duplicate():
  if not g.enemies.has(e):continue
  candidates.append(e)
 if g.boss_active and not g.boss.is_empty():candidates.append(g.boss)
 var landed:bool=false
 for e in candidates:
  if not e.has("pos"):continue
  var d:Vector2=Vector2(e["pos"])-g.player_pos
  if d.length()>reach or d.length()<0.1:continue
  if d.normalized().dot(facing)<0.25:continue
  landed=true
  var damage:float=(30.0+float(combo)*9.0)*g.alpha.damage_multiplier()*(1.0+float(g.player_form)*0.10)
  g._damage_target(e,damage)
  if hero=="neji" and e.has("stagger"):
   e["stagger"]=maxf(float(e.get("stagger",0.0)),0.19+float(combo)*0.04)
  if hero=="rock_lee" and e.has("stagger"):
   e["stagger"]=maxf(float(e.get("stagger",0.0)),0.09)
 if landed:
  if g.fx.size()<g.MAX_FX:g.fx.append({"pos":contact,"kind":"lee_air" if hero=="rock_lee" else "gentle_palm","radius":67.0+float(combo)*8.0,"life":0.22,"max":0.22,"direction":g.player_facing})
  g._sfx("heavy_hit.wav" if combo==2 else "mid_hit.wav" if combo==1 else "impact.wav")
 else:
  g._sfx("swing.wav")
static func start_palms(g,apex:bool=false)->bool:
 if g.alpha.selected!="neji" or not g.melee_64.is_empty():return false
 var target:Dictionary=g._closest_target(g.player_pos,113.0)
 if target.is_empty():return false
 var direction:Vector2=Vector2(target["pos"])-g.player_pos
 if direction.length_squared()<0.01:return false
 g.player_facing=-1.0 if direction.x<0 else 1.0
 g.player.facing=g.player_facing
 g.melee_cast.clear()
 g.melee_64={"time":0.0,"pulses":0,"hits":0,"target":target,"apex":apex}
 g.player.play_pose("220",0.85 if apex else 0.72)
 g._flash("HAKKE 128 PALMS!" if apex else "HAKKE 64 PALMS!",1.0)
 return true
static func _tick_palms(g,dt:float)->void:
 var state:Dictionary=g.melee_64
 state["time"]=float(state["time"])+dt
 var apex:bool=bool(state["apex"])
 var pulses:int=32 if apex else 16
 var interval:float=0.035 if apex else 0.047
 var target:Dictionary=state["target"]
 while int(state["pulses"])<pulses and float(state["time"])>=float(int(state["pulses"])+1)*interval:
  state["pulses"]=int(state["pulses"])+1
  if target.is_empty() or not target.has("pos"):break
  if Vector2(target["pos"]).distance_to(g.player_pos)>131.0:break
  var strike:float=3.2*g.alpha.damage_multiplier()*(1.0+float(g.player_form)*0.12)
  g._damage_target(target,strike*4.0)
  state["hits"]=int(state["hits"])+4
  if target.has("stagger"):target["stagger"]=maxf(float(target.get("stagger",0.0)),0.1)
  if int(state["pulses"])%2==0 and g.fx.size()<g.MAX_FX:
   g.fx.append({"pos":Vector2(target["pos"])+Vector2(0,-18),"kind":"gentle_palm","radius":54.0,"life":0.12,"max":0.12,"direction":g.player_facing})
  if int(state["pulses"])%4==0:g._sfx("impact.wav")
 if int(state["pulses"])>=pulses or target.is_empty() or not target.has("pos") or Vector2(target["pos"]).distance_to(g.player_pos)>131.0:
  g.melee_64.clear()
  if g.fx.size()<g.MAX_FX:g.fx.append({"pos":g.player_pos+Vector2(g.player_facing*47.0,-16),"kind":"gentle_palm","radius":105.0,"life":0.35,"max":0.35,"direction":g.player_facing})
