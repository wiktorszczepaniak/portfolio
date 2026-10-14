extends Control
const R=preload("res://scripts/alpha/roster.gd")
const DARK=Color("#0d1b20")
const PANEL=Color("#1a2a30")
const PAPER=Color("#e9d7b2")
const MUTED=Color("#99acac")
const GOLD=Color("#dab77c")
var selected:="naruto"
var hero_portraits:Dictionary={}
var small_font:Font
var display_font:Font
func _ready() -> void:
 size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 small_font=load("res://assets/fonts/mono.ttf")
 display_font=load("res://assets/fonts/ninja.ttf")
 for id in R.IDS:
  var p=R.pack(id,0,0)
  var f="res://assets/mugen/%s/manifest.json"%p
  if not FileAccess.file_exists(f):continue
  var m=JSON.parse_string(FileAccess.get_file_as_string(f))
  if not m is Dictionary:continue
  var actions:Dictionary=m.get("actions",{})
  var frames:Array=actions.get("0",[])
  if frames.is_empty():continue
  var key=str(frames[0].get("key",""))
  var sprites:Dictionary=m.get("sprites",{})
  if not sprites.has(key):continue
  var texfile="res://assets/mugen/%s/%s"%[p,str(sprites[key].get("file",""))]
  if not FileAccess.file_exists(texfile):continue
  var img=Image.new()
  if img.load_png_from_buffer(FileAccess.get_file_as_bytes(texfile))==OK:
   hero_portraits[id]=ImageTexture.create_from_image(img)
 queue_redraw()
func _txt(s:String,p:Vector2,font_size:int=17,color:Color=PAPER,font:Font=null) -> void:
 draw_string(small_font if font==null else font,p,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _line(p:Vector2,q:Vector2,color:Color=GOLD,thick:float=1.0) -> void:draw_line(p,q,color,thick,true)
func _panel(rect:Rect2,fill:Color=PANEL,stroke:Color=GOLD) -> void:
 draw_rect(rect,fill)
 draw_rect(rect,stroke,false,1.4)
 for corner in [rect.position,rect.position+Vector2(rect.size.x,0),rect.position+Vector2(0,rect.size.y),rect.end]:
  draw_circle(corner,2.0,stroke)
func _hero_rect(index:int) -> Rect2:
 return Rect2(42+(index%2)*195,161+int(index/2)*149,180,134)
func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),DARK)
 for i in range(12):
  _line(Vector2(0,float(i)*64),Vector2(1280,float(i)*64+40),Color(0.46,0.66,0.60,0.025))
 draw_rect(Rect2(0,0,1280,9),GOLD)
 _txt("SHINOBI / BIBLIOTEKA KLANÓW",Vector2(44,57),33,PAPER,display_font)
 _txt("6 BOHATERÓW   •   48 DRZEWEK JUTSU   •   96 ŚCIEŻEK EWOLUCJI",Vector2(45,91),13,GOLD)
 _panel(Rect2(1111,32,125,46),Color("#33494a"))
 _txt("ZAMKNIJ  [C]",Vector2(1122,61),13,PAPER)
 _txt("WYBIERZ SHINOBI",Vector2(44,132),20,GOLD,display_font)
 _txt("ROZWÓJ JUTSU",Vector2(487,132),20,GOLD,display_font)
 for i in range(R.IDS.size()):
  var id=str(R.IDS[i]);var entry=R.hero(id);var rect=_hero_rect(i)
  var ready=R.all_assets_ready(id)
  var active=id==selected
  _panel(rect,Color("#3e332d") if active else PANEL,Color("#ffd78e") if active else Color("#516765"))
  draw_rect(Rect2(rect.position,Vector2(6,rect.size.y)),Color("#%s"%entry.accent))
  _txt(str(entry.name),rect.position+Vector2(13,29),15,PAPER)
  var portrait=hero_portraits.get(id)
  if portrait is Texture2D:
   var dims=portrait.get_size()*minf(1.25,53.0/portrait.get_height())
   draw_texture_rect(portrait,Rect2(rect.position+Vector2(14,40),dims),false)
  else:
   _txt("◎",rect.position+Vector2(17,76),30,Color("#%s"%entry.accent))
  _txt("MUGEN: KOMPLET" if ready else "MUGEN: DO IMPORTU",rect.position+Vector2(14,112),11,Color("#88e4c6") if ready else Color("#e6b17e"))
 _panel(Rect2(45,625,378,65),Color("#273338"),Color("#5b6c63"))
 _txt("ART GATE: BRAK SPRITE'ÓW = BRAK FAŁSZYWEJ GRYWALNOŚCI",Vector2(56,646),10,GOLD)
 _txt("Stare formy Naruto są w bazie. Reszta czeka na MUGEN.",Vector2(56,671),12,PAPER)
 var chosen=R.hero(selected)
 _txt(str(chosen.name),Vector2(488,172),23,PAPER,display_font)
 _txt("I  "+str(chosen.branch_names[0]),Vector2(489,195),12,GOLD)
 _txt("II "+str(chosen.branch_names[1]),Vector2(489,213),12,GOLD)
 var rows=R.skills(selected)
 for i in range(rows.size()):
  var row:Dictionary=rows[i]
  var top=238+i*55
  var rect=Rect2(487,top,744,51)
  _panel(rect,Color("#24353a") if i%2==0 else PANEL,Color("#556760"))
  draw_rect(Rect2(rect.position,Vector2(4,rect.size.y)),Color("#%s"%chosen.accent))
  _txt("%02d"%[i+1],Vector2(503,top+19),13,GOLD)
  _txt(str(row.name),Vector2(533,top+21),15,PAPER)
  _txt(str(row.role),Vector2(1110,top+21),11,GOLD)
  _txt("↳ "+str(row.branches[0]),Vector2(537,top+41),12,Color("#c7e5df"))
  _txt("↳ "+str(row.branches[1]),Vector2(829,top+41),12,Color("#e9c99e"))
 _txt("KAŻDE JUTSU: POZIOM I → II → III → WYBÓR GAŁĘZI → MASTERY I → II",Vector2(488,705),11,GOLD)
func _gui_input(event:InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  var p=event.position
  if Rect2(1111,32,125,46).has_point(p):
   visible=false;accept_event();return
  for i in range(R.IDS.size()):
   if _hero_rect(i).has_point(p):
    selected=str(R.IDS[i]);queue_redraw();accept_event();return
func open() -> void:
 visible=true;queue_redraw()
