extends SceneTree
const R=preload("res://scripts/alpha/roster.gd")
const P=preload("res://scripts/alpha/progression.gd")
var checks:=0
var failures:Array=[]
func ensure(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures.append(message)
func _initialize() -> void:
 var issues=R.validate()
 ensure(issues.is_empty(),"roster schema: "+str(issues))
 ensure(R.IDS.size()==6,"six unique heroes")
 ensure(R.SLOT_IDS.size()==8,"eight jutsu slots")
 var total_trees:=0
 var declared_paths:=0
 for id in R.IDS:
  var hero=R.hero(id)
  ensure(not hero.is_empty(),"hero entry "+id)
  ensure(str(hero.name)!="","hero name "+id)
  var rows=R.skills(id)
  ensure(rows.size()==8,"eight families "+id)
  ensure(R.pack(id,0,0)!="","base form pack "+id)
  ensure(R.pack(id,0,2)!=R.pack(id,1,2),"divergent forms "+id)
  for row in rows:
   total_trees+=1
   declared_paths+=row.branches.size()
   ensure(row.branches.size()==2 and row.branches[0]!=row.branches[1],"two branches "+id+"/"+row.id)
   ensure(R.title(id,row.id)==str(row.name),"base title "+id+"/"+row.id)
  var p=P.new(id,2407)
  ensure(p.hero_id==id,"hero state "+id)
  ensure(p.equipped().is_empty(),"empty equipped "+id)
  ensure(not p.legal("rasengan:left"),"no premature evolution "+id)
  ensure(p.legal("rasengan"),"base is legal "+id)
  for i in range(3):
   ensure(p.grant("rasengan"),"rank upgrade "+id+"/"+str(i))
  ensure(p.legal("rasengan:left") and p.legal("rasengan:right"),"two legal paths "+id)
  ensure(p.grant("rasengan:left"),"path select "+id)
  ensure(not p.legal("rasengan:right"),"exclusive path "+id)
  ensure(p.grant("rasengan:mastery") and p.grant("rasengan:mastery"),"mastery x2 "+id)
  ensure(not p.grant("rasengan:mastery"),"mastery cap "+id)
  for key in ["naruto_rendan","fuma_shuriken"]:
   ensure(p.grant(key),"two more slots "+id)
  ensure(not p.grant("shuriken_barrage"),"max 3 slots "+id)
  ensure(p.grant("utility_1"),"utility equip "+id)
  ensure(not p.grant("utility_3"),"no second utility "+id)
  ensure(p.grant("passive_attack"),"passive rank "+id)
  ensure(p.choose_form(1),"choose alternate form "+id)
  ensure(not p.choose_form(0),"single path enforced "+id)
  ensure(p.advance_form() and not p.advance_form(),"two form stages "+id)
  var snap=p.snapshot()
  var q=P.new()
  ensure(q.restore(snap),"snapshot restore "+id)
  ensure(JSON.stringify(q.snapshot())==JSON.stringify(p.snapshot()),"lossless snapshot "+id)
  var old=q.snapshot()
  var invalid=old.duplicate(true);invalid.slots[2]="naruto_rendan"
  ensure(not q.restore(invalid),"tampered duplicate rejected "+id)
  ensure(q.snapshot()==old,"atomic restore "+id)
  var a=P.new(id,11221);var b=P.new(id,11221)
  ensure(a.offers(4,true)==b.offers(4,true),"deterministic gacha "+id)
  ensure(a.offers(4,true)==b.offers(4,true),"deterministic successive offer "+id)
  ensure(a.offers(4).size()==4,"four choice draft "+id)
 ensure(total_trees==48,"48 family trees")
 ensure(declared_paths==96,"96 divergent evolutions")
 var nar=P.new("naruto",11)
 ensure(nar.current_pack()=="naruto_base","Naruto existing pack")
 ensure(R.asset_ready("naruto"),"Naruto base MUGEN exists")
 # Don't silently pretend other MUGEN packs are in V12 source.
 for id in R.IDS:
  if not R.all_assets_ready(id):print("[ALPHA ASSET GAP] ",id," MUGEN full animation pack not imported")
 print("ALPHA QA: %d checks, %d failures, %d trees, %d paths"%[checks,failures.size(),total_trees,declared_paths])
 for err in failures:push_error(err)
 quit(0 if failures.is_empty() else 1)
