extends RefCounted
## Pure wave policy; scene owns RNG and spawned actors.
static func wave(clock:float,boss_time:float,miniboss:bool) -> Dictionary:
 var phase=clampf(clock/boss_time,0.0,1.0)
 var amount=1 if clock<50.0 else 2 if phase<0.30 else 3
 if clock>350.0 and int(clock)%36<11:amount+=1
 if miniboss:amount=maxi(1,amount-1)
 return {"maximum":23+int(phase*72.0),"amount":amount,"interval":lerpf(2.1,0.90,pow(phase,0.78))}
