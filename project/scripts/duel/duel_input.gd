extends RefCounted
static func commands(overrides:Dictionary) -> Dictionary:
 var result={"move":float(int(Input.is_physical_key_pressed(KEY_D))-int(Input.is_physical_key_pressed(KEY_A))),"block":Input.is_physical_key_pressed(KEY_S)}
 result.merge(overrides,true)
 return result
static func retreat(direction:float,player_x:float,enemy_x:float) -> bool:
 return direction!=0 and (enemy_x-player_x)*direction<0
