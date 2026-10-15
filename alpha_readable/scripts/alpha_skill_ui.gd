extends Control
## Full-screen branching skill constellation, not a static mockup.
## Every node is clickable and validates parent/points in AlphaProgress.
const NinjaTheme=preload("res://scripts/ninja_theme.gd")
const Moves=preload("res://scripts/combat/alpha_abilities.gd")
const INK=Color("15232c")
const DARK=Color("09151e")
const GOLD=Color("dfb36e")
const PAPER=Color("f0dfb7")
const TEAL=Color("70d3de")
const RED=Color("ce694e")
var g:Node
var alpha:Node
var title_font:FontFile
var body_font:FontFile
var mono_font:FontFile
var cursor:Vector2=Vector2.ZERO
var inspected:int=-1
var time:=0.0
const NODES=[Vector2(640,237),Vector2(412,313),Vector2(868,313),Vector2(412,405),Vector2(868,405),Vector2(640,491),Vector2(640,571),Vector2(640,651)]
const PARENTS=[[0,1],[0,2],[1,3],[2,4],[3,5],[4,5],[5,6],[6,7]]

func _ready()->void:
 size=Vector2(1280,720)
 mouse_filter=Control.MOUSE_FILTER_STOP
 title_font=_font("ninja");body_font=_font("body");mono_font=_font("mono")
 alpha=get_node("/root/AlphaProgress")
 visible=false

func _font(name:String)->FontFile:
 var f=FontFile.new();f.data=FileAccess.get_file_as_bytes("res://assets/fonts/%s.ttf"%name);return f

func _process(dt:float)->void:
 time+=dt
 var should_show:bool=alpha!=null and alpha.tree_open
 if visible!=should_show:visible=should_show
 if visible:
  cursor=get_local_mouse_position();queue_redraw()

func _card(i:int)->Rect2:
 return Rect2(NODES[i]-Vector2(136,29),Vector2(272,58))

func _gui_input(event:InputEvent)->void:
 if not visible:return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  var p:Vector2=event.position
  if Rect2(1163,19,90,43).has_point(p):
   alpha.tree_open=false;accept_event();return
  for i in range(10):
   if Rect2(28+(i%5)*244,92+int(i/5)*53,232,47).has_point(p):
    alpha.tree_tab=i;accept_event();return
  for n in range(8):
   if _card(n).has_point(p):
    if alpha.buy(alpha.tree_tab,n):
     g._sfx("upgrade.wav")
     g._flash("NOWA TECHNIKA: "+alpha.node_name(alpha.tree_tab,n),1.5)
     # Explicitly persist progression between survival and duel.
     var file=FileAccess.open("user://last_alpha.json",FileAccess.WRITE)
     if file!=null:file.store_string(JSON.stringify(alpha.snapshot(),"  "))
    accept_event();return
  accept_event()

func _text(value:String,at:Vector2,px:int=16,color:Color=PAPER,font:Font=null)->void:
 draw_string(body_font if font==null else font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)

func _center(value:String,at:Vector2,px:int=16,color:Color=PAPER,font:Font=null)->void:
 var f:Font=body_font if font==null else font
 _text(value,at-Vector2(f.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x*.5,0),px,color,f)

func _panel(rect:Rect2,color:Color,edge:Color)->void:
 NinjaTheme.panel(self,rect,color,edge)

func _draw()->void:
 if not visible or alpha==null:return
 draw_rect(Rect2(0,0,1280,720),Color("081018"))
 for i in range(24):
  var y:float=float(i)*39.0+fmod(time*.5,39.0)
  draw_line(Vector2(0,y),Vector2(1280,y-125),Color(0.73,0.62,0.43,0.04),1)
 draw_circle(Vector2(640,395),280,Color(.27,.3,.32,.06))
 draw_arc(Vector2(640,410),296,0,TAU,90,Color(GOLD,0.12),2,true)
 _panel(Rect2(21,16,1238,63),INK,GOLD)
 _text("DRZEWKA SHINOBI",Vector2(42,58),27,PAPER,title_font)
 _text("%s  •  %d PUNKTÓW TALENTU" % [str(alpha.hero()["name"]),alpha.points],Vector2(480,52),17,TEAL,mono_font)
 _panel(Rect2(1163,19,90,43),RED,GOLD)
 _center("[T] X",Vector2(1208,46),15,PAPER,mono_font)
 for t in range(10):
  var r=Rect2(28+(t%5)*244,92+int(t/5)*53,232,47)
  var active:bool=t==alpha.tree_tab
  var count:int=alpha.count_focus(t)
  _panel(r,Color("3a3a37") if active else INK,GOLD if active else Color("607075"))
  _center(alpha.tree_name(t),Vector2(r.get_center().x,r.position.y+22),13,PAPER if active else Color("b7c6c5"),title_font)
  _center("%d / 8"%count,Vector2(r.get_center().x,r.position.y+41),11,GOLD if active else Color("8c9da1"),mono_font)
 var active_tree:int=alpha.tree_tab
 inspected=-1
 for hover_index in range(8):
  if _card(hover_index).has_point(cursor):inspected=hover_index
 _draw_compendium(active_tree)
 var root_color:Color=Color("5e7b9b")
 for edge in PARENTS:
  var a:int=edge[0];var b:int=edge[1]
  var linked:bool=alpha.invested(active_tree,a) and alpha.invested(active_tree,b)
  var open_edge:bool=alpha.invested(active_tree,a) and alpha.can_buy(active_tree,b)
  var color:Color=GOLD if linked else TEAL if open_edge else Color(.4,.45,.45,.42)
  draw_line(NODES[a]+Vector2(0,20),NODES[b]-Vector2(0,24),color,4 if linked else 2.0,true)
 for n in range(8):
  var rect:Rect2=_card(n)
  var owned:bool=alpha.invested(active_tree,n)
  var available:bool=alpha.can_buy(active_tree,n)
  var hot:bool=rect.has_point(cursor)
  var locked:bool=not owned and not available
  var edge:Color=GOLD if owned else TEAL if available else Color("525963")
  var fill:Color=Color("42382d") if owned else Color("254451") if available else INK
  if hot:fill=fill.lightened(.17)
  _panel(rect,fill,edge)
  var skill:String=alpha.node_name(active_tree,n)
  var font_size:int=11 if skill.length()>23 else 13
  _center(skill,Vector2(rect.get_center().x,rect.position.y+25),font_size,PAPER if not locked else Color("98a3a6"),title_font)
  _center("ODKRYTO ✓" if owned else ("%d PKT  •  KLIKNIJ"%alpha.node_cost(n)) if available else "WYMAGANA POPRZEDNIA TECHNIKA",Vector2(rect.get_center().x,rect.position.y+46),10,GOLD if owned else TEAL if available else Color("64717c"),mono_font)
  var ring_pos:Vector2=Vector2(rect.position.x+18,rect.position.y+16)
  draw_circle(ring_pos,12,edge)
  _center(str(n+1),ring_pos+Vector2(0,5),10,DARK,mono_font)
 _center("10 DRZEWEK  •  8 WĘZŁÓW  •  PRAWDZIWE ODNOGI I SYGNATURY",Vector2(640,701),11,Color("a3aea9"),mono_font)
 _text("1–9 / 0 DRZEWKA   •   T / ESC ZAMKNIJ",Vector2(28,714),10,Color("849797"),mono_font)

const ABILITY_DESCRIPTIONS={
 "nova":["ROZBŁYSK CHAKRY","Eksplozja w punkcie trafienia","Dodatkowe fale i obrażenia"],
 "fan":["ROZPROSZENIE","Pięć technik w szerokim stożku","Szerokość i skuteczność rosną"],
 "pierce":["PRZEBICIE","Seria uderzeń wzdłuż jednej linii","Przełamuje zwarte grupy ninja"],
 "ring":["OBRÓT OBRONNY","Osiem ciosów wokół bohatera","Okno nietykalności i zasięg"],
 "chain":["ŁAŃCUCH UDERZEŃ","Technika przeskakuje między celami","Kolejny cel przy legendarnej"],
 "guard":["TARCZA CHAKRY","Krótka ochrona i kontratak","Leczenie i dłuższa ochrona"],
 "summon":["WEZWANIE WSPARCIA","Atak wspierających wojowników","Klon lub wsparcie obszarowe"],
 "suppress":["PRZERWANIE JUTSU","Powstrzymuje ataki grupy przeciwników","Dłuższe ogłuszenie i presja"]
}
const NODE_HINTS=[
 ["PODSTAWA","+6,5% mocy ofensywnej","Działa także w walce z bossem"],
 ["TEMPO","-3,5% czasu między atakami","Szybsze kombosy i częstsze jutsu"],
 ["WYTRZYMAŁOŚĆ","Zmniejsza otrzymywany DMG","Zwiększa szanse na kontratak"],
 ["WIELOKROTNOŚĆ","Co 2 talenty dodatkowy pocisk","Wzmacnia obrażenia obszarowe"],
 ["MOBILNOŚĆ","+3,7% prędkości ruchu","Łatwiej unikać i doskakiwać"],
 ["SYGNATURA","Odblokuj unikalną technikę","Uaktywnia się podczas walki"],
 ["APEX","Wersja legendarna techniki","Większy zasięg, moc i kontrola"],
 ["MISTRZOSTWO","Synergia ścieżek i charakteru","Wymaga odblokowanego APEX"]
]
func _draw_compendium(tree:int)->void:
 var primary:String=alpha.tree_name(tree)
 var profile:String=str(alpha.hero()["role"])
 var ability:String=str(Moves.ability_type(alpha.selected,tree))
 var labels:Array=ABILITY_DESCRIPTIONS.get(ability,["SYGNATURA","Osobista technika","Wybierz pieczęć"])
 _panel(Rect2(14,185,244,366),INK,Color(GOLD,.49))
 _text("ŚCIEŻKA SHINOBI",Vector2(30,217),12,GOLD,mono_font)
 _text(profile.substr(0,24),Vector2(30,253),11,TEAL,mono_font)
 _text(primary.substr(0,22),Vector2(30,288),17,PAPER,title_font)
 draw_line(Vector2(30,300),Vector2(238,300),Color(GOLD,.45),2)
 _text("TECHNIKA SYGNATURY",Vector2(30,331),11,GOLD,mono_font)
 _text(str(labels[0]),Vector2(30,358),14,TEAL,title_font)
 _text(str(labels[1]).substr(0,31),Vector2(30,385),11,PAPER)
 _text(str(labels[2]).substr(0,31),Vector2(30,405),11,PAPER)
 _text("PUNKT 6: "+("ODKRYTY" if alpha.special_unlocked(tree) else "ZABLOKOWANY"),Vector2(30,463),10,TEAL if alpha.special_unlocked(tree) else Color("879097"),mono_font)
 _text("APEX: "+("AKTYWNY" if alpha.apex_unlocked(tree) else "ZABLOKOWANY"),Vector2(30,488),10,GOLD if alpha.apex_unlocked(tree) else Color("879097"),mono_font)
 _text("ZAWALCZ O SWÓJ STYL",Vector2(30,526),11,GOLD,mono_font)
 _panel(Rect2(1021,185,244,366),INK,Color(GOLD,.49))
 var n:int=inspected if inspected>=0 else 5
 var unlocked:bool=alpha.invested(tree,n)
 var can:bool=alpha.can_buy(tree,n)
 var hint:Array=NODE_HINTS[n]
 _text("PIECZĘĆ TALENTU",Vector2(1037,217),12,GOLD,mono_font)
 _text("%02d / 08" % (n+1),Vector2(1037,255),25,TEAL,title_font)
 _text(alpha.node_name(tree,n).substr(0,27),Vector2(1037,285),12,PAPER,title_font)
 draw_line(Vector2(1037,300),Vector2(1250,300),Color(GOLD,.45),2)
 _text(str(hint[0]),Vector2(1037,335),14,TEAL,title_font)
 _text(str(hint[1]).substr(0,32),Vector2(1037,368),11,PAPER)
 _text(str(hint[2]).substr(0,32),Vector2(1037,389),11,PAPER)
 _text("KOSZT: %d PKT"%alpha.node_cost(n),Vector2(1037,445),12,GOLD,mono_font)
 _text("ODBLOKOWANY" if unlocked else "KLIKNIJ ABY ODKRYĆ" if can else "WYMAGANE INNE PIECZĘCIE",Vector2(1037,488),10,TEAL if can or unlocked else Color("879097"),mono_font)
 _text("LEWA / PRAWA GAŁĄŹ",Vector2(1037,524),10,GOLD,mono_font)
