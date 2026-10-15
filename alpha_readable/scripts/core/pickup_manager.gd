extends RefCounted
static func step(g,dt:float) -> void:
 for d in g.drops.duplicate():
  var at:Vector2=d.pos
  var distance:float=at.distance_to(g.player_pos)
  var magnet_radius:float=138.0+float(g.upgrades["magnet"])*48.0
  if distance<magnet_radius and distance>0.0:d.pos+=(g.player_pos-at).normalized()*dt*minf(430.0,1800.0/(distance+15.0)*50.0)
  if distance>31.0:continue
  g.drops.erase(d)
  if d.type=="xp":
   g._sfx("pickup.wav")
   g.exp_value+=float(d.value);g.stat_exp_collected+=int(d.value)
   if g.exp_value>=g.exp_needed:
    g.exp_value-=g.exp_needed;g.level+=1;g.alpha.award_for_level(g.level);g.exp_needed=18.0+float(g.level)*10.55;g._open_upgrade(false);return
  elif d.type in ["heal","ramen"]:g.player_hp=minf(g.PLAYER_MAX_HP+float(g.upgrades["max_hp"])*18.0,g.player_hp+float(d.value))
  elif d.type=="chest":g._open_chest();return
  else:g._open_upgrade(true);return
