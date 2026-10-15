extends RefCounted
## Resolution-independent effects; no chroma keys or opaque mattes.
const IDS=["rasengan","rasenshuriken","water","water_dragon","wind","hit","blast","slam","sand","poison","chakra","smoke","chakra_arm","lee_air","gentle_palm"]
static func paint(c:CanvasItem,id:String,at:Vector2,width:float,t:float,angle:float=0.0,alpha:float=1.0) -> void:
 c.draw_set_transform(at,angle)
 var r=width*0.45
 var blue=Color(0.14,0.65,1,alpha);var white=Color(0.85,0.98,1,alpha)
 if id=="chakra_arm":
  # Replace the green MUGEN crop with a clean amber Kurama sweep.
  var swing=clampf(t/0.36,0.0,1.0)
  var shade=[Color(0.57,0.16,0.055,alpha*0.92),Color(1.0,0.37,0.055,alpha),Color(1.0,0.75,0.23,alpha),Color(1,0.98,0.74,alpha*0.96)]
  for band in range(4):
   var outer=PackedVector2Array()
   var inner=PackedVector2Array()
   for j in range(15):
    var q=float(j)/14.0
    var curve=q*PI*0.89
    var jitter=sin(float(j)*7.2+float(band)*1.8+t*18.0)*1.25
    var mid=Vector2(-r*0.92+q*r*1.79,r*0.64-sin(curve)*r*1.65+jitter)
    var deriv=Vector2(1.79,-1.65*PI*0.89*cos(curve))
    var normal=Vector2(-deriv.y,deriv.x).normalized()
    var taper=maxf(0.015,sin(q*PI))
    var thickness=r*(0.24-0.057*float(band))*taper*(0.82+0.18*sin(t*17.0+q*12.0))
    var center=mid+normal*r*(0.012*float(band))
    outer.append(center+normal*thickness)
    inner.insert(0,center-normal*thickness)
   outer.append_array(inner)
   c.draw_colored_polygon(outer,shade[band])
  # Detached embers and seal mark, no color-keyed sprite background.
  for i in range(9):
   var q=float(i)/9.0
   var scatter=Vector2(-r*0.8+q*r*1.8+sin(t*8+i*3.9)*8.0,
    r*0.64-sin(q*PI*0.89)*r*1.65+cos(i*2.7+t*8.0)*r*0.22)
   var w=(2.2+float(i%3)*1.2)*(1.0-swing*0.26)
   c.draw_colored_polygon(PackedVector2Array([scatter+Vector2(-w,-w*.35),scatter+Vector2(w*.72,-w*.5),scatter+Vector2(w*.16,w*.94)]),shade[1+i%2])
  c.draw_arc(Vector2(-r*0.73,r*0.52),r*0.09,0,TAU,14,Color(0.21,0.15,0.13,alpha),2.2,true)
 elif id in ["rasengan","rasenshuriken","chakra"]:
  if id=="chakra":blue=Color(0.55,0.29,0.86,alpha)
  c.draw_circle(Vector2.ZERO,r*0.9,Color(blue,alpha*0.12))
  c.draw_circle(Vector2.ZERO,r*0.63,Color(blue,alpha*0.9))
  c.draw_circle(Vector2.ZERO,r*0.41,Color(0.4,0.86,1,alpha))
  for i in range(6):
   var pts=PackedVector2Array()
   for j in range(20):
    var q=float(j)/19;var a=q*4.3+i*TAU/6+t*13
    pts.append(Vector2.from_angle(a)*r*(0.12+q*0.65))
   c.draw_polyline(pts,white,1.5,true)
  c.draw_circle(Vector2(-r*0.12,-r*0.12),r*0.18,white)
  if id=="rasenshuriken":
   for i in range(4):
    var d=Vector2.from_angle(t*17+i*PI/2);var n=d.orthogonal()
    c.draw_colored_polygon(PackedVector2Array([d*r*0.4+n*r*0.2,d*r*1.45,d*r*0.5-n*r*0.16]),white)
 elif id in ["water","water_dragon"]:
  var length=r*1.7
  for k in range(3):
   var pts=PackedVector2Array()
   for j in range(24):
    var q=float(j)/23
    pts.append(Vector2(-length+q*length*1.6,sin(q*7-t*10+k*0.4)*r*(0.12+q*0.2)+k*r*0.13))
   c.draw_polyline(pts,Color(0.08+k*0.17,0.38+k*0.2,0.76+k*0.10,alpha),maxf(2,r*(0.43-k*0.13)),true)
  if id=="water_dragon":
   c.draw_colored_polygon(PackedVector2Array([Vector2(r*.1,-r*.1),Vector2(r*.3,-r*.85),Vector2(r*.65,-r*1.1),Vector2(r*1.1,-r*.72),Vector2(r*.9,-r*.42),Vector2(r*.5,-r*.48),Vector2(r*.4,r*.14)]),blue)
   c.draw_polyline(PackedVector2Array([Vector2(r*.3,-r*.85),Vector2(r*.65,-r*1.1),Vector2(r*1.1,-r*.72)]),white,2,true)
   c.draw_line(Vector2(r*.63,-r*.79),Vector2(r*.83,-r*.72),white,3)
  for i in range(6):
   var p=Vector2(-r+fposmod(i*.37+t*1.7,1.7)*r,sin(i*2.4+t*7)*r*.5)
   c.draw_circle(p,2,white)
 elif id in ["hit","blast","slam"]:
  var color=Color(1,0.66,0.18,alpha) if id=="blast" else Color(0.98,0.94,0.72,alpha)
  var growth=0.35+clampf(t*3,0,1)*0.65
  for i in range(9):
   var d=Vector2.from_angle(i*TAU/9+0.3);var n=d.orthogonal()
   c.draw_colored_polygon(PackedVector2Array([d*r*.16+n*r*.07,d*r*growth*(1.0 if i%2==0 else .65),d*r*.16-n*r*.07]),color)
  c.draw_circle(Vector2.ZERO,r*.16,Color(1,1,0.95,alpha))
  c.draw_arc(Vector2.ZERO,r*growth*.72,0,TAU,40,Color(color,alpha*.5),2,true)
 elif id in ["smoke","poison"]:
  for i in range(7):
   var p=Vector2.from_angle(i*2.4+t*.4)*r*(.2+fposmod(t*.5+i*.13,.5))
   var color=Color(.23,.61,.39,alpha*.45) if id=="poison" else Color(.8,.87,.91,alpha*.5)
   c.draw_circle(p,r*(.24+sin(i)*.05),color)
   c.draw_arc(p,r*.25,PI,TAU,14,Color(color.lightened(.3),alpha*.7),1.5,true)
 elif id in ["lee_air","gentle_palm"]:
  # Near-body trails for taijutsu. These strokes appear only on active contact frames.
  var green:bool=id=="lee_air"
  var outer:Color=Color(0.08,0.34,0.12,alpha*0.72) if green else Color(0.36,0.25,0.52,alpha*0.62)
  var inner:Color=Color(0.40,0.95,0.34,alpha) if green else Color(0.79,0.88,1.0,alpha)
  var center:Vector2=Vector2.ZERO
  for k in range(3):
   var rad:float=r*(0.43+float(k)*0.17)
   var begin:float=PI*1.17+float(k)*0.14+t*2.3
   var span:float=PI*(0.68+float(k)*0.03)
   c.draw_arc(center,rad,begin,begin+span,24,outer,6.5-float(k)*1.3,true)
   c.draw_arc(center,rad,begin+0.11,begin+span-0.07,24,inner,3.0-float(k)*0.38,true)
  for i in range(7):
   var u:float=float(i)/6.0
   var p:Vector2=Vector2.from_angle(PI*(1.22+u*.68)+t*1.3)*r*(0.4+u*.23)
   c.draw_circle(p,1.1+float(i%3),Color(inner,alpha*(0.42+u*.45)))
 elif id=="sand":
  # Sand is ochre/brown particulate matter, not the old grey polygon spikes.
  # A moving, layered stream with turbulent grains and an optional spiral shell.
  var palette=[
   Color(0.32,0.20,0.10,alpha*0.85),
   Color(0.63,0.39,0.18,alpha*0.92),
   Color(0.82,0.59,0.29,alpha),
   Color(0.95,0.77,0.41,alpha*0.92)
  ]
  var rise:float=r*0.18
  for lane in range(4):
   var path=PackedVector2Array()
   for i in range(16):
    var k=float(i)/15.0
    var x=-r*1.08+k*r*2.18
    var y=sin(k*6.8+t*7.5+float(lane)*0.78)*r*0.18+float(lane-2)*rise
    path.append(Vector2(x,y))
   c.draw_polyline(path,Color(palette[lane],alpha*(0.34+float(lane)*0.08)),2.5+float(lane),true)
  for i in range(42):
   var lane:int=i%4
   var u:float=fposmod(float(i)*0.129+t*(0.85+float(lane)*0.10),1.0)
   var x:float=-r*1.10+u*r*2.2
   var y:float=sin(u*7.2+t*8.0+float(i)*1.34)*r*(0.14+float(lane)*0.025)+float(lane-2)*rise
   var dust:float=maxf(1.0,r*(0.027+float(i%5)*0.012))
   var grain:Color=palette[(i+lane)%4]
   c.draw_circle(Vector2(x,y),dust,grain)
   if i%7==0:c.draw_circle(Vector2(x-3.0,y-2.0),dust*0.47,Color(1.0,0.87,0.58,alpha*0.8))

 else:
  for i in range(3):c.draw_arc(Vector2.ZERO,r*(.4+i*.22),t*9+i*1.7,t*9+i*1.7+PI*1.2,24,Color(white,alpha*(1-i*.2)),2,true)
 c.draw_set_transform(Vector2.ZERO)
