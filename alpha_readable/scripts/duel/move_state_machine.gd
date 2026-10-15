extends RefCounted
## Time windows use seconds derived from 60 Hz frame data, never a delayed one-shot hit.
const MOVES = [
 {"action":"200", "startup":5, "active":3, "recovery":8, "cancel":11, "damage":1.0, "reach":96.0},
 {"action":"210", "startup":6, "active":3, "recovery":8, "cancel":12, "damage":1.1, "reach":102.0},
 {"action":"220", "startup":9, "active":4, "recovery":11, "cancel":24, "damage":1.6, "reach":112.0}
]
var stage := 0
var age := 0.0
var speed := 1.0
var connected := false
var phase := "idle"
var definition:Dictionary = {}
func start(next_stage:int, rapid:int=0) -> void:
 stage=clampi(next_stage,1,3);definition=MOVES[stage-1];age=0;connected=false
 speed=1.0/maxf(0.65,1.0-0.055*rapid);phase="startup"
func duration() -> float:
 return (float(definition.get("startup",0))+float(definition.get("active",0))+float(definition.get("recovery",0))) / (60.0*speed)
func can_cancel() -> bool:
 return stage>0 and age*60.0*speed>=float(definition.cancel)
func advance(dt:float) -> bool:
 if stage==0:return false
 var previous=age*60.0*speed
 age+=dt
 var frame=age*60.0*speed
 var begin=float(definition.startup)
 var end=begin+float(definition.active)
 # Swept time interval also catches an active window crossed at 30 FPS.
 var contact=not connected and frame>=begin and previous<end
 phase="startup" if frame<begin else "active" if frame<end else "recovery" if age<duration() else "idle"
 return contact
func reset() -> void:
 stage=0;age=0;connected=false;phase="idle";definition={}
