extends Node2D
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
 var origin:Vector2=host.skill_origin();var target=nearest(origin)
 if target.is_empty():return false
 if mode=="duel" and not host.skill_spend(id):return false
 var d:Dictionary=Registry.DATA[id];var point:Vector2=target.pos
 var direction=(point-origin).normalized() if mode=="survival" else Vector2(host.skill_facing(),0)
 if direction.length_squared()<0.1:direction=Vector2.RIGHT
 var total:float=float(d.startup)+float(d.active)+float(d.recovery)
 cooldowns[id]=build.cooldown(id,mode)
 if mode=="duel":lock_time=total
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
  if c.id=="naruto_rendan" and c.active:
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
   for i in range(2 if evo=="double_fuma" else 1):projectile(id,"fuma",origin+Vector2(0,-33),dir.rotated((float(i)-0.5)*0.15) if evo=="double_fuma" else dir,390,power,23+lv*3,1.0,{"return":lv>=2,"pierce":8,"orbit":evo=="blade_orbit"})
  "shuriken_barrage":
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
   effect("frog",origin-dir*30,125,1.15)
   for i in range(2 if lv>=2 and evo!="suiton_wave" else 1):projectile(id,"water_dragon" if evo=="suiton_wave" else "wind" if evo=="futon_wave" else "water",origin+Vector2(0,-27)+dir*i*38,dir,360 if evo=="futon_wave" else 290 if evo=="suiton_wave" else 265,power*1.8 if evo=="suiton_wave" else power,38 if evo=="suiton_wave" else 19+lv*3,1.7 if evo=="suiton_wave" else 1.3,{"pierce":99,"interval":0.21,"push":22.0 if evo=="suiton_wave" else 17.0 if lv>=3 else 9.0})
   if sage:projectile(id,"wind",origin+Vector2(0,-36),dir,400,power*0.5,40,1.15,{"pierce":99,"interval":0.28})
 if build.form_branch=="kyubi" and build.form_stage==2 and id in ["rasengan","naruto_rendan","kuchiyose"]:effect("chakra_arm",origin+dir*48+Vector2(0,-35),130,0.45);trap(point,0.32,80*render_scale,power*0.2,id,"hit")
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
 host.skill_sound("impact.wav")
func utility() -> bool:
 if build.utility_id=="" or utility_cd>0:return false
 utility_cd=build.cooldown(build.utility_id,mode);var pos:Vector2=host.skill_origin();var lv=int(build.levels.get(build.utility_id,1));host.skill_pose("210",0.42);effect("smoke",pos,105,0.6)
 match build.utility_id:
  "kage_bunshin":
   for i in range(2+(1 if lv==3 else 0)):
    if assistants.size()<4:assistants.append({"pos":pos+Vector2((i*2-1)*44,0),"life":4.5+lv,"cd":0.3+i*0.2,"facing":host.skill_facing()})
   host.skill_sound("clone.wav")
  "oiroke":
   oiroke_time=3.0+lv;oiroke_pos=pos;oiroke_tick=0
   for spot in oiroke_points():area(spot,82*render_scale,19*build.power("oiroke"),"oiroke",0.55)
   host.skill_sound("oiroke_puff.wav")
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
  if p.art=="water_dragon":
   var dragon:Texture2D=Art.frame("water_dragon",p.age*0.86)
   if dragon!=null:
    var factor:float=(float(p.radius)*3.1+12)/maxf(1,dragon.get_width())
    var dims=dragon.get_size()*factor
    draw_set_transform(p.pos,0,Vector2(-1 if p.dir.x<0 else 1,1))
    draw_texture_rect(dragon,Rect2(-dims*0.5,dims),false)
    draw_set_transform(Vector2.ZERO)
  else:draw_art(p.art,p.pos,float(p.radius)*(1.8 if p.art=="water" else 2.7)+12,clock,clock*12 if p.art in ["fuma","shuriken","rasenshuriken"] else Vector2(p.dir).angle())
 for e in effects:
  var alpha=1.0-float(e.age)/e.life
  if e.art=="clone":draw_clone(e.pos,e.age,e.facing,alpha)
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
 if support_time>0:draw_art("frog",support_pos,110,clock,0,0.9,true)
 if oiroke_time>0:
  for spot in oiroke_points():draw_art("oiroke",spot,65*render_scale,clock,0,1,true)
