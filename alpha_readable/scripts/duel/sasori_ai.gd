extends RefCounted
var host
var phase:=1
var state:="recover"
var timer:=1.6
var pattern:=""
var action_index:=0
var segment:=0
var aim:=Vector2.ZERO
var cc_immunity:=0.0
var stagger:=0.0
var phase_pause:=0.0
var history:Array=[]
const PATTERNS={
 "senbon":{"warning":0.8,"active":0.3,"recovery":2.1,"waves":3,"label":"SALWY SENBON · BLOK / SKOK"},
 "tail":{"warning":0.85,"active":0.34,"recovery":2.5,"waves":2,"label":"PODWÓJNY OGON · PRZESKOCZ"},
 "poison":{"warning":1.05,"active":0.25,"recovery":2.3,"waves":3,"label":"TRUJĄCY ŚLAD · ZMIENIAJ POZYCJĘ"},
 "sand_sweep":{"warning":0.85,"active":0.4,"recovery":2.7,"waves":3,"label":"FALE SATETSU · SKOK, LĄDOWANIE, SKOK"},
 "cross":{"warning":0.95,"active":0.6,"recovery":2.5,"waves":2,"label":"KRZYŻOWY OSTRZAŁ · BLOK / KAWARIMI"},
 "lances":{"warning":0.9,"active":0.4,"recovery":2.6,"waves":3,"label":"WŁÓCZNIE · WYJDŹ Z OZNACZEŃ"},
 "air_counter":{"warning":0.85,"active":0.3,"recovery":2.1,"waves":2,"label":"WACHLARZ IGIEŁ · ZMIEŃ WYSOKOŚĆ"},
 "needle_fan":{"warning":0.9,"active":0.4,"recovery":2.4,"waves":3,"label":"WACHLARZ HIRUKO · SKOK / BLOK"},
 "iron_rain":{"warning":1.2,"active":0.5,"recovery":3.0,"waves":3,"label":"ŻELAZNY DESZCZ · ZIELONA LUKA"},
 "puppet_sweep":{"warning":1.0,"active":0.45,"recovery":2.8,"waves":3,"label":"NICI MARIONETEK · PRZESKOCZ FALĘ"}}
func _init(owner_node):host=owner_node
func reset() -> void:phase=1;state="recover";timer=1.6;action_index=0;segment=0;phase_pause=0;cc_immunity=0;stagger=0;history.clear()
func prepare_segment() -> void:
 aim=host.skills.decoy_pos if host.skills.decoy_time>0 else host.player_pos
 if pattern=="iron_rain":aim.x=[290.0,640.0,990.0][(action_index+segment)%3]
 state="telegraph";timer=PATTERNS[pattern].warning
 host.skill_sound("boss_tell.wav")
 host.announce("%s  %d/%d"%[PATTERNS[pattern].label,segment+1,PATTERNS[pattern].waves],timer+.15)
 host.boss.actor.play_pose("210" if pattern=="tail" else "200",timer+.4)
func tick(dt:float) -> void:
 cc_immunity=maxf(0,cc_immunity-dt);stagger=maxf(0,stagger-dt)
 if phase_pause>0:phase_pause=maxf(0,phase_pause-dt);return
 if stagger>0:return
 timer-=dt
 # Recovery is a genuine stationary punish window; never flee from melee.
 if timer>0:return
 if state=="recover":
  var cycle=["senbon","tail","needle_fan","poison","tail"] if phase==1 else ["sand_sweep","lances","iron_rain","cross","puppet_sweep","needle_fan"]
  pattern=cycle[action_index%cycle.size()];action_index+=1;segment=0
  if pattern=="tail" and absf(host.boss.pos.x-host.player_pos.x)>350:pattern="needle_fan"
  history.append(pattern);prepare_segment()
 elif state=="telegraph":
  state="active";timer=PATTERNS[pattern].active;host.boss_attack(pattern,aim)
 elif state=="active":
  segment+=1
  if segment<int(PATTERNS[pattern].waves):prepare_segment()
  else:state="recover";timer=PATTERNS[pattern].recovery;host.announce("OTWARCIE!  F / LPM · KOMBINACJA",timer)
func phase_two() -> void:phase=2;phase_pause=2;state="recover";timer=1.4;stagger=0;cc_immunity=2.5;action_index=0;segment=0
func interrupt(duration:float) -> bool:
 if phase_pause>0 or cc_immunity>0:return false
 if state=="telegraph" and pattern in ["senbon","poison","lances","air_counter","needle_fan"]:
  state="recover";timer=1.7;stagger=minf(0.55,duration);cc_immunity=4.8;host.announce("PRZERWANIE / KONTRATAK",1.7);return true
 return false
func label() -> String:
 if phase_pause>0:return "FAZA II / MISTRZ MARIONETEK"
 return "OKNO NA KONTRATAK" if state=="recover" else PATTERNS.get(pattern,{}).get("label","")
