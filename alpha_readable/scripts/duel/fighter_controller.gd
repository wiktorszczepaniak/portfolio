extends RefCounted
## Movement is independent of move timings; host retains the public QA/skill interface.
static func step(g,dt:float,direction:float) -> Dictionary:
 var can_move=g.hurt_time<=0 and not g.block and g.attack_time<=0.12 and g.skills.lock_time<=0.16
 if can_move and direction!=0:g.player_facing=1 if g.boss.pos.x>g.player_pos.x else -1
 if not can_move:direction=0
 var speed=260+float(g.build.passives.get("speed",0))*11+(15 if g.build.form_branch=="kyubi" else 0)
 g.player_pos.x=clampf(g.player_pos.x+(g.dash_direction*820 if g.dash_time>0 else direction*speed)*dt,65,1215)
 if g.player_pos.y<g.FLOOR or g.velocity.y<0:
  g.velocity.y+=1280*dt;g.player_pos.y+=g.velocity.y*dt
  if g.player_pos.y>=g.FLOOR:
   g.player_pos.y=g.FLOOR;g.velocity.y=0;g.jumps_remaining=2;g.landing_time=3.0/60.0;g.record_action("landing")
 if absf(g.player_pos.x-float(g.boss.pos.x))<66 and absf(g.player_pos.y-g.FLOOR)<70 and g.dash_time<=0:
  var side=signf(g.player_pos.x-float(g.boss.pos.x))
  if side==0:side=-g.player_facing
  g.player_pos.x=clampf(float(g.boss.pos.x)+side*66,65,1215)
 if direction==0 and g.attack_time<=0 and g.skills.lock_time<=0:g.player_facing=1 if g.boss.pos.x>g.player_pos.x else -1
 return {"direction":direction,"can_move":can_move}
