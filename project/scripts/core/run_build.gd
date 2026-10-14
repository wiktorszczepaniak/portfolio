extends Node
const Registry=preload("res://scripts/core/jutsu_registry.gd")
var offensive_slots:Array=[null,null,null]
var utility_id:=""
var levels:Dictionary={}
var evolution_choices:Dictionary={}
var passives:Dictionary={}
var form_branch:=""
var form_stage:=0
var rng_seed:int=1
var draft_counter:=0
var elapsed:=0.0
var retry_used:=false
var godmode:=false
var muted:=false
var kills:=0
var player_level:=1
var audit:Array=[]
func reset(seed_value:int=0) -> void:
 offensive_slots=[null,null,null];utility_id="";levels.clear();evolution_choices.clear();passives.clear();form_branch="";form_stage=0;rng_seed=seed_value if seed_value!=0 else int(Time.get_unix_time_from_system());draft_counter=0;elapsed=0;retry_used=false;kills=0;player_level=1;audit.clear()
func owned() -> Array:return offensive_slots.filter(func(id):return id!=null)
func legal(card:String) -> bool:
 if card=="recovery":return true
 if ":" in card:
  var p=card.split(":")
  return p.size()==2 and owned().has(p[0]) and int(levels.get(p[0],0))>=3 and not evolution_choices.has(p[0]) and Registry.DATA[p[0]].evolutions.has(p[1])
 if card in Registry.OFFENSIVE:return int(levels.get(card,0))<3 and (owned().has(card) or owned().size()<3)
 if card in Registry.UTILITY:return (utility_id=="" or utility_id==card) and int(levels.get(card,0))<3
 return Registry.PASSIVES.has(card) and int(passives.get(card,0))<int(Registry.PASSIVES[card][2])
func grant(card:String) -> bool:
 if not legal(card):return false
 if ":" in card:
  var p=card.split(":");evolution_choices[p[0]]=p[1]
 elif card in Registry.OFFENSIVE:
  if not owned().has(card):offensive_slots[offensive_slots.find(null)]=card
  levels[card]=int(levels.get(card,0))+1
 elif card in Registry.UTILITY:utility_id=card;levels[card]=int(levels.get(card,0))+1
 elif Registry.PASSIVES.has(card):passives[card]=int(passives.get(card,0))+1
 audit.append({"time":elapsed,"card":card});return true
func reorder(a:int,b:int) -> void:
 if a<0 or b<0 or a>2 or b>2:return
 var t=offensive_slots[a];offensive_slots[a]=offensive_slots[b];offensive_slots[b]=t
func snapshot() -> Dictionary:return {"offensive_slots":offensive_slots.duplicate(),"utility_id":utility_id,"levels":levels.duplicate(true),"evolution_choices":evolution_choices.duplicate(true),"passives":passives.duplicate(true),"form_branch":form_branch,"form_stage":form_stage,"rng_seed":rng_seed,"elapsed":elapsed,"retry_used":retry_used,"draft_counter":draft_counter,"kills":kills,"player_level":player_level}
func restore(saved:Dictionary) -> bool:
 var slots=saved.get("offensive_slots",[])
 if not slots is Array or slots.size()!=3:return false
 var seen=[]
 for id in slots:
  if id!=null:
   if not id in Registry.OFFENSIVE or id in seen:return false
   seen.append(id)
 var utility=saved.get("utility_id","")
 if utility!="" and not utility in Registry.UTILITY:return false
 for field in ["levels","evolution_choices","passives"]:
  if not saved.get(field,{}) is Dictionary:return false
 for id in saved.get("levels",{}):
  if not id in seen and id!=utility:return false
  if float(saved.levels[id])<1 or float(saved.levels[id])>3:return false
 for id in seen+([utility] if utility!="" else []):
  if not saved.get("levels",{}).has(id):return false
 for id in saved.get("evolution_choices",{}):
  if not id in seen or int(saved.levels[id])<3:return false
  if not saved.evolution_choices[id] in Registry.DATA[id].evolutions:return false
 for id in saved.get("passives",{}):
  if not Registry.PASSIVES.has(id):return false
  if float(saved.passives[id])<1 or float(saved.passives[id])>int(Registry.PASSIVES[id][2]):return false
 if not saved.get("form_branch","") in ["","sage","kyubi"]:return false
 if int(saved.get("form_stage",0))<0 or int(saved.get("form_stage",0))>2:return false
 offensive_slots=slots.duplicate();utility_id=utility
 levels=saved.get("levels",{}).duplicate(true);evolution_choices=saved.get("evolution_choices",{}).duplicate(true);passives=saved.get("passives",{}).duplicate(true)
 for id in levels:levels[id]=int(levels[id])
 for id in passives:passives[id]=int(passives[id])
 form_branch=saved.get("form_branch","");form_stage=int(saved.get("form_stage",0));rng_seed=int(saved.get("rng_seed",1));draft_counter=int(saved.get("draft_counter",0))
 elapsed=float(saved.get("elapsed",0));retry_used=bool(saved.get("retry_used",false));kills=int(saved.get("kills",0));player_level=int(saved.get("player_level",1));audit.clear()
 return true
func max_hp() -> float:return 165.0+18.0*float(passives.get("max_hp",0))
func form_name() -> String:
 if form_stage==0:return "NARUTO"
 if form_branch=="kyubi":return "KYŪBI CLOAK" if form_stage==1 else "KURAMA CHAKRA MODE"
 return "SAGE MODE" if form_stage==1 else "SENNIN MASTERY"
func actor_pack() -> String:
 if form_stage==0:return "naruto_base"
 if form_branch=="kyubi":return "naruto_kyubi" if form_stage==1 else "naruto_kcm"
 return "naruto_sage" if form_stage==1 else "naruto_sennin"
func cooldown(id:String,mode:String) -> float:
 return float(Registry.DATA[id].cooldowns[0 if mode=="survival" else 1])*(1.0-0.06*float(passives.get("chakra_flow",0)))*(1.0-0.08*form_stage if form_branch=="kyubi" else 1.0)*(1.0-0.055*maxi(0,int(levels.get(id,1))-1))
func power(id:String) -> float:return (1.0+0.24*maxi(0,int(levels.get(id,1))-1))*(1.0+0.07*float(passives.get("crit",0)))*(1.0+0.12*form_stage)
