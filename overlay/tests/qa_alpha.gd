extends SceneTree
## Full Alpha roster/tree integrity check. Uses real Godot 4.5.2 engine.
var assertions:=0
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
 assertions+=1
 if not ok:failures.append(message);push_error("ALPHA QA: "+message)
func _initialize()->void:
 call_deferred("test_all")
func test_all()->void:
 var alpha=get_root().get_node_or_null("AlphaProgress")
 check(alpha!=null,"AlphaProgress autoload missing")
 if alpha==null:quit(1);return
 check(alpha.IDS.size()==6,"6 class IDs")
 var previous:String=alpha.selected
 for id in alpha.IDS:
  check(alpha.choose(id),"select "+id)
  var hero:Dictionary=alpha.hero()
  check(hero.has("pack"),"pack "+id)
  var path:String="res://assets/mugen/%s/manifest.json"%hero["pack"]
  check(FileAccess.file_exists(path),"MUGEN manifest "+path)
  if FileAccess.file_exists(path):
   var manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
   check(manifest is Dictionary,"parse "+id)
   if manifest is Dictionary:
    for a in ["0","20","100","200","5000"]:
     check(manifest["actions"].has(a) and not manifest["actions"][a].is_empty(),"animation "+a+" "+id)
     for f in manifest["actions"].get(a,[]):
      var info=manifest["sprites"].get(str(f["key"]),{})
      check(not info.is_empty(),"mapped frame " + id)
      if not info.is_empty():check(FileAccess.file_exists("res://assets/mugen/%s/%s"%[hero["pack"],info["file"]]),"frame exists "+id)
  check(hero["trees"].size()==6,"tree count "+id)
  for t in range(6):
   check(hero["trees"][t][1].size()==7,"7 talents "+id+"/"+str(t))
   alpha.reset_run();alpha.points=30
   for n in [0,1,3,5,6]:
    check(alpha.can_buy(t,n),"branch unlock %s %d %d"%[id,t,n])
    check(alpha.buy(t,n),"branch purchase %s %d %d"%[id,t,n])
   check(not alpha.buy(t,6),"no duplicate apex "+id)
   check(alpha.count_focus(t)==5,"correct talent investment "+id)
   var save:Dictionary=alpha.snapshot()
   alpha.reset_run()
   check(alpha.restore(save),"restore %s/%d"%[id,t])
   check(alpha.apex_unlocked(t),"restore apex %s/%d"%[id,t])
  alpha.reset_run();alpha.points=30
  check(alpha.buy(0,0),"select root "+id)
  check(not alpha.buy(0,3),"require left fork "+id)
  check(alpha.buy(0,2) and alpha.buy(0,4) and alpha.buy(0,5),"alternative right fork "+id)
  check(alpha.additional_projectiles()==0,"no fake projectile unlock "+id)
  check(alpha.damage_multiplier()>=1.0,"base damage scaler "+id)
 alpha.choose(previous);alpha.reset_run()
 print("ALPHA_QA: %d checks, %d failed"%[assertions,failures.size()])
 if failures.size()>0:
  for m in failures:print("ALPHA_QA_FAIL: "+m)
 quit(1 if failures.size()>0 else 0)