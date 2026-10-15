extends Control
const NinjaTheme=preload("res://scripts/ninja_theme.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
const Art=preload("res://scripts/combat/combat_art.gd")
const INK=Color("141d2a")
const PAPER=Color("f1dfb7")
const CREAM=Color("fff2d3")
const GOLD=Color("efac59")
const MUTED=Color("aab6ae")
var g
var body:FontFile
var title:FontFile
var mono:FontFile
func font_file(name:String) -> FontFile:
 var f=FontFile.new();f.data=FileAccess.get_file_as_bytes("res://assets/fonts/%s.ttf"%name);return f
func _ready() -> void:size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_PASS;body=font_file("body");title=font_file("ninja");mono=font_file("mono");texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(_dt:float) -> void:queue_redraw()
func box(r:Rect2,c:Color,edge:Color=GOLD) -> void:
 NinjaTheme.panel(self,r,c,edge)

func text(s:String,p:Vector2,px:int=16,c:Color=CREAM,font:Font=null) -> void:draw_string(body if font==null else font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,px,c)
func center(s:String,x:float,y:float,px:int=16,c:Color=CREAM,font:Font=null) -> void:
 var f=body if font==null else font;text(s,Vector2(x-f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x/2,y),px,c,f)
func wrap_text(s:String,r:Rect2,px:int,c:Color=CREAM) -> void:
 var line="";var y=r.position.y+px
 for word in s.split(" "):
  var trial=line+word+" "
  if body.get_string_size(trial,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>r.size.x and not line.is_empty():text(line,Vector2(r.position.x,y),px,c);y+=px+6;line=""
  line+=word+" "
 text(line,Vector2(r.position.x,y),px,c)
func bar(r:Rect2,value:float,c:Color) -> void:NinjaTheme.meter(self,r,value,c)
func card(i:int,y:float=270) -> Rect2:return Rect2(134+i*342,y,320,215)
func _gui_input(event:InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  if g.intro:
   for i in range(3):
    if card(i).has_point(event.position):g.swap_slot(i)
   if Rect2(440,595,400,55).has_point(event.position):g.start_fight()
  elif g.finished and Rect2(440,480,400,55).has_point(event.position):g.retry()
func _draw() -> void:
 if g.build==null:return
 box(Rect2(24,20,510,87),INK);box(Rect2(746,20,510,87),INK)
 text("NARUTO",Vector2(40,45),22,CREAM,title);text(g.build.form_name(),Vector2(178,44),12,GOLD,mono)
 text("SASORI / MARIONETKI",Vector2(763,45),20,CREAM,title)
 bar(Rect2(40,58,477,16),g.player_hp/g.build.max_hp(),Color("df7855"));bar(Rect2(763,58,477,16),g.boss.hp/g.boss.max_hp,Color("b44e37"))
 text("HP %d/%d"%[g.player_hp,g.build.max_hp()],Vector2(40,96),11,GOLD,mono);bar(Rect2(169,86,254,8),g.chakra/100,NinjaTheme.CYAN);text("CHAKRA %d"%g.chakra,Vector2(437,96),11,GOLD,mono)
 text("FAZA %d / 2"%g.ai.phase,Vector2(763,96),11,GOLD,mono);text("%d / %d"%[g.boss.hp,g.boss.max_hp],Vector2(1112,96),11,GOLD,mono)
 center("%02d:%02d"%[int(g.elapsed)/60,int(g.elapsed)%60],640,64,28,CREAM,mono)
 if g.build.godmode:text("GODMODE",Vector2(27,124),11,GOLD,mono)
 if not g.intro and not g.finished:
  var counter=g.ai.state=="recover"
  box(Rect2(390,119,500,32),INK,NinjaTheme.CYAN if counter else Color("e7755b"))
  center("KONTRATAK · F / LPM" if counter else "SEKWENCJA %d/%d"%[g.ai.segment+1,int(g.ai.PATTERNS.get(g.ai.pattern,{"waves":1}).waves)],640,141,13,NinjaTheme.CYAN if counter else GOLD,mono)
  if g.announce_time>0:center(g.announce_text,640,181,17,CREAM,title)
  if g.combo_chain>1 and g.elapsed-g.last_contact<1.2:
   text("%d HITS"%g.combo_chain,Vector2(38,244),24,GOLD,title)
 for i in range(4):
  var id=g.build.offensive_slots[i] if i<3 else g.build.utility_id;var r=Rect2(24+i*250,627,242,64);box(r,INK,NinjaTheme.CYAN if (g.skills.cooldown(id) if i<3 else g.skills.utility_cd)<=0 else GOLD)
  text(["J","K","L","X"][i],r.position+Vector2(16,34),24,GOLD,mono);text(Registry.title(id),r.position+Vector2(55,26),15,CREAM,title)
  var cd=g.skills.cooldown(id) if i<3 else g.skills.utility_cd
  var sub="PUSTY SLOT" if id==null or id=="" else "%.1f s"%cd if cd>0 else "GOTOWE"
  if i<3 and id!=null and g.build.evolution_choices.has(id):sub=Registry.EVOLUTIONS[g.build.evolution_choices[id]][0]
  text(sub.substr(0,28),r.position+Vector2(55,47),10,GOLD,mono)
 box(Rect2(1024,627,232,64),INK);text("SHIFT / KAWARIMI",Vector2(1040,654),14,CREAM,mono);text("GOTOWE" if g.dash_cd<=0 else "%.1f s"%g.dash_cd,Vector2(1040,676),11,GOLD,mono)
 center("A/D RUCH   W SKOK   S BLOK   F / LPM KOMBO   J/K/L JUTSU   X WSPARCIE   ESC PAUZA",640,715,11,CREAM,mono)
 if g.intro:
  draw_rect(Rect2(0,0,1280,720),Color(0.025,0.05,0.06,0.92));center("AKATSUKI / LIST GOŃCZY",640,118,32,CREAM,title);center("SASORI · HIRUKO → MISTRZ MARIONETEK",640,158,14,GOLD,mono)
  center("Przeniesiono zdobyte techniki, poziomy i formę. Możesz zmienić tylko kolejność.",640,209,16,MUTED)
  for i in range(3):
   var r=card(i);var id=g.build.offensive_slots[i];box(r,PAPER,GOLD if i==g.selected_slot else Color("817555"));center(["J","K","L"][i],r.get_center().x,306,30,INK,mono);center(Registry.title(id),r.get_center().x,353,21,INK,title)
   if id!=null:
    var txt=Registry.EVOLUTIONS[g.build.evolution_choices[id]][0] if g.build.evolution_choices.has(id) else "POZIOM %d"%g.build.levels[id]
    wrap_text(txt,Rect2(r.position+Vector2(25,112),Vector2(270,54)),15,INK)
   center("KLIK / %d — ZAMIANA"%(i+1),r.get_center().x,465,12,Color("9b5236"),mono)
  center("X: "+Registry.title(g.build.utility_id)+"    •    "+g.build.form_name(),640,535,17,GOLD)
  box(Rect2(440,595,400,55),Color("b65038"));center("ROZPOCZNIJ POJEDYNEK  [ENTER]",640,631,17,CREAM,mono)
  center("F / LPM: trzy ciosy · przytrzymaj, aby łączyć. Atakuj w oknach na kontrę.",640,680,13,MUTED)
 elif g.finished:
  draw_rect(Rect2(0,0,1280,720),Color(0.025,0.05,0.06,0.92));center("SASORI POKONANY" if g.victory else "POJEDYNEK PRZEGRANY",640,236,36,CREAM,title)
  center("Twój zestaw przetrwał próbę." if g.victory else "Ten sam build — jeszcze jedna szansa." if not g.build.retry_used else "Powtórka została wykorzystana.",640,298,18,MUTED)
  center("CZAS %.1f s   •   PERFEKCYJNE BLOKI %d"%[g.elapsed,g.parries],640,360,15,GOLD,mono)
  if not g.victory and not g.build.retry_used:box(Rect2(440,480,400,55),Color("b65038"));center("POWTÓRZ POJEDYNEK  [R]",640,515,18,CREAM,mono)
  center("ENTER — MENU",640,600,17,CREAM,mono)
 elif g.paused:draw_rect(Rect2(0,0,1280,720),Color(0.025,0.05,0.06,0.85));center("PAUZA  /  ESC",640,355,32,CREAM,title)
