extends RefCounted
const INK=Color("141d2a")
const LIGHT=Color("f5e9cc")
const ORANGE=Color("ef9b43")
const CYAN=Color("65d4df")
static func panel(c:CanvasItem,r:Rect2,color:Color,edge:Color=ORANGE) -> void:
 var p=r.position;var e=r.end;var cut=minf(12,r.size.y*.2)
 var poly=PackedVector2Array([p+Vector2(cut,0),Vector2(e.x, p.y),Vector2(e.x,e.y-cut),e-Vector2(cut,0),Vector2(p.x,e.y),p+Vector2(0,cut)])
 c.draw_colored_polygon(poly,color)
 if edge.a>0:
  poly.append(poly[0]);c.draw_polyline(poly,Color(edge,edge.a*.65),1.5,true)
  c.draw_line(p+Vector2(cut,0),p+Vector2(minf(r.size.x*.3,64),0),edge,3)

 if r.size.x>180 and r.size.y>40 and edge.a>0:
  for x in [p.x+3,e.x-7]:
   c.draw_rect(Rect2(x,p.y+5,4,r.size.y-10),Color("695039"))
   for y in [p.y+5,e.y-9]:c.draw_rect(Rect2(x-1,y,6,4),Color("c49b5b"))
static func seal(c:CanvasItem,p:Vector2,r:float,color:Color) -> void:
 c.draw_arc(p,r,0,TAU,48,color,2,true)
 var pts=PackedVector2Array()
 for i in range(40):
  var q=float(i)/39;pts.append(p+Vector2.from_angle(q*TAU*1.6)*r*.65*q)
 c.draw_polyline(pts,color,2,true)
 c.draw_line(p+Vector2(r*.3,r*.4),p+Vector2(r*.85,r*.7),color,2)
static func meter(c:CanvasItem,r:Rect2,value:float,color:Color) -> void:
 c.draw_rect(r,Color("101723"));var fill=Rect2(r.position+Vector2(2,2),Vector2((r.size.x-4)*clampf(value,0,1),r.size.y-4))
 if fill.size.x>0:
  c.draw_rect(fill,color);c.draw_line(fill.position+Vector2(0,1),Vector2(fill.end.x,fill.position.y+1),color.lightened(.35),1)
 for i in range(1,10):c.draw_line(r.position+Vector2(r.size.x*i/10,2),r.position+Vector2(r.size.x*i/10,r.size.y-2),Color(0,0,0,.18),1)
