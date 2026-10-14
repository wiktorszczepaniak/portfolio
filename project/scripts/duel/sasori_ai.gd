extends RefCounted
var host
var phase:=1
var state:="recover"
var timer:=1.6
var pattern:=""
var action_index:=0
var aim:=Vector2.ZERO
var cc_immunity:=0.0
var stagger:=0.0
var phase_pause:=0.0
var history:Array=[]
const PATTERNS={"senbon":{"warning":0.72,"active":0.35,"recovery":1.25,"label":"SENBON  •  BLOKUJ"},"tail":{"warning":0.85,"active":0.3,"recovery":1.55,"label":"OGON HIRUKO  •  ODSKOCZ"},"poison":{"warning":1.05,"active":0.35,"recovery":1.55,"label":"TRUCIZNA  •  ZMIEŃ POZYCJĘ"},"sand_sweep":{"warning":0.95,"active":0.65,"recovery":1.55,"label":"ŻELAZNY PIASEK  •  SKOCZ"},"cross":{"warning":0.85,"active":0.5,"recovery":1.7,"label":"ATAK KRZYŻOWY  •  KAWARIMI"},"lances":{"warning":1.1,"active":0.4,"recovery":1.5,"label":"WŁÓCZNIE SATETSU  •  UCIEKAJ"},"air_counter":{"warning":0.6,"active":0.25,"recovery":1.25,"label":"IGŁY W POWIETRZU  •  BLOKUJ"}}
func _init(owner_node):host=owner_node
func reset() -> void:phase=1;state="recover";timer=1.6;action_index=0;phase_pause=0;cc_immunity=0;stagger=0;history.clear()
func tick(dt:float) -> void:
 cc_immunity=maxf(0,cc_immunity-dt);stagger=maxf(0,stagger-dt)
 if phase_pause>0:phase_pause=maxf(0,phase_pause-dt);return
 if stagger>0:return
 timer-=dt
 if state=="recover":
  var distance:float=host.boss.pos.x-host.player_pos.x;var movement:=0.0
  if absf(distance)<240:movement=signf(distance)*95*dt
  elif absf(distance)>510:movement=-signf(distance)*80*dt
  if float(host.boss.get("slowed_until",0))>host.skills.clock:movement*=0.62
  host.boss.pos.x=clampf(host.boss.pos.x+movement,90,1190)
 if timer>0:return
 if state=="recover":
  var cycle=["senbon","tail","senbon","poison"] if phase==1 else ["sand_sweep","cross","lances","senbon","poison"]
  pattern=cycle[action_index%cycle.size()];action_index+=1
  if host.player_pos.y<host.FLOOR-70 and action_index%3==0:pattern="air_counter"
  if pattern=="tail" and absf(host.boss.pos.x-host.player_pos.x)>350:pattern="senbon"
  aim=host.skills.decoy_pos if host.skills.decoy_time>0 else host.player_pos
  state="telegraph";timer=PATTERNS[pattern].warning;history.append(pattern);host.announce(PATTERNS[pattern].label,timer+0.3)
  host.boss.actor.pose_action="210" if pattern=="tail" else "200";host.boss.actor.pose_time=timer+0.4;host.skill_sound("boss.wav")
 elif state=="telegraph":state="active";timer=PATTERNS[pattern].active;host.boss_attack(pattern,aim)
 elif state=="active":state="recover";timer=PATTERNS[pattern].recovery
func phase_two() -> void:phase=2;phase_pause=2;state="recover";timer=1.4;stagger=0;cc_immunity=2.5;action_index=0
func interrupt(duration:float) -> bool:
 if phase_pause>0 or cc_immunity>0:return false
 if state=="telegraph" and pattern in ["senbon","poison","lances","air_counter"]:
  state="recover";timer=0.85;stagger=minf(0.55,duration);cc_immunity=4.8;host.announce("PRZERWANIE  /  OKNO NA KONTRĘ",1.1);return true
 return false
func label() -> String:
 if phase_pause>0:return "FAZA II  /  MISTRZ MARIONETEK"
 return "OKNO NA KONTRATAK" if state=="recover" else PATTERNS.get(pattern,{}).get("label","")
