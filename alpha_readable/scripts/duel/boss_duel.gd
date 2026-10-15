extends Node2D
const FX=preload("res://scripts/combat/ninja_fx.gd")
const AlphaAbilities=preload("res://scripts/combat/alpha_abilities.gd")
const Actor=preload("res://scripts/mugen_actor.gd")
const Adapter=preload("res://scripts/combat/duel_skill_adapter.gd")
const AI=preload("res://scripts/duel/sasori_ai.gd")
const HUD=preload("res://scripts/duel/duel_hud.gd")
const Art=preload("res://scripts/combat/combat_art.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
const Resolver=preload("res://scripts/combat/combat_resolver.gd")
const MoveState=preload("res://scripts/duel/move_state_machine.gd")
const Controls=preload("res://scripts/duel/duel_input.gd")
const Fighter=preload("res://scripts/duel/fighter_controller.gd")
var controls=Controls.new()
var melee=MoveState.new()
var action_log:Array=[]
var fighter_state:="idle"
var shake_time:=0.0
var combo_chain:=0
var last_contact:=-10.0
const FLOOR:=582.0
var build
var skills
var ai
var player
var boss:Dictionary={}
var player_pos:=Vector2(285,FLOOR)
var velocity:=Vector2.ZERO
var player_facing:=1.0
var player_hp:=165.0
var chakra:=100.0
var invulnerable:=0.0
var hurt_time:=0.0
var dash_cd:=0.0
var dash_time:=0.0
var dash_direction:=1.0
var block:=false
var block_age:=0.0
var jumps_remaining:=2
var auto_guard_time:=0.0
var retreat_window:=0.0
var retreat_direction:=0.0
var landing_time:=0.0
var sfx_last:Dictionary={}
var attack_time:=0.0
var combo_stage:=0
var combo_age:=0.0
var combo_hit:=false
var combo_buffer:=0.0
var hitstop:=0.0
var elapsed:=0.0
var intro:=true
var paused:=false
var finished:=false
var victory:=false
var selected_slot:=-1
var announce_text:=""
var announce_time:=0.0
var projectiles:Array=[]
var zones:Array=[]
var background:Texture2D
var music:AudioStreamPlayer
var sound:AudioStreamPlayer
var before_duel:Dictionary={}
var alpha:Node
var talent_effect_counter:int=0
var phase_damage:Array=[0.0,0.0]
var damage_received:=0.0
var parries:=0
func _ready() -> void:
 alpha=get_node_or_null("/root/AlphaProgress");talent_effect_counter=0
 build=get_node("/root/RunBuild");before_duel=build.snapshot();texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;background=Art.texture("res://assets/v12/akatsuki_cave.png")
 player=Actor.new();player.pack_name=build.actor_pack();player.scale=Vector2.ONE*2.1;add_child(player)
 var enemy=Actor.new();enemy.pack_name="sasori_hiruko";enemy.scale=Vector2.ONE*2.1;add_child(enemy)
 boss={"actor":enemy,"pos":Vector2(970,FLOOR),"hp":5200.0,"max_hp":5200.0,"stagger":0.0,"marked_until":0.0}
 skills=Adapter.new();skills.configure(self,build);add_child(skills);ai=AI.new(self)
 var layer=CanvasLayer.new();add_child(layer);var hud=HUD.new();hud.g=self;layer.add_child(hud)
 music=AudioStreamPlayer.new();add_child(music);sound=AudioStreamPlayer.new();add_child(sound)
 music.stream=AudioStreamMP3.load_from_buffer(FileAccess.get_file_as_bytes("res://assets/audio/sasori_battle.mp3"));music.stream.loop=true;music.volume_db=-80 if build.muted else -16;music.play();reset_fight()
func reset_fight() -> void:
 talent_effect_counter=0
 controls.queued.clear();melee.reset();action_log.clear();combo_chain=0;last_contact=-10;shake_time=0
 player_pos=Vector2(285,FLOOR);velocity=Vector2.ZERO;jumps_remaining=2;auto_guard_time=0.0;retreat_window=0.0;retreat_direction=0.0;landing_time=0.0;sfx_last.clear();player_hp=build.max_hp();chakra=100;invulnerable=1;hurt_time=0;dash_cd=0;dash_time=0;attack_time=0;combo_stage=0;combo_age=0;combo_buffer=0;hitstop=0;block=false;block_age=0
 player.set_pack(build.actor_pack());boss.actor.set_pack("sasori_hiruko");boss.pos=Vector2(970,FLOOR);boss.hp=5200.0;boss.max_hp=5200.0;boss.marked_until=0
 ai.reset();skills.reset();projectiles.clear();zones.clear();elapsed=0;finished=false;victory=false;paused=false;phase_damage=[0.0,0.0];damage_received=0;parries=0;player.position=player_pos;boss.actor.position=boss.pos;boss.actor.facing=-1;announce("SASORI / HIRUKO",2)
func start_fight() -> void:
 if intro:intro=false;selected_slot=-1
func swap_slot(slot:int) -> void:
 if not intro:return
 if selected_slot<0:selected_slot=slot
 else:build.reorder(selected_slot,slot);selected_slot=-1
func retry() -> void:
 if not finished or victory or build.retry_used:return
 build.retry_used=true;reset_fight();intro=false
func _input(event:InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not intro and not paused and not finished:
  controls.queued.combo=true

 if not event is InputEventKey or not event.pressed or event.echo:return
 var key=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 if intro:
  if key==KEY_ENTER:start_fight()
  elif key in [KEY_J,KEY_K,KEY_L]:swap_slot([KEY_J,KEY_K,KEY_L].find(key))
  elif key in [KEY_1,KEY_2,KEY_3]:swap_slot(key-KEY_1)
  return
 if finished:
  if key==KEY_R:retry()
  elif key==KEY_ENTER:get_tree().change_scene_to_file("res://scenes/main.tscn")
  return
 if key==KEY_ESCAPE:paused=not paused;return
 if key==KEY_M:build.muted=not build.muted;music.volume_db=-80 if build.muted else -16;return
 if key==KEY_G:build.godmode=not build.godmode;return
 if paused:return
 controls.push(key)

func _process(delta:float) -> void:
 if intro or paused or finished:
  if intro:player.tick(delta);boss.actor.tick(delta)
  queue_redraw();return
 step(minf(delta,0.05))
func step(dt:float,commands:Dictionary={}) -> void:
 if intro or paused or finished:return
 if hitstop>0:hitstop=maxf(0,hitstop-dt);return
 var input=controls.consume(commands)
 elapsed+=dt;announce_time=maxf(0,announce_time-dt);invulnerable=maxf(0,invulnerable-dt);hurt_time=maxf(0,hurt_time-dt);dash_cd=maxf(0,dash_cd-dt);dash_time=maxf(0,dash_time-dt)
 var direction=float(input.move)
 var pressed_block=bool(input.block)
 auto_guard_time=maxf(0,auto_guard_time-dt)
 retreat_window=maxf(0,retreat_window-dt);landing_time=maxf(0,landing_time-dt)
 if Controls.retreat(direction,player_pos.x,float(boss.pos.x)) and player_pos.y>=FLOOR-1:retreat_window=0.16;retreat_direction=direction
 if input.get("jump",false):jump()
 if input.get("dash",false):dash()
 if input.get("combo",false):combo_buffer=0.24
 if input.has("slot"):skills.request_slot(input.slot)
 if input.get("utility",false):skills.utility()
 block=pressed_block and player_pos.y>=FLOOR-1 and attack_time<=0 and skills.lock_time<=0 and dash_time<=0;block_age=block_age+dt if block else 0.0
 var movement=Fighter.step(self,dt,direction)
 direction=movement.direction;var can_move=movement.can_move
 chakra=minf(100,chakra+dt*(13+build.passives.get("magnet",0)*1.6));player_hp=minf(build.max_hp(),player_hp+dt*0.3*float(build.passives.get("regeneration",0)));combo_buffer=maxf(0,combo_buffer-dt)
 if skills.buffer_time>0 and attack_time>0 and melee.can_cancel():
  attack_time=0;combo_buffer=0;combo_stage=0;melee.reset();record_action("jutsu_cancel")
 if combo_buffer>0 and skills.buffer_time<=0 and (attack_time<=0 or melee.can_cancel()) and skills.lock_time<=0.12 and hurt_time<=0 and landing_time<=0 and not block:start_combo();combo_buffer=0
 if attack_time>0:
  var active_window=melee.advance(dt)
  combo_age=melee.age;attack_time=maxf(0,melee.duration()-melee.age)
  if active_window and absf(boss.pos.x-player_pos.x)<(float(melee.definition.reach)+29 if build.form_branch=="sage" else float(melee.definition.reach)) and absf(player_pos.y-FLOOR)<95 and (boss.pos.x-player_pos.x)*player_facing>=0:
   melee.connected=true;combo_hit=true
   skill_hit(boss,(76+build.passives.get("kunai_twin",0)*6)*float(melee.definition.damage),"basic",0.12,Vector2(player_facing*(22 if combo_stage==3 else 10),0))
  if attack_time<=0 and combo_buffer<=0:combo_stage=0;melee.reset()
 fighter_state="hurt" if hurt_time>0 else "dash" if dash_time>0 else "blockstun" if auto_guard_time>0 else "block" if block else melee.phase if attack_time>0 else "double_jump" if player_pos.y<FLOOR-1 and jumps_remaining==0 else "jump" if player_pos.y<FLOOR-1 else "landing" if landing_time>0 else "run" if direction!=0 else "idle"
 shake_time=maxf(0,shake_time-dt)
 position=Vector2(sin(elapsed*150)*3.0,cos(elapsed*170)*1.5) if shake_time>0 else Vector2.ZERO
 skills.tick(dt);ai.tick(dt);update_hazards(dt);player.position=player_pos;player.facing=player_facing;player.moving=absf(direction)>0.01 and can_move;player.dashing=dash_time>0
 if hurt_time>0:player.pose_action="5000";player.pose_time=0.1
 elif block or auto_guard_time>0:player.pose_action="130";player.pose_time=0.1
 elif attack_time<=0 and skills.lock_time<=0:
  if player_pos.y<FLOOR-1:player.pose_action="41" if velocity.y<-140 else "42" if velocity.y<140 else "43";player.pose_time=0.1
  elif direction!=0 and Controls.retreat(direction,player_pos.x,float(boss.pos.x)):player.pose_action="21";player.pose_time=0.1

 player.tick(dt);boss.actor.position=boss.pos;boss.actor.facing=-1 if boss.pos.x>player_pos.x else 1;boss.actor.tick(dt);player.z_index=100;boss.actor.z_index=100
 if player_hp<=0:finish(false)
 queue_redraw()
func jump() -> void:
 if jumps_remaining>0 and hurt_time<=0 and skills.lock_time<=0.18 and attack_time<=0.15:
  velocity.y=-620 if jumps_remaining==2 else -555
  player_pos.y=minf(player_pos.y,FLOOR-2)
  jumps_remaining-=1
  block=false
  skills.effect("wind",player_pos+Vector2(0,-10),65,0.3)
  skill_sound("dash.wav")
func dash() -> void:
 if dash_cd>0 or hurt_time>0 or (attack_time>0 and not melee.can_cancel()):return
 if attack_time>0:attack_time=0;combo_stage=0;combo_buffer=0;melee.reset();record_action("dash_cancel")
 dash_cd=maxf(1.65,3-0.18*build.passives.get("speed",0));dash_time=0.23;dash_direction=player_facing;invulnerable=0.4;skills.effect("log",player_pos+Vector2(0,-22),50,0.65);skills.effect("smoke",player_pos+Vector2(0,-25),110,0.45);skill_sound("dash.wav")
func start_combo() -> void:
 combo_stage=combo_stage%3+1;combo_age=0;combo_hit=false
 player_facing=signf(boss.pos.x-player_pos.x)
 var gap=absf(boss.pos.x-player_pos.x)
 if gap<230 and player_pos.y>=FLOOR-95:player_pos.x+=player_facing*minf(64,maxf(0,gap-82))
 skill_sound("swing.wav")
 skills.effect("wind",player_pos+Vector2(player_facing*42,-60),65,0.16)
 melee.start(combo_stage,int(build.passives.get("kunai_rapid",0)));attack_time=melee.duration()
 player.play_pose(melee.definition.action,attack_time)
 record_action("melee_start",{"stage":combo_stage})
func record_action(event:String,data:Dictionary={}) -> void:
 if action_log.size()>=1024:action_log.pop_front()
 action_log.append({"time":elapsed,"event":event,"data":data.duplicate(true)})

func skill_origin() -> Vector2:return player_pos
func skill_facing() -> float:return player_facing
func skill_targets() -> Array:return [boss] if not finished else []
func skill_pose(action:String,duration:float) -> void:player.play_pose(action,duration)
func skill_dash(movement:Vector2,_limit:float) -> void:
 var travel=movement.x
 if (boss.pos.x-player_pos.x)*travel>0:travel=signf(travel)*minf(absf(travel),maxf(0,absf(boss.pos.x-player_pos.x)-74))
 player_pos.x=clampf(player_pos.x+travel,65,1215);invulnerable=maxf(invulnerable,0.16)
func skill_spend(id:String) -> bool:
 if hurt_time>0 or attack_time>0 or block or ai.phase_pause>0:return false
 var cost=Registry.cost(id)
 if chakra<cost:announce("BRAK CHAKRY",0.7);return false
 chakra-=cost;return true
func skill_hit(target:Dictionary,damage:float,id:String,stagger:float,push:Vector2) -> void:
 if target!=boss or ai.phase_pause>0 or boss.hp<=0 or finished:return
 var break_guard=id in ["rasengan","kuchiyose"] or (build.form_branch=="sage" and build.form_stage>0 and id in ["basic","naruto_rendan","henge_feint"])
 if ai.state=="telegraph" and ai.pattern=="tail" and not break_guard:damage*=minf(0.84,0.48+float(build.passives.get("kunai_pierce",0))*0.12) if id=="basic" else 0.48
 # Keep class talents active in the boss fight; protect boss phases with the existing hit cap.
 if alpha!=null:
  damage*=alpha.damage_multiplier()
  talent_effect_counter+=1
  if alpha.proc_ready():
   var talent_tree:int=alpha.current_signature()
   if talent_tree>=0:_duel_talent_effect(talent_tree)
 if id=="basic":
  combo_chain=combo_chain+1 if elapsed-last_contact<1.0 else 1
  last_contact=elapsed;damage*=maxf(0.75,1.0-0.035*(combo_chain-1))
 record_action("contact",{"id":id,"phase":melee.phase if id=="basic" else "skill","stage":combo_stage})
 shake_time=0.10 if id=="basic" and combo_stage<3 else 0.16
 if id=="basic" and ai.state=="recover":damage*=1.35;chakra=minf(100,chakra+4)
 damage=minf(damage*0.60,float(boss.max_hp)*0.06);boss.hp=maxf(0,boss.hp-damage);phase_damage[ai.phase-1]+=damage;boss.actor.hit_flash=0.12
 if id in ["oiroke","henge_feint"]:ai.interrupt(stagger)
 if ai.state=="recover" and ai.cc_immunity<=0 and stagger>0:ai.stagger=minf(0.22,stagger);ai.cc_immunity=0.72
 if ai.state=="recover":boss.pos.x=clampf(float(boss.pos.x)+push.x*0.45,90,1190)
 hitstop=maxf(hitstop,(3.0 if combo_stage<3 else 6.0)/60.0 if id=="basic" else 0.045)
 skills.effect("hit",boss.pos+Vector2(0,-74),78 if id=="basic" else 118,0.40)
 if id in ["rasengan","kunai_kibaku","kuchiyose"]:skills.effect("blast",boss.pos+Vector2(0,-70),145,0.5)
 elif id in ["gama_teppo","henge_feint"]:skills.effect("wind",boss.pos+Vector2(0,-80),124,0.42)
 skill_sound("heavy_hit.wav" if id!="basic" or combo_stage==3 else "mid_hit.wav" if combo_stage==2 else "impact.wav")
 if boss.hp<=0:
  if ai.phase==1:
   ai.phase_two();boss.hp=6300.0;boss.max_hp=6300.0;boss.actor.set_pack("sasori_puppet");projectiles.clear();zones.clear();skills.projectiles.clear();skills.traps.clear();skills.casts.clear();announce("HIRUKO ZNISZCZONY  /  FAZA II",2.2);skill_sound("transform.wav")
  else:finish(true)
func _duel_talent_effect(tree_index:int)->void:
 if alpha==null or tree_index<0:return
 var style:String=AlphaAbilities.ability_type(alpha.selected,tree_index)
 var apex:bool=alpha.apex_unlocked(tree_index)
 var at:Vector2=boss.pos+Vector2(0,-70)
 var visual:String="blast" if style in ["nova","fan","summon","chain"] else "wind" if style in ["pierce","ring"] else "hit"
 var radius:float=170.0 if apex else 118.0
 skills.effect(visual,at,radius,0.45)
 match style:
  "pierce":
   chakra=minf(100.0,chakra+(8.0 if apex else 5.0))
   dash_cd=maxf(0.0,dash_cd-0.5)
  "fan":
   boss.marked_until=maxf(float(boss.get("marked_until",0.0)),elapsed+1.2)
  "nova":
   shake_time=maxf(shake_time,0.20)
  "ring":
   invulnerable=maxf(invulnerable,0.36 if apex else 0.22)
  "chain":
   combo_chain=maxi(0,combo_chain-2)
  "guard":
   invulnerable=maxf(invulnerable,0.42 if apex else 0.26)
   player_hp=minf(build.max_hp(),player_hp+(12.0 if apex else 7.0))
  "summon":
   chakra=minf(100.0,chakra+(15.0 if apex else 9.0))
   auto_guard_time=maxf(auto_guard_time,0.15)
  "suppress":
   if ai.state=="recover" and ai.cc_immunity<=0:
    ai.stagger=maxf(ai.stagger,0.18 if apex else 0.09)
    ai.cc_immunity=0.72
 if alpha.selected=="rock_lee":dash_cd=maxf(0.0,dash_cd-0.3)
 if alpha.selected=="neji":invulnerable=maxf(invulnerable,0.16)
 if alpha.selected=="gaara":player_hp=minf(build.max_hp(),player_hp+5.0)
 skill_sound("rasengan.wav" if alpha.selected=="naruto" else "heavy_hit.wav")
 record_action("alpha_signature",{"hero":alpha.selected,"tree":tree_index,"pattern":style,"apex":apex})
 announce(str(alpha.tree_name(tree_index))+"  /  "+("APEX" if apex else "SYGNATURA"),0.7)

func hurt(damage:float,unblockable:bool=false,poison:bool=false,source_x:float=NAN) -> void:
 if build.godmode or invulnerable>0 or finished:return
 var attacker_x=float(boss.pos.x) if is_nan(source_x) else source_x
 var front=(attacker_x-player_pos.x)*player_facing>=0
 var guarding:bool=front and (block or (retreat_window>0 and Controls.retreat(retreat_direction,player_pos.x,attacker_x) and player_pos.y>=FLOOR-1 and attack_time<=0.13 and skills.lock_time<=0.16))
 if guarding and not unblockable:
  auto_guard_time=0.24
  if block and block_age<=0.16:
   skill_sound("parry.wav")
   parries+=1;chakra=minf(100,chakra+8)
   if build.form_branch=="sage":skills.counter_time=1.5+(1 if build.form_stage==2 else 0);ai.interrupt(0.2)
   if build.form_branch=="sage" and build.form_stage==2:skills.projectile("frog_kata_counter","wind",player_pos+Vector2(0,-45),Vector2(signf(boss.pos.x-player_pos.x),0),520,90,30,1.7,{"pierce":1})
   skills.effect("hit",player_pos+Vector2(player_facing*30,-65),70,0.18);record_action("parry");invulnerable=0.18;announce("PERFEKCYJNY BLOK",0.65);return
  skill_sound("block.wav")
  skills.effect("hit",player_pos+Vector2(player_facing*30,-65),55,0.16);record_action("guard");damage*=0.24;chakra=maxf(0,chakra-9)
 damage=Resolver.mitigated(damage,build)
 if skills.support_time>0:damage*=0.55
 player_hp=maxf(0,player_hp-damage);damage_received+=damage;invulnerable=0.4;hurt_time=0.14 if not guarding else 0;player.hit_flash=0.17;hitstop=0.04
 if not guarding:attack_time=0;combo_buffer=0;combo_stage=0;melee.reset();record_action("hurt")
 if poison and not guarding:announce("ZATRUCIE  /  OPUŚĆ STREFĘ",0.7)
 if not guarding:skill_sound("impact.wav")
func boss_attack(kind:String,at:Vector2) -> void:
 var origin:Vector2=boss.pos+Vector2(0,-65);var dir=signf(at.x-origin.x)
 skill_sound("throw.wav")
 match kind:
  "needle_fan":
   for i in range(5):enemy_projectile(origin,Vector2(dir,0).rotated((i-2)*0.18),"senbon",360,12,8)
  "iron_rain":
   for x in range(90,1240,100):
    if absf(x-at.x)>155:enemy_projectile(Vector2(x,190),Vector2.DOWN,"sand",370,21,12)
  "puppet_sweep":
   var left=ai.segment%2==0
   enemy_projectile(Vector2(35 if left else 1245,FLOOR-18),Vector2.RIGHT if left else Vector2.LEFT,"sand",430,23,16,true)
  "senbon":
   for i in range(4):enemy_projectile(origin+Vector2(dir*i*28,0),Vector2(dir,0),"senbon",440,13,10)
  "tail":zones.append({"rect":Rect2(boss.pos.x-235,FLOOR-88,470,88),"life":0.32,"damage":29.0,"unblockable":true,"kind":"tail","hit":false});skills.effect("sand",boss.pos+Vector2(-dir*20,-30),290,0.4)
  "poison":zones.append({"rect":Rect2(at.x-80,FLOOR-42,160,42),"life":2.0,"damage":7.0,"unblockable":true,"kind":"poison","hit":false})
  "sand_sweep":enemy_projectile(Vector2(boss.pos.x,FLOOR-20),Vector2(dir,0),"sand",355,27,24,true)
  "cross":enemy_projectile(Vector2(35,FLOOR-65),Vector2.RIGHT,"chakra",385,20,12);enemy_projectile(Vector2(1245,FLOOR-95),Vector2.LEFT,"chakra",340,20,12)
  "lances":
   for offset in [-105,0,105]:enemy_projectile(Vector2(clampf(at.x+offset,65,1215),160),Vector2.DOWN,"sand",385,22,17)
  "air_counter":
   for i in range(3):enemy_projectile(origin,(at+Vector2(0,-50)-origin).normalized().rotated((i-1)*0.12),"senbon",500,16,12)
func enemy_projectile(at:Vector2,dir:Vector2,art:String,speed:float,damage:float,radius:float,unblockable:bool=false) -> void:
 if projectiles.size()<40:projectiles.append({"pos":at,"dir":dir,"art":art,"speed":speed,"damage":damage,"radius":radius,"life":4.0,"unblockable":unblockable})
func update_hazards(dt:float) -> void:
 for p in projectiles.duplicate():
  p.life-=dt;var prev:Vector2=p.pos;p.pos+=p.dir*p.speed*dt
  if p.life<=0 or p.pos.x<0 or p.pos.x>1280 or p.pos.y>FLOOR+25:projectiles.erase(p);continue
  if skills.intercept(p.pos):projectiles.erase(p);continue
  if segment_rect(prev,p.pos,Rect2(player_pos-Vector2(23,119),Vector2(46,119)).grow(p.radius)):hurt(p.damage,p.unblockable,false,prev.x);projectiles.erase(p)
 for z in zones.duplicate():
  z.life-=dt
  if z.life<=0:zones.erase(z);continue
  if z.rect.intersects(Rect2(player_pos-Vector2(22,115),Vector2(44,115))) and (not z.hit or z.kind=="poison"):hurt(z.damage,z.unblockable,z.kind=="poison");z.hit=true
func segment_rect(a:Vector2,b:Vector2,r:Rect2) -> bool:
 if r.has_point(a) or r.has_point(b):return true
 var corners=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
 for i in range(4):
  if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4])!=null:return true
 return false
func announce(text:String,duration:float) -> void:announce_text=text;announce_time=duration
func skill_sound(name:String) -> void:
 var path="res://assets/v9/oiroke_puff.wav" if name=="oiroke_puff.wav" else "res://assets/v8/explosion_v8.wav" if name=="explosion_v8.wav" else "res://assets/audio/"+name
 if get_node("/root/AudioDirector").play_effect(path,name,build.muted):sfx_last[name]=Time.get_ticks_msec()*0.001

func finish(won:bool) -> void:
 finished=true;victory=won
 var f=FileAccess.open("user://duel_result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"victory":won,"seconds":elapsed,"phase":ai.phase,"build":build.snapshot(),"damage_received":damage_received},"  "))
func _draw() -> void:
 if background==null:return
 draw_texture_rect_region(background,Rect2(0,0,1280,720),Rect2(0,26,400,225))
 if ai!=null and ai.phase==2:draw_rect(Rect2(0,0,1280,720),Color(.12,.025,.09,.12))
 for i in range(12):
  var dust=Vector2(fposmod(i*107+elapsed*18,1320)-20,330+sin(i*4.1+elapsed*.6)*140)
  draw_line(dust,dust+Vector2(7,0),Color(1,.8,.6,.18),1)
 if ai==null:return
 if ai.phase_pause>0:draw_rect(Rect2(0,0,1280,720),Color(0.1,0.03,0.04,0.35))
 if ai.state=="telegraph":
  var warn=Color(0.95,0.35,0.24,0.25+0.15*sin(elapsed*17))
  if ai.pattern=="iron_rain":
   for x in range(90,1240,100):
    if absf(x-ai.aim.x)>155:draw_rect(Rect2(x-18,190,36,FLOOR-190),warn)
   draw_rect(Rect2(ai.aim.x-140,FLOOR-9,280,9),Color("8bddaa"))
  elif ai.pattern=="puppet_sweep":draw_rect(Rect2(20,FLOOR-38,1240,38),warn)
  elif ai.pattern=="poison":draw_rect(Rect2(ai.aim.x-80,FLOOR-42,160,42),warn)
  elif ai.pattern=="lances":
   for x in [-105,0,105]:draw_rect(Rect2(ai.aim.x+x-18,170,36,FLOOR-170),warn)
  elif ai.pattern=="tail":draw_rect(Rect2(boss.pos.x-235,FLOOR-88,470,88),warn)
  elif ai.pattern=="sand_sweep":draw_rect(Rect2(20,FLOOR-38,1240,38),warn)
  else:draw_line(boss.pos+Vector2(0,-65),ai.aim+Vector2(0,-65),Color(1,0.52,0.35,0.5),2)
 for p in projectiles:
  if p.art in FX.IDS:
   FX.paint(self,p.art,p.pos,75,elapsed,Vector2(p.dir).angle());continue
  var tex=Art.frame(p.art,elapsed)
  if tex!=null:
   var size:Vector2=tex.get_size()*(75 if p.art=="senbon" else 95)/maxf(tex.get_width(),tex.get_height());draw_set_transform(p.pos,Vector2(p.dir).angle());draw_texture_rect(tex,Rect2(-size*0.5,size),false);draw_set_transform(Vector2.ZERO)
 for z in zones:
  if z.kind=="poison":
   FX.paint(self,"poison",z.rect.get_center(),z.rect.size.x,elapsed,0,0.8)
 if attack_time>0:
  FX.paint(self,"wind",player_pos+Vector2(player_facing*50,-65),80,combo_age,0,0.65)
 if ai.state=="recover":
  draw_arc(boss.pos+Vector2(0,-4),46,0,PI,24,Color("87ddad"),3)
 if block:draw_arc(player_pos+Vector2(0,-45),64,-PI*0.48 if player_facing>0 else PI*0.52,PI*0.48 if player_facing>0 else PI*1.48,20,Color("a7ebe1"),3)

func _exit_tree() -> void:
 for child in get_children():
  if child is AudioStreamPlayer:
   child.stop();child.stream=null
