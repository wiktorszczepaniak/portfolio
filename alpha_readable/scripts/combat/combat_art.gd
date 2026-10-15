extends RefCounted
static var cache:Dictionary={}
static var sequences:Dictionary={}
static var actors:Dictionary={}
static func texture(path:String):
 if not cache.has(path):
  if not FileAccess.file_exists(path):return null
  var im=Image.new()
  if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
  cache[path]=ImageTexture.create_from_image(im)
 return cache[path]
static func frames(id:String) -> Array:
 if sequences.has(id):return sequences[id]
 var result=[]
 var paths={"shuriken":"res://assets/vfx_items/small_shuriken.png","kunai":"res://assets/vfx_items/kunai.png","note":"res://assets/v10/note.png","log":"res://assets/stage_desert/kawarimi_log.png"}
 if paths.has(id):result=[texture(paths[id])]
 else:
  var base="res://assets/v10/"+id+"_%02d.png"
  if id in ["hit","blast","sand","senbon","poison","chakra"]:base="res://assets/boss_sasori/"+id+"_%02d.png"
  for i in range(64):
   var t=texture(base%i)
   if t!=null:result.append(t)
 result=result.filter(func(t):return t!=null);sequences[id]=result;return result
static func frame(id:String,time:float):
 var a=frames(id);return null if a.is_empty() else a[posmod(int(time*14),a.size())]
static func actor(pack:String,action:String,time:float) -> Dictionary:
 if not actors.has(pack):actors[pack]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/mugen/%s/manifest.json"%pack))
 var m:Dictionary=actors[pack];var a:Array=m.actions.get(action,m.actions["0"])
 if a.is_empty():a=m.actions["0"]
 var total=0.0
 for entry in a:total+=maxf(1,float(entry.get("ticks",6)))
 var position=fposmod(time*60,total)
 var entry:Dictionary=a[0]
 for candidate in a:
  entry=candidate;position-=maxf(1,float(candidate.get("ticks",6)))
  if position<0:break
 var s:Dictionary=m.sprites[entry.key]
 return {"texture":texture("res://assets/mugen/%s/%s"%[pack,s.file]),"axis":Vector2(s.axis[0],s.axis[1]),"scale":float(m.get("display_scale",1)),"offset":Vector2(entry.get("x",0),entry.get("y",0)),"flip_h":entry.get("flip_h",false),"flip_v":entry.get("flip_v",false)}
