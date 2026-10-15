extends Node2D
const FX=preload("res://scripts/combat/ninja_fx.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
const Resolver=preload("res://scripts/combat/combat_resolver.gd")
const Art=preload("res://scripts/combat/combat_art.gd")
const Pool=preload("res://scripts/core/transient_pool.gd")
var projectile_pool=Pool.new()
var effect_pool=Pool.new()
const MAX_PROJECTILES=96
const MAX_EFFECTS=70
var host
var build
var mode:="survival"
var cooldowns:Dictionary={}
var utility_cd:=0.0
var lock_time:=0.0
var casts:Array=[]
var projectiles:Array=[]
var effects:Array=[]
var traps:Array=[]
var assistants:Array=[]
var clock:=0.0
var support_time:=0.0
var support_charges:=0
var support_pos:=Vector2.ZERO
var decoy_time:=0.0
var decoy_pos:=Vector2.ZERO
var oiroke_time:=0.0
var oiroke_tick:=0.0
var oiroke_pos:=Vector2.ZERO
var counter_time:=0.0
var cast_history:Array=[]
var hit_history:Dictionary={}
var render_scale:=1.0
func setup(owner_node,state,game_mode:String) -> void:
 host=owner_node;build=state;mode=game_mode;render_scale=1.55 if mode=="duel" else 1.0;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;z_index=2200
func reset() -> void:
 cooldowns.clear();casts.clear();projectiles.clear();effects.clear();traps.clear();assistants.clear();utility_cd=0;lock_time=0;support_time=0;decoy_time=0;oiroke_time=0;counter_time=0;clock=0;cast_history.clear();hit_history.clear()
func nearest(origin:Vector2,max_range:float=900.0) -> Dictionary:
 var best={};var dist=max_range
 for e in host.skill_targets():
  if float(e.get("hp",0))<=0:continue
  var distance=origin.distance_to(e.pos)
  if distance<dist:dist=distance;best=e
 return best
func cooldown(id) -> float:return float(cooldowns.get(id,0))
func cast_slot(slot:int) -> bool:
 if slot<0 or slot>2:return false
 var id=build.offensive_slots[slot];return false if id==null else cast(str(id))
func cast(id:String) -> bool:
 if id not in build.owned() or cooldown(id)>0 or (mode=="duel" and lock_time>0):return false
 var origin:Vector2=host.skill_origin()
 var hero:String=_hero_id()
 var reach:float=158.0 if hero=="rock_lee" else 166.0 if hero=="neji" else 900.0
 # Neji's advanced Vacuum Palm reaches short-medium distance, not the whole screen.
 if hero=="neji" and id=="rasengan" and int(build.levels.get(id,0))>=2:reach=265.0
 var target=nearest(origin,reach)
 if target.is_empty():return false
 if mode=="duel" and not host.skill_spend(id):return false
 var d:Dictionary=Registry.DATA[id];var point:Vector2=target.pos
 var direction=(point-origin).normalized() if mode=="survival" else Vector2(host.skill_facing(),0)
 if direction.length_squared()<0.1:direction=Vector2.RIGHT
 var total:float=float(d.startup)+float(d.active)+float(d.recovery)
 cooldowns[id]=build.cooldown(id,mode)
 if mode=="duel":lock_time=total
 if id=="rasengan":host.skill_sound("chakra_charge.wav")
 casts.append({"id":id,"age":0.0,"origin":origin,"point":point,"dir":direction,"lv":int(build.levels.get(id,1)),"evo":str(build.evolution_choices.get(id,"")),"power":build.power(id),"startup":d.startup,"total":total,"active":false,"pulses":0})
 if casts.size()>12:casts.pop_front()
 host.skill_pose("210" if id in ["naruto_rendan","henge_feint"] else "200",total)
 cast_history.append(id)
 if cast_history.size()>100:cast_history.pop_front()
 effect("smoke" if id in ["kuchiyose","gama_teppo","henge_feint"] else "wind",origin+Vector2(0,-20),38,0.26)
 return true
func tick(dt:float) -> void:
 clock+=dt;utility_cd=maxf(0,utility_cd-dt);lock_time=maxf(0,lock_time-dt);support_time=maxf(0,support_time-dt);decoy_time=maxf(0,decoy_time-dt);counter_time=maxf(0,counter_time-dt)
 for id in cooldowns:cooldowns[id]=maxf(0,float(cooldowns[id])-dt)
 if build.utility_id=="oiroke" and utility_cd<=0:
  utility()  # Automatically re-cast Oiroke. X is unnecessary for this utility.
 if mode=="survival":
  for id in build.owned():
   if cooldown(id)<=0:cast(id)
 for c in casts.duplicate():
  c.age+=dt
  if not c.active and c.age>=c.startup:c.active=true;activate(c)
  if c.id=="naruto_rendan" and _hero_id()=="naruto" and c.active:
   var count=3+int(c.lv)+(2 if c.evo=="nisen" else 0);var spacing=0.11 if c.evo=="combo_rush" else 0.15
   while c.pulses<count and c.age>=float(c.startup)+float(c.pulses)*spacing:
    var point:Vector2=c.point
    if c.evo=="combo_rush":
     var victim=nearest(point,400)
     if not victim.is_empty():point=victim.pos
    var power=float(c.power)*float(Registry.DATA[c.id].damage)
    if c.pulses==count-1:
     power*=1.7
     if "rasengan" in build.owned():power*=1.45;effect("rasengan",point+Vector2(0,-25),100,0.4)
    var side=-1 if int(c.pulses)%2==0 else 1
    clone_effect(point+Vector2(side*35,-18 if c.lv>=2 and c.pulses==2 else 0),-side,0.32)
    var radius=85.0 if mode=="duel" else 62.0
    if c.evo=="nisen" and c.pulses==count-1:radius*=1.45
    area(point,radius,power,c.id,0.22 if c.lv>=2 else 0.13,Vector2(c.dir)*(30 if c.pulses==count-1 else 3));c.pulses+=1
   c.total=maxf(float(c.total),float(c.startup)+count*spacing+0.23)
  if c.age>c.total:casts.erase(c)
 _tick_projectiles(dt);_tick_traps(dt);_tick_assistants(dt)
 if oiroke_time>0:
  oiroke_time=maxf(0,oiroke_time-dt);oiroke_tick-=dt
  if oiroke_tick<=0:
   oiroke_tick=0.65
   for spot in oiroke_points():area(spot,82*render_scale,12*build.power("oiroke"),"oiroke",0.18)
 for e in effects.duplicate():
  e.age+=dt
  if e.age>=e.life:effects.erase(e);effect_pool.release(e)
 queue_redraw()
func oiroke_points() -> Array[Vector2]:
 var lv:int=int(build.levels.get("oiroke",1))
 var count:int=1+2*(lv-1)
 var spots:Array[Vector2]=[oiroke_pos]
 for j in range(1,count):spots.append(oiroke_pos+Vector2.from_angle(TAU*float(j-1)/float(count-1))*(65+35*(lv-1))*render_scale)
 return spots
func activate(c:Dictionary) -> void:
 var id:String=c.id;var origin:Vector2=c.origin;var point:Vector2=c.point;var dir:Vector2=c.dir;var lv=int(c.lv);var evo:String=c.evo
 var power=float(Registry.DATA[id].damage)*float(c.power);var sage=build.form_branch=="sage" and build.form_stage>0;var rb=1.22 if sage else 1.0
 if _hero_id()!="naruto" and _class_cast(c,_hero_id()):return
 match id:
  "rasengan":
   if evo=="rasenshuriken":projectile(id,"rasenshuriken",origin+Vector2(0,-30),dir,420,power,31,1.65,{"blast":true,"pierce":1})
   else:
    var at:Vector2=point
    if mode=="duel":host.skill_dash(dir*220,220);at=host.skill_origin()+dir*53
    else:clone_effect(point-dir*35,dir.x,0.52)
    effect("rasengan",at+Vector2(0,-26),110 if evo=="odama" else 68+lv*9,0.5)
    area(at,(110 if evo=="odama" else 66+lv*7)*rb,power,id,0.3,dir*(30+lv*12))
    if evo=="odama":trap(at,0.23,100,power*0.38,id,"wind")
   host.skill_sound("rasengan.wav")
  "naruto_rendan":
   if mode=="duel":host.skill_dash(dir*180,180);c.point=host.skill_origin()+dir*65
   host.skill_sound("clone.wav")
  "fuma_shuriken":
   host.skill_sound("throw.wav")
   for i in range(2 if evo=="double_fuma" else 1):projectile(id,"fuma",origin+Vector2(0,-33),dir.rotated((float(i)-0.5)*0.15) if evo=="double_fuma" else dir,390,power,23+lv*3,1.0,{"return":lv>=2,"pierce":8,"orbit":evo=="blade_orbit"})
  "shuriken_barrage":
   host.skill_sound("throw.wav")
   volley(origin,point,dir,lv,power,evo)
   if evo=="shadow_shuriken" and traps.size()<28:traps.append({"kind":"volley","pos":origin-dir*36,"point":point,"dir":dir,"delay":0.38,"lv":lv,"damage":power*0.7,"id":id})
  "kunai_kibaku":
   var at=point if mode=="survival" else origin+dir*clampf(absf(point.x-origin.x),130,360)
   effect("kunai",origin+Vector2(0,-22),48,0.26,dir.angle());trap(at,0.85 if lv<3 else 0.6,(85+lv*10)*render_scale,power,id,"blast",evo)
   if evo=="chain_blast":trap(at+dir*83,1.12,95*render_scale,power*0.7,id,"blast");trap(at-dir*70,1.35,95*render_scale,power*0.65,id,"blast")
  "kuchiyose":
   var at=point if mode=="survival" else origin+dir*clampf(absf(point.x-origin.x),120,340)
   effect("bunta" if evo=="gamabunta" else "frog",at,235 if evo=="gamabunta" else 130,0.9)
   var radius=(155 if evo=="gamabunta" else 95+lv*9)*render_scale
   trap(at,0.26,radius,power,id,"slam")
   if lv>=2:trap(at,0.58,radius*1.18,power*0.22,id,"slam")
   if evo=="gamakichi_assault":trap(at+dir*66,0.78,radius,power*0.72,id,"frog");trap(at+dir*130,1.28,radius,power*0.72,id,"frog")
   host.skill_sound("clone.wav")
  "henge_feint":
   var at=point
   if mode=="duel" and absf(point.x-origin.x)>480:at=origin+dir*480
   effect("fuma",origin+Vector2(0,-24),45,0.32,dir.angle());effect("smoke",at,95,0.5);clone_effect(at+dir*45,-dir.x,0.7);trap(at,0.19,80*render_scale,power,id,"hit")
   if lv>=2:counter_time=maxf(counter_time,1.35)
   if lv>=3:decoy_pos=at;decoy_time=maxf(decoy_time,1.5)
   if evo=="double_feint":trap(at-dir*45,0.43,85*render_scale,power*0.65,id,"hit");clone_effect(at-dir*45,dir.x,0.7)
   if evo=="clone_counter":decoy_pos=at;decoy_time=3.2;counter_time=3.2
   if "fuma_shuriken" in build.owned():trap(at,0.7,100*render_scale,power*0.36,id,"fuma")
  "gama_teppo":
   host.skill_sound("water_cast.wav")
   effect("frog",origin-dir*30,125,1.15)
   for i in range(2 if lv>=2 and evo!="suiton_wave" else 1):projectile(id,"water_dragon" if evo=="suiton_wave" else "wind" if evo=="futon_wave" else "water",origin+Vector2(0,-27)+dir*i*38,dir,360 if evo=="futon_wave" else 290 if evo=="suiton_wave" else 265,power*1.8 if evo=="suiton_wave" else power,38 if evo=="suiton_wave" else 19+lv*3,1.7 if evo=="suiton_wave" else 1.3,{"pierce":99,"interval":0.21,"push":22.0 if evo=="suiton_wave" else 17.0 if lv>=3 else 9.0})
   if sage:projectile(id,"wind",origin+Vector2(0,-36),dir,400,power*0.5,40,1.15,{"pierce":99,"interval":0.28})
 if _hero_id()=="naruto" and build.form_branch=="kyubi" and build.form_stage==2 and id in ["rasengan","naruto_rendan","kuchiyose"]:effect("chakra_arm",origin+dir*48+Vector2(0,-35),130,0.45);trap(point,0.32,80*render_scale,power*0.2,id,"hit")
 if not assistants.is_empty() and id in ["rasengan","naruto_rendan"]:clone_effect(point-dir*50,dir.x,0.6);trap(point,0.4,70*render_scale,power*0.26,id,"hit")
func volley(origin:Vector2,point:Vector2,dir:Vector2,lv:int,power:float,evo:String) -> void:
 for i in range(3+lv):
  var heading=dir.rotated((i-(2+lv)*0.5)*0.055);var at=origin+Vector2(0,-28)-dir*i*18
  if evo=="shuriken_rain":at=point+Vector2((i-(2+lv)*0.5)*27,-230);heading=Vector2.DOWN
  projectile("shuriken_barrage","shuriken",at,heading,650,power,9,1.6,{"pierce":1 if lv>=2 else 0})
func projectile(id:String,art:String,pos:Vector2,dir:Vector2,speed:float,damage:float,radius:float,life:float,extra:Dictionary={}) -> void:
 if projectiles.size()>=MAX_PROJECTILES:return
 var p=projectile_pool.acquire({"id":id,"art":art,"pos":pos,"dir":dir,"speed":speed,"damage":damage,"radius":radius,"life":life,"age":0.0,"hit":{},"pierce":0,"returned":false,"interval":0.0});p.merge(extra,true);projectiles.append(p)
func trap(at:Vector2,delay:float,radius:float,damage:float,id:String,art:String,evo:String="") -> void:
 if traps.size()<28:traps.append({"kind":"blast","pos":at,"delay":delay,"radius":radius,"damage":damage,"id":id,"art":art,"evo":evo})
func _tick_traps(dt:float) -> void:
 for t in traps.duplicate():
  t.delay-=dt
  if t.delay>0:continue
  traps.erase(t)
  if t.kind=="volley":volley(t.pos,t.point,t.dir,t.lv,t.damage,"");continue
  effect(t.art,t.pos+Vector2(0,-16),float(t.radius)*1.65,0.48);area(t.pos,t.radius,t.damage,t.id,0.18)
  if t.id=="kunai_kibaku":host.skill_sound("explosion_v8.wav")
  if t.get("evo","")=="fragment_trap":
   for i in range(8):projectile(t.id,"shuriken",t.pos+Vector2(0,-25),Vector2.from_angle(i*TAU/8),500,float(t.damage)*0.26,9,0.7,{"pierce":2})
func _tick_projectiles(dt:float) -> void:
 for p in projectiles.duplicate():
  p.life-=dt;p.age+=dt;var prev:Vector2=p.pos
  if p.get("orbit",false) and p.age>0.55:p.pos+=Vector2.from_angle(clock*15)*dt*100
  else:p.pos+=Vector2(p.dir)*float(p.speed)*dt
  if p.life<=0:
   if p.get("return",false) and not p.returned:p.returned=true;p.life=1.0;p.dir=(host.skill_origin()+Vector2(0,-30)-Vector2(p.pos)).normalized();p.hit.clear()
   else:
    if p.get("blast",false):area(p.pos,120*render_scale,p.damage*0.7,p.id);effect("wind",p.pos,220,0.5)
    projectiles.erase(p);projectile_pool.release(p);continue
  for e in host.skill_targets().duplicate():
   if float(e.get("hp",0))<=0:continue
   var center:Vector2=e.pos+Vector2(0,-30*render_scale);var rad=(32*render_scale if mode=="duel" else 22.0)+float(p.radius);var uid:int=int(e.actor.get_instance_id());var interval:float=0.22 if p.get("orbit",false) else float(p.interval)
   if Resolver.swept_hit(prev,p.pos,center,rad) and Resolver.can_hit(p.hit,uid,clock,interval):
    hit(e,p.damage,p.id,0.1,Vector2(p.dir)*float(p.get("push",8)))
    if p.id=="shuriken_barrage" and int(build.levels.get(p.id,1))>=2:e.marked_until=clock+4
    if p.id=="gama_teppo" and build.evolution_choices.get(p.id,"")=="suiton_wave":e.slowed_until=clock+1.25
    if p.get("blast",false):area(p.pos,110*render_scale,p.damage*0.65,p.id);effect("wind",p.pos,200,0.5)
    p.pierce-=1
    if p.pierce<0:projectiles.erase(p);projectile_pool.release(p);break
func area(at:Vector2,radius:float,damage:float,id:String,stagger:float=0.0,push:Vector2=Vector2.ZERO) -> void:
 for e in host.skill_targets().duplicate():
  if float(e.get("hp",0))>0 and at.distance_to(e.pos)<=radius:hit(e,damage,id,stagger,push)
func hit(e:Dictionary,damage:float,id:String,stagger:float=0.0,push:Vector2=Vector2.ZERO) -> void:
 if id=="kunai_kibaku" and float(e.get("marked_until",0))>clock and "shuriken_barrage" in build.owned():damage*=1.45;e.marked_until=0;effect("blast",e.pos+Vector2(0,-25),100,0.4)
 if counter_time>0:damage*=1.2
 host.skill_hit(e,damage,id,stagger,push);hit_history[id]=int(hit_history.get(id,0))+1;effect("hit",e.pos+Vector2(0,-30*render_scale),55*render_scale,0.36)
 if id in ["kunai_kibaku","rasengan","kuchiyose"]:effect("blast",e.pos+Vector2(0,-20*render_scale),90*render_scale,0.50)
 elif id in ["gama_teppo","henge_feint"]:effect("wind",e.pos+Vector2(0,-28*render_scale),78*render_scale,0.54)
 if mode=="survival":host.skill_sound("water_hit.wav" if id=="gama_teppo" else "heavy_hit.wav" if id in ["rasengan","kuchiyose","kunai_kibaku"] else "impact.wav")
func utility() -> bool:
 if build.utility_id=="" or utility_cd>0:return false
 utility_cd=build.cooldown(build.utility_id,mode);var pos:Vector2=host.skill_origin();var lv=int(build.levels.get(build.utility_id,1));host.skill_pose("210",0.42);effect("smoke",pos,105,0.6)
 match build.utility_id:
  "kage_bunshin":
   host.skill_sound("clone_smoke.wav")
   for i in range(2+(1 if lv==3 else 0)):
    if assistants.size()<4:assistants.append({"pos":pos+Vector2((i*2-1)*44,0),"life":4.5+lv,"cd":0.3+i*0.2,"facing":host.skill_facing()})
   host.skill_sound("clone.wav")
  "oiroke":
   oiroke_time=3.0+lv;oiroke_pos=pos;oiroke_tick=0
   for spot in oiroke_points():area(spot,82*render_scale,19*build.power("oiroke"),"oiroke",0.55)
   host.skill_sound("oiroke_puff.wav" if _hero_id()=="naruto" else "heavy_hit.wav")
  "gamakichi_support":support_time=3.5+lv;support_charges=4+lv*2;support_pos=pos
  "bunshin_decoy":decoy_pos=pos;decoy_time=3.0+lv;counter_time=2.3
 return true
func intercept(pos:Vector2) -> bool:
 if support_time>0 and support_charges>0 and pos.distance_to(support_pos)<125*render_scale:support_charges-=1;effect("smoke",pos,60,0.32);return true
 return false
func _tick_assistants(dt:float) -> void:
 for a in assistants.duplicate():
  a.life-=dt;a.cd-=dt
  if a.life<=0:effect("smoke",a.pos,80,0.5);assistants.erase(a);continue
  var target=nearest(a.pos,800)
  if target.is_empty():continue
  var vec:Vector2=target.pos-a.pos
  if mode=="survival":a.pos=Vector2(a.pos).move_toward(target.pos,90*dt)
  a.facing=signf(vec.x)
  if a.cd<=0:a.cd=1.05;projectile("kage_bunshin","kunai",a.pos+Vector2(0,-28),vec.normalized() if mode=="survival" else Vector2(a.facing,0),480,13*build.power("kage_bunshin"),8,1.6)
func effect(art:String,at:Vector2,width:float,life:float,angle:float=0.0) -> void:
 if effects.size()<MAX_EFFECTS:effects.append(effect_pool.acquire({"art":art,"pos":at,"width":width,"age":0.0,"life":life,"angle":angle}))
func clone_effect(at:Vector2,facing:float,life:float) -> void:
 if effects.size()<MAX_EFFECTS:effects.append(effect_pool.acquire({"art":"clone","pos":at,"width":60,"age":0.0,"life":life,"angle":0.0,"facing":facing}))
func draw_art(id:String,at:Vector2,width:float,time:float,angle:float=0.0,alpha:float=1.0,bottom:bool=false) -> void:
 if id=="water_dragon":
  var dragon=Art.texture("res://assets/v12/water_dragon.png")
  var dims=Vector2(width,width*float(dragon.get_height())/dragon.get_width()*(1+sin(time*11)*0.045))
  draw_set_transform(at,angle)
  draw_texture_rect(dragon,Rect2(-dims*.5,dims),false,Color(1,1,1,alpha))
  for i in range(6):
   var droplet=Vector2(-width*.4+fposmod(time*70+i*19,width*.45),sin(i*2.4+time*9)*width*.18)
   draw_circle(droplet,1.5,Color(.7,.96,1,alpha*.7))
  draw_set_transform(Vector2.ZERO);return
 if id in FX.IDS:
  FX.paint(self,id,at,width,time,angle,alpha);return
 var tex=Art.frame(id,time)
 if tex==null:return
 var size:Vector2=tex.get_size()*width/maxf(1,tex.get_width());draw_set_transform(at,angle);draw_texture_rect(tex,Rect2(Vector2(-size.x*0.5,-size.y if bottom else -size.y*0.5),size),false,Color(1,1,1,alpha));draw_set_transform(Vector2.ZERO)
func draw_clone(at:Vector2,time:float,facing:float,alpha:float=0.8) -> void:
 var info=Art.actor(build.actor_pack(),"210",time);var factor:float=info.scale*render_scale;var axis:Vector2=info.axis
 draw_set_transform(at,0,Vector2((-1 if facing<0 else 1)*(-1 if info.flip_h else 1),-1 if info.flip_v else 1)*factor);draw_texture(info.texture,-axis+info.offset,Color(0.83,0.95,1,alpha));draw_set_transform(Vector2.ZERO)
func _draw() -> void:
 if build==null:return
 for t in traps:
  if t.kind=="blast":draw_art("note" if t.id=="kunai_kibaku" else "smoke",t.pos+Vector2(0,-12),35 if t.id=="kunai_kibaku" else 55,clock)
 for p in projectiles:
  draw_art(p.art,p.pos,float(p.radius)*(3.6 if p.art=="water_dragon" else 2.7)+12,p.age,clock*12 if p.art in ["fuma","shuriken"] else Vector2(p.dir).angle())
 for e in effects:
  var alpha=1.0-float(e.age)/e.life
  if e.art=="clone":draw_clone(e.pos,e.age,e.facing,alpha)
  elif e.art in FX.IDS:FX.paint(self,e.art,e.pos,e.width,e.age,e.angle,alpha)
  else:
   var seq=Art.frames(e.art)
   if seq.is_empty():continue
   var index=clampi(int((float(e.age)/float(e.life))*seq.size()),0,seq.size()-1)
   var tex:Texture2D=seq[index]
   var size:Vector2=tex.get_size()*float(e.width)/maxf(1,tex.get_width())
   draw_set_transform(e.pos,e.angle)
   draw_texture_rect(tex,Rect2(Vector2(-size.x*0.5,-size.y if e.art in ["frog","bunta"] else -size.y*0.5),size),false,Color(1,1,1,alpha))
   draw_set_transform(Vector2.ZERO)
 for a in assistants:draw_clone(a.pos,clock,a.facing,0.8)
 if decoy_time>0:draw_clone(decoy_pos,clock,host.skill_facing(),0.5)
 if support_time>0:draw_art("frog" if _hero_id()=="naruto" else _class_art(_hero_id()),support_pos,110,clock,0,0.9,true)
 if oiroke_time>0:
  for spot in oiroke_points():draw_art("oiroke" if _hero_id()=="naruto" else _class_art(_hero_id()),spot,65*render_scale,clock,0,1,true)

## Alpha uses actual class-specific effects instead of repurposed Naruto frogs, Oiroke, and Rasengan.
func _hero_id()->String:
 var alpha=get_node_or_null("/root/AlphaProgress")
 return str(alpha.selected) if alpha!=null else "naruto"
func _class_art(hero:String)->String:
 match hero:
  "sasuke":return "blast"
  "kakashi":return "rasengan"
  "rock_lee":return "lee_air"
  "neji":return "gentle_palm"
  "gaara":return "sand"
 return "rasengan"
func _class_cast(c:Dictionary,hero:String)->bool:
 var id:String=str(c.id)
 if hero in ["rock_lee","neji"] and id in ["fuma_shuriken","shuriken_barrage","kunai_kibaku","henge_feint"]:
  return _class_close_jutsu(c,hero)
 if id not in ["rasengan","naruto_rendan","kuchiyose","gama_teppo"]:return false
 var origin:Vector2=c.origin
 var dir:Vector2=c.dir
 var target:Vector2=c.point
 var power:float=float(Registry.DATA[id].damage)*float(c.power)
 var evo:String=str(c.get("evo",""))
 var evo_index:int=Registry.DATA[id].get("evolutions",[]).find(evo) if not evo.is_empty() else -1
 if evo_index==0:power*=1.25
 elif evo_index==1:
  power*=0.92
  counter_time=maxf(counter_time,0.65)
 var level:int=int(c.lv)
 var art:String=_class_art(hero)
 var extra_hits:int=2 if level>=3 else 1
 match id:
  "rasengan":
   # Sasuke Chidori, Kakashi Raikiri, Lee Omote Renge, Neji Air Palm, Gaara Sand Coffin.
   if hero in ["sasuke","kakashi","rock_lee"] and mode=="duel":
    host.skill_dash(dir*130.0,130.0)
    origin=host.skill_origin()
    target=origin+dir*105.0
   effect(art,target+Vector2(0,-28),125.0+level*11.0,0.53,dir.angle())
   area(target,68.0*render_scale+level*8.0,power*1.15,id,0.25,dir*32.0)
   if level>=2:trap(target+dir*35.0,0.19,70.0*render_scale,power*0.31,id,art)
  "naruto_rendan":
   if hero=="neji":
    # Group sixteen waves into 64 close chakra-point contacts, not a missile.
    var at:Vector2=origin+dir*61.0
    effect("gentle_palm",at,98.0,0.48,dir.angle())
    for n in range(16):
     trap(at,0.04+float(n)*0.048,51.0*render_scale,power*0.083,id,"gentle_palm")
    host.skill_sound("impact.wav")
    return true
   if hero=="rock_lee":
    var at:Vector2=origin+dir*67.0
    for n in range(3+extra_hits):
     trap(at+dir*float(n%2)*9.0,0.08+float(n)*0.11,62.0*render_scale,power*0.35,id,"lee_air")
    effect("lee_air",at,113.0,0.56,dir.angle())
    host.skill_sound("swing.wav")
    return true
   # Personal multi-hit kata, not the Naruto clone Rendan.
   host.skill_sound("impact.wav")
   for n in range(3+extra_hits):
    var hit_at:Vector2=target+dir*float(n-1)*18.0
    trap(hit_at,0.04+float(n)*0.13,60.0*render_scale,power*0.44,id,art)
   effect(art,target+Vector2(0,-28),92,0.55)
  "kuchiyose":
   # Character-specific ultimate without the Gamabunta frog sprite.
   effect(art,target+Vector2(0,-35),225.0,0.72)
   if hero in ["gaara","sasuke"]:
    for n in range(3):
     var at:Vector2=target+Vector2.from_angle(float(n)*TAU/3.0)*67.0
     trap(at,0.15+0.13*float(n),87.0*render_scale,power*0.51,id,art)
   elif hero=="kakashi":
    for n in range(3):
     var at:Vector2=target+Vector2(float(n-1)*76.0,-19.0)
     trap(at,0.13+float(n)*0.16,80.0*render_scale,power*0.56,id,art)
   else:
    area(target,140.0*render_scale,power*0.86,id,0.38)
    trap(target,0.24,123.0*render_scale,power*0.47,id,art)
  "gama_teppo":
   if hero=="rock_lee":
    # Ura Renge has close taijutsu impacts, no green long-distance bullets.
    var at:Vector2=origin+dir*75.0
    for n in range(4+level):
     var impact_at:Vector2=at+dir*float(n%3-1)*12.0
     trap(impact_at,0.10+float(n)*0.075,66.0*render_scale,power*0.29,id,"lee_air")
    effect("lee_air",at,125.0,0.44,dir.angle())
    host.skill_sound("heavy_hit.wav")
    return true
   if hero=="neji":
    # Hakke Kaiten, a radial contact defence, not a vacuum projectile.
    var at:Vector2=origin
    effect("gentle_palm",at,185.0,0.46)
    for n in range(3+level):
     trap(at,0.09+float(n)*0.10,88.0*render_scale,power*0.30,id,"gentle_palm")
    host.skill_sound("parry.wav")
    return true
   # Katon / lightning / desert rain for ranged classes.
   host.skill_sound("water_cast.wav" if hero=="kakashi" else "throw.wav")
   var count:int=1+extra_hits+(1 if level>=3 else 0)
   for n in range(count):
    var heading:Vector2=dir.rotated((float(n)-float(count-1)*0.5)*0.15)
    projectile(id,art,origin+Vector2(0,-29),heading,360.0+float(level)*35.0,
      power*(0.79 if count>2 else 0.98),20.0+float(level)*5.0,1.45,
      {"pierce":2 if level>=3 else 0,"push":22.0})
 host.skill_sound("explosion_v8.wav" if hero=="sasuke" else "heavy_hit.wav" if hero=="gaara" else "impact.wav")
 return true

## Lore-specific close techniques. Most common Naruto 'fuma' slots now mean
## *different physical melee techniques* for Lee/Neji, never reskinned missiles.
func _class_close_jutsu(c:Dictionary,hero:String)->bool:
 var id:String=str(c.id)
 var origin:Vector2=c.origin
 var dir:Vector2=c.dir
 var lv:int=int(c.lv)
 var power:float=float(Registry.DATA[id].damage)*float(c.power)
 var evo:String=str(c.get("evo",""))
 var evo_index:int=Registry.DATA[id].get("evolutions",[]).find(evo) if not evo.is_empty() else -1
 if evo_index==0:power*=1.25
 elif evo_index==1:
  power*=0.92
  counter_time=maxf(counter_time,0.65)
 var close:Vector2=origin+dir*72.0
 if hero=="rock_lee":
  match id:
   "fuma_shuriken":
    # Leaf Gale: low sweep and close stagger.
    effect("lee_air",close,94,0.34,dir.angle())
    trap(close,0.14,72.0*render_scale,power*1.12,id,"lee_air")
   "shuriken_barrage":
    # Konoha Dai Senpū: animated series of physical kicks.
    for i in range(4+lv):trap(close+dir*float(i%2)*13.0,0.11+float(i)*0.09,64.0*render_scale,power*0.36,id,"lee_air")
    effect("lee_air",close,117.0,0.63,dir.angle())
   "kunai_kibaku":
    # Leaf Rising Wind, a launching blow (not explosive kunai).
    effect("lee_air",close,122,0.43,dir.angle())
    trap(close,0.19,79.0*render_scale,power*1.22,id,"lee_air")
   "henge_feint":
    # Drunken Fist step: physical counter/feint, not Naruto Henge clone.
    counter_time=maxf(counter_time,1.5+float(lv)*0.35)
    decoy_time=maxf(decoy_time,0.42)
    decoy_pos=origin+Vector2(-dir.x*24.0,0)
    effect("lee_air",origin,90.0,0.38)
    trap(close,0.24,59.0*render_scale,power*0.65,id,"lee_air")
  host.skill_sound("swing.wav")
  return true
 if hero=="neji":
  match id:
   "fuma_shuriken":
    # Hakke Kūshō only unlocks a short/midrange vacuum strike at level 3.
    if lv>=3:
     projectile(id,"gentle_palm",origin+Vector2(0,-27),dir,310,power,25,0.8,{"pierce":0})
    else:
     effect("gentle_palm",close,87.0,0.42,dir.angle())
     trap(close,0.16,73.0*render_scale,power*0.90,id,"gentle_palm")
   "shuriken_barrage":
    # Gentle Fist uninterrupted close-range hits.
    for i in range(4+lv):trap(close,0.09+float(i)*0.08,48.0*render_scale,power*0.34,id,"gentle_palm")
    effect("gentle_palm",close,113.0,0.55)
   "kunai_kibaku":
    # Kaiten interrupts incoming attackers around the actor.
    effect("gentle_palm",origin,165.0,0.55)
    for i in range(3+lv):trap(origin,0.12+float(i)*0.09,87.0*render_scale,power*0.36,id,"gentle_palm")
    counter_time=maxf(counter_time,0.55+0.12*float(lv))
   "henge_feint":
    # Byakugan precision counter, small radial chakra seal.
    counter_time=maxf(counter_time,1.25+float(lv)*0.25)
    effect("gentle_palm",origin,90.0,0.4)
    trap(close,0.28,72.0*render_scale,power*0.88,id,"gentle_palm")
  host.skill_sound("impact.wav")
  return true
 return false
