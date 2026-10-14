extends RefCounted
static func swept_hit(a:Vector2,b:Vector2,c:Vector2,r:float) -> bool:return Geometry2D.get_closest_point_to_segment(c,a,b).distance_squared_to(c)<=r*r
static func can_hit(log:Dictionary,key:int,time:float,interval:float) -> bool:
 if log.has(key) and (interval<=0 or time-float(log[key])<interval):return false
 log[key]=time;return true
static func mitigated(damage:float,build) -> float:return damage*(1.0-0.09*float(build.passives.get("survivor_instinct",0)))
