extends RefCounted
## Concrete combat patterns for the five non-Naruto heroes.
## Uses same pooled hit detection, cooldowns, targeting and sound system as V12.
## No sprite forgery: this module only becomes selectable after required MUGEN packs exist.
const Roster=preload("res://scripts/alpha/roster.gd")
const Base=preload("res://scripts/core/jutsu_registry.gd")
static func path_index(id:String,evolution:String) -> int:
 if not Base.DATA.has(id):return -1
 return Base.DATA[id].evolutions.find(evolution)
static func activate(rt,c:Dictionary,hero_id:String) -> void:
 if hero_id=="naruto":
  return
 var id=str(c.id)
 var slot=Roster.SLOT_IDS.find(id)
 if slot<0:return
 var h=Roster.hero(hero_id)
 if h.is_empty():return
 var point:Vector2=c.point
 var origin:Vector2=c.origin
 var direction:Vector2=c.dir
 var lv=int(c.lv)
 var choice=path_index(id,str(c.evo))
 var damage=float(Base.DATA[id].damage)*float(c.power)*float(h.attack)
 var branch_mul=1.32 if choice==0 else 1.18 if choice==1 else 1.0
 damage*=branch_mul
 var radius=rt.render_scale*float(56+lv*11)
 var tint_art="wind"
 match hero_id:
  "sasuke":tint_art="blast"
  "rock_lee":tint_art="slash"
  "kakashi":tint_art="chakra"
  "neji":tint_art="wind"
  "gaara":tint_art="sand"
 var speed_mul=float(h.speed)
 match slot:
  0:
   # Strong signature strike (Chidori, Senpū, Raikiri, Jūken, Sand Coffin).
   if hero_id in ["sasuke","rock_lee","kakashi"] and rt.mode=="duel":
    rt.host.skill_dash(direction*(155.0+25.0*lv),200.0)
    point=rt.host.skill_origin()+direction*62.0
   rt.effect(tint_art,point+Vector2(0,-28),radius*1.8,0.46)
   rt.area(point,radius,damage,id,0.18+0.035*lv,direction*float(16+10*lv))
   if choice==0:rt.trap(point,0.22,radius*1.26,damage*0.48,id,tint_art)
   if choice==1:rt.projectile(id,tint_art,point,direction,480*speed_mul,damage*.44,22,0.75,{"pierce":2})
  1:
   # Multi-contact combo. Not a generic single-number attack.
   var count=3+lv+(2 if choice==0 else 0)
   for i in range(count):
    var where=point+direction*float(i%3-1)*26*rt.render_scale
    rt.trap(where,0.05+0.12*i,radius*.72,damage*.36,id,tint_art)
   rt.effect(tint_art,point,radius*2,0.52)
  2:
   for i in range(2 if choice==0 else 1):
    var angle=(float(i)*2.0-1.0)*0.1 if choice==0 else 0.0
    rt.projectile(id,"fuma" if hero_id in ["kakashi","sasuke"] else tint_art,
      origin+Vector2(0,-26),direction.rotated(angle),
      (360.0+lv*42)*speed_mul,damage*.9,19+lv*4,1.2,{"pierce":2+lv,"return":choice==1})
  3:
   var count=5+lv*2+(2 if choice==0 else 0)
   for i in range(count):
    var spread=(float(i)-float(count-1)*.5)*0.095
    rt.projectile(id,"shuriken" if hero_id in ["sasuke","kakashi"] else tint_art,
      origin+Vector2(0,-25),direction.rotated(spread),
      335*speed_mul,damage*.4,12,1.2,{"pierce":1+(1 if choice==1 else 0)})
  4:
   # Persistent control through delayed explosions / ground pressure.
   for i in range(2+lv):
    var land=point+Vector2.from_angle(float(i)*2.399)*float(26+18*lv)
    rt.trap(land,0.13+float(i)*.16,radius*(.78 if choice==1 else 1.0),
      damage*(.68 if choice==0 else .49),id,tint_art)
   rt.effect(tint_art,point,radius*2,0.65)
  5:
   # Summon/field-like pressure; variant B emphasizes immediate burst.
   var pulses=3+lv+(2 if choice==0 else 0)
   for i in range(pulses):
    rt.trap(point+Vector2.from_angle(float(i)*TAU/float(pulses))*radius*.65,
      .17+.18*i,radius*.78,damage*.42,id,tint_art)
   if choice==1:rt.area(point,radius*1.2,damage*.65,id,.15)
  6:
   # Defensive control skill makes an actual counter window and interrupts targets.
   rt.counter_time=maxf(rt.counter_time,1.3+0.35*lv)
   rt.effect(tint_art,origin,radius*1.7,0.55)
   rt.area(point,radius*1.2,damage*.7,id,.34,direction*22)
   if choice==0:rt.trap(origin,.3,radius,damage*.5,id,tint_art)
  7:
   # Wide elemental sweep, lightning beam, Kaiten / Shukaku fan etc.
   var streams=2+lv+(1 if choice==0 else 0)
   for i in range(streams):
    var spread=(float(i)-float(streams-1)*.5)*.16
    rt.projectile(id,tint_art,origin+Vector2(0,-35),
      direction.rotated(spread),450*speed_mul,damage*.5,25,
      1.1+0.2*lv,{"pierce":5+(3 if choice==1 else 0),"blast":choice==0})
 rt.host.skill_sound("heavy_hit.wav" if slot in [0,1,4,7] else "mid_hit.wav")
