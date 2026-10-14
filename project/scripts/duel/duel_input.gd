extends RefCounted
var queued:Dictionary={}
func push(key:int) -> void:
 if key in [KEY_J,KEY_K,KEY_L]:queued.slot=[KEY_J,KEY_K,KEY_L].find(key)
 elif key==KEY_F:queued.combo=true
 elif key==KEY_X:queued.utility=true
 elif key==KEY_W:queued.jump=true
 elif key==KEY_SHIFT:queued.dash=true
func consume(overrides:Dictionary) -> Dictionary:
 var result=commands(queued);result.merge(overrides,true);queued.clear();return result
static func commands(overrides:Dictionary) -> Dictionary:
 var result={"move":float(int(Input.is_physical_key_pressed(KEY_D))-int(Input.is_physical_key_pressed(KEY_A))),"block":Input.is_physical_key_pressed(KEY_S)}
 result.merge(overrides,true)
 return result
static func retreat(direction:float,player_x:float,enemy_x:float) -> bool:
 return direction!=0 and (enemy_x-player_x)*direction<0
