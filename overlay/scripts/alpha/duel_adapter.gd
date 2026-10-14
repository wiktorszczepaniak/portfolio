extends "res://scripts/combat/duel_skill_adapter.gd"
## Alpha extension of the battle adapter. Original Naruto execution remains unchanged.
const Roster=preload("res://scripts/alpha/roster.gd")
const Patterns=preload("res://scripts/alpha/combat_patterns.gd")
var hero_id:="naruto"
func set_hero(value:String) -> void:
 hero_id=value if value in Roster.IDS else "naruto"
func activate(c:Dictionary) -> void:
 if hero_id=="naruto":
  super.activate(c)
 else:
  Patterns.activate(self,c,hero_id)
func utility() -> bool:
 if hero_id=="naruto":return super.utility()
 if build.utility_id=="" or utility_cd>0:return false
 utility_cd=build.cooldown(build.utility_id,mode)
 var pos:Vector2=host.skill_origin()
 var lv=int(build.levels.get(build.utility_id,1))
 var action_index=["kage_bunshin","oiroke","gamakichi_support","bunshin_decoy"].find(build.utility_id)
 host.skill_pose("210",.35)
 match action_index:
  0:
   support_time=2.8+float(lv);support_charges=4+lv*2;support_pos=pos
   effect("chakra",pos,102,0.6)
  1:
   counter_time=1.1+float(lv)*.5
   area(pos,95+lv*32,18*lv,build.utility_id,0.43)
   effect("wind",pos,160+lv*18,0.54)
  2:
   support_time=3.0+float(lv);support_charges=4+lv*3;support_pos=pos
   effect("sand" if hero_id=="gaara" else "chakra",pos,150,0.55)
  3:
   decoy_pos=pos;decoy_time=3.0+lv;counter_time=1.0+lv*.3
   effect("smoke",pos,120,0.52)
 host.skill_sound("chakra_charge.wav")
 return true
