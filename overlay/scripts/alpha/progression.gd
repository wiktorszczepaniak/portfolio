extends RefCounted
## Deterministic, serializable and legality-checked progression for six Alpha heroes.
## Three jutsu equipped on J/K/L, one utility on X; 8 trees available per hero.
const Roster=preload("res://scripts/alpha/roster.gd")
const COMMON_PASSIVES={"attack":4,"defense":4,"mobility":4,"chakra":4,"pickup":4,"regen":3}
var hero_id:="naruto"
var slots:Array=[null,null,null]
var utility:=""
var levels:Dictionary={}
var paths:Dictionary={}
var capstones:Dictionary={}
var passive_levels:Dictionary={}
var utility_level:=0
var form_branch:=-1
var form_stage:=0
var seed:=1
var offers_made:=0
var audit:Array=[]
func _init(which:String="naruto",s:int=1) -> void:reset(which,s)
func reset(which:String="naruto",s:int=1) -> void:
 hero_id=which if which in Roster.IDS else "naruto"
 slots=[null,null,null];utility="";levels.clear();paths.clear()
 capstones.clear();passive_levels.clear();utility_level=0
 form_branch=-1;form_stage=0;seed=s if s!=0 else 1;offers_made=0;audit.clear()
func equipped() -> Array:return slots.filter(func(v):return v!=null)
func has_tree(family:String) -> bool:return family in Roster.SLOT_IDS
func legal(id:String) -> bool:
 var p=id.split(":");var tree=str(p[0])
 if p.size()==2 and tree in Roster.SLOT_IDS:
  if not equipped().has(tree):return false
  if p[1]=="left" or p[1]=="right":return int(levels.get(tree,0))>=3 and not paths.has(tree)
  if p[1]=="mastery":return paths.has(tree) and int(capstones.get(tree,0))<2
  return false
 if p.size()!=1:return false
 if tree in Roster.SLOT_IDS:
  return int(levels.get(tree,0))<3 and (equipped().has(tree) or equipped().size()<3)
 if tree.begins_with("utility_"):
  var key=tree.substr(8)
  if not key.is_valid_int():return false
  var n=int(key)
  return n>=0 and n<4 and (utility=="" or utility==tree) and utility_level<3
 if tree.begins_with("passive_"):
  var key=tree.substr(8)
  return COMMON_PASSIVES.has(key) and int(passive_levels.get(key,0))<int(COMMON_PASSIVES[key])
 return false
func grant(id:String) -> bool:
 if not legal(id):return false
 var p=id.split(":");var tree=str(p[0])
 if p.size()==2:
  if p[1]=="mastery":capstones[tree]=int(capstones.get(tree,0))+1
  else:paths[tree]=p[1]
 elif tree in Roster.SLOT_IDS:
  if not equipped().has(tree):slots[slots.find(null)]=tree
  levels[tree]=int(levels.get(tree,0))+1
 elif tree.begins_with("utility_"):utility=tree;utility_level+=1
 elif tree.begins_with("passive_"):
  var key=tree.substr(8);passive_levels[key]=int(passive_levels.get(key,0))+1
 audit.append(id)
 return true
func choose_form(path:int) -> bool:
 if form_stage!=0 or path<0 or path>1:return false
 form_branch=path;form_stage=1;return true
func advance_form() -> bool:
 if form_branch<0 or form_stage!=1:return false
 form_stage=2;return true
func playable_art_ready() -> bool:return Roster.all_assets_ready(hero_id)
func current_pack() -> String:return Roster.pack(hero_id,maxi(0,form_branch),form_stage)
func legal_cards() -> Array:
 var result:Array=[]
 for family in Roster.SLOT_IDS:
  if legal(family):result.append(family)
  for path in ["left","right","mastery"]:
   var card=family+":"+path
   if legal(card):result.append(card)
 for n in range(4):
  var card="utility_"+str(n)
  if legal(card):result.append(card)
 for key in COMMON_PASSIVES:
  var card="passive_"+key
  if legal(card):result.append(card)
 return result
func rarity(card:String) -> int:
 if card.ends_with(":mastery"):return 3
 if card.ends_with(":left") or card.ends_with(":right"):return 2
 if card.begins_with("utility_"):return 1
 if card.begins_with("passive_"):return 0
 return 1 if int(levels.get(card,0))==0 else 0
func offers(count:int=3,chest:bool=false) -> Array:
 var pool=legal_cards()
 var roll=RandomNumberGenerator.new();roll.seed=seed+98761*offers_made+int(hero_id.length())*1613
 offers_made+=1
 var out:Array=[]
 while out.size()<count and not pool.is_empty():
  var candidates:Array=[];var weighted=0.0
  for card in pool:
   var tier=rarity(card)
   var weight=[5.0,3.0,1.25,0.24][tier]
   if chest:weight=[2.0,3.0,3.0,1.0][tier]
   weighted+=weight;candidates.append({"id":card,"weight":weight})
  var pick=roll.randf_range(0.0,weighted)
  var chosen=str(pool.back())
  for item in candidates:
   pick-=item.weight
   if pick<=0:
    chosen=item.id;break
  out.append(chosen);pool.erase(chosen)
 return out
func summary(family:String) -> Dictionary:
 if not has_tree(family):return {}
 var path=str(paths.get(family,""))
 var tier=int(levels.get(family,0))
 var mastery=int(capstones.get(family,0))
 return {"id":family,"hero":hero_id,"rank":tier,"branch":path,"mastery":mastery,"name":Roster.title(hero_id,family,path)}
func snapshot() -> Dictionary:
 return {"version":1,"hero_id":hero_id,"slots":slots.duplicate(),"utility":utility,"utility_level":utility_level,"levels":levels.duplicate(true),"paths":paths.duplicate(true),"capstones":capstones.duplicate(true),"passive_levels":passive_levels.duplicate(true),"form_branch":form_branch,"form_stage":form_stage,"seed":seed,"offers_made":offers_made}
func restore(saved:Dictionary) -> bool:
 if int(saved.get("version",0))!=1:return false
 var id=str(saved.get("hero_id",""))
 if not id in Roster.IDS:return false
 var sl=saved.get("slots",null)
 if not sl is Array or sl.size()!=3:return false
 var seen:Array=[]
 for family in sl:
  if family!=null:
   if not family in Roster.SLOT_IDS or family in seen:return false
   seen.append(family)
 var ul=str(saved.get("utility",""))
 if ul!="" and not ul in ["utility_0","utility_1","utility_2","utility_3"]:return false
 var ur=int(saved.get("utility_level",0))
 if ur<0 or ur>3 or (ul=="" and ur!=0) or (ul!="" and ur==0):return false
 for key in ["levels","paths","capstones","passive_levels"]:
  if not saved.get(key,null) is Dictionary:return false
 for family in saved.levels:
  if not family in seen or int(saved.levels[family])<1 or int(saved.levels[family])>3:return false
 for family in seen:
  if not saved.levels.has(family):return false
 for family in saved.paths:
  if not family in seen or int(saved.levels[family])!=3 or not str(saved.paths[family]) in ["left","right"]:return false
 for family in saved.capstones:
  if not saved.paths.has(family) or int(saved.capstones[family])<1 or int(saved.capstones[family])>2:return false
 for key in saved.passive_levels:
  if not COMMON_PASSIVES.has(key) or int(saved.passive_levels[key])<1 or int(saved.passive_levels[key])>int(COMMON_PASSIVES[key]):return false
 var fb=int(saved.get("form_branch",-2))
 var fs=int(saved.get("form_stage",-1))
 if fb< -1 or fb>1 or fs<0 or fs>2 or (fb==-1 and fs!=0) or (fb>=0 and fs==0):return false
 if int(saved.get("offers_made",-1))<0:return false
 hero_id=id;slots=sl.duplicate();utility=ul;utility_level=ur
 levels=saved.levels.duplicate(true);paths=saved.paths.duplicate(true);capstones=saved.capstones.duplicate(true)
 passive_levels=saved.passive_levels.duplicate(true);form_branch=fb;form_stage=fs
 seed=int(saved.get("seed",1));offers_made=int(saved.get("offers_made",0));audit.clear()
 for key in levels:levels[key]=int(levels[key])
 for key in capstones:capstones[key]=int(capstones[key])
 for key in passive_levels:passive_levels[key]=int(passive_levels[key])
 return true
