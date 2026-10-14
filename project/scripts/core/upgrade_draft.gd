extends RefCounted
const Registry=preload("res://scripts/core/jutsu_registry.gd")
var build
func _init(state):build=state
func pool() -> Array:
 var p=[]
 for id in Registry.cards():
  if id!="recovery" and build.legal(id):p.append(id)
 return p if not p.is_empty() else ["recovery"]
func offer(kind:String="level",jackpot:bool=false) -> Array:
 var rng=RandomNumberGenerator.new();rng.seed=build.rng_seed+build.draft_counter*7919;build.draft_counter+=1
 if kind=="utility":return Registry.UTILITY.filter(func(id):return build.legal(id))
 var p=pool()
 if kind=="new":
  p=p.filter(func(id):return id in Registry.OFFENSIVE and id not in build.owned() and build.legal(id))
  if p.is_empty():p=pool()
 var out=[]
 if jackpot and kind=="chest":
  var rares=p.filter(func(id):return ":" in id and build.legal(id))
  if not rares.is_empty():
   var rare=rares[rng.randi_range(0,rares.size()-1)]
   out.append(rare)
   p.erase(rare)
 while out.size()<3 and not p.is_empty():
  var weighted=[]
  for id in p:
   var weight=5 if id in build.owned() or ":" in id else 1
   if kind=="chest" and ":" in id:weight*=2
   for i in range(weight):weighted.append(id)
  var id=weighted[rng.randi_range(0,weighted.size()-1)];out.append(id);p.erase(id)
 return out
