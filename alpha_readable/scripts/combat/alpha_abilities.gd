extends RefCounted
## Six genuinely different playstyles and 36 triggered tree signatures.
## All attack forms use the existing capped FX, AoE and collision machinery.
const PATTERNS={
 "naruto":["nova","summon","fan","ring","chain","guard"],
 "sasuke":["pierce","fan","suppress","chain","guard","nova"],
 "kakashi":["pierce","suppress","summon","fan","guard","chain"],
 "rock_lee":["chain","pierce","nova","fan","guard","ring"],
 "neji":["suppress","chain","ring","pierce","fan","guard"],
 "gaara":["nova","guard","chain","suppress","fan","ring"]
}
const FX_COLORS={
 "naruto":"chakra_blast","sasuke":"chakra_blast","kakashi":"futon_blast",
 "rock_lee":"smoke_blast","neji":"chakra_blast","gaara":"smoke_blast"
}
const SFX={
 "naruto":"rasengan.wav","sasuke":"explosion_v8.wav","kakashi":"heavy_hit.wav",
 "rock_lee":"impact.wav","neji":"rasengan.wav","gaara":"heavy_hit.wav"
}
static func ability_type(hero:String,tree:int)->String:
 if not PATTERNS.has(hero) or tree<0 or tree>=6:return ""
 return str(PATTERNS[hero][tree])
static func activate(g,hero:String,tree:int,apex:bool,power:float,route:int=0)->bool:
 var pattern:String=ability_type(hero,tree)
 if pattern.is_empty():return false
 var mult:float=(1.44 if apex else 1.0)*maxf(0.7,power)
 var damage:float=(47.0+float(tree)*9.5)*mult
 var area:float=(72.0+float(tree%3)*13.0)*(1.18 if apex else 1.0)
 # Both talent forks influence the actual attack, not only the UI.
 # Left: concentrated damage; right: battlefield control and wider impact.
 if route<0:
  damage*=1.27
  area*=0.84
 elif route>0:
  damage*=0.89
  area*=1.35
  if "invulnerable" in g:g.invulnerable=maxf(g.invulnerable,0.12)
 var player_at:Vector2=g.player_pos
 var target:Dictionary=g._closest_target(player_at,560.0)
 var at:Vector2=target["pos"] if not target.is_empty() else player_at+Vector2(g.player_facing*90.0,0)
 var direction:Vector2=(at-player_at).normalized()
 if direction.length_squared()<0.01:direction=Vector2.RIGHT
 var art:String=str(FX_COLORS.get(hero,"chakra_blast"))
 match pattern:
  "nova":
   g._aoe_damage(at,area*1.50,damage*1.25)
   g._add_blast(at,area*1.50,art)
   for i in range(4):
    var p:Vector2=at+Vector2.from_angle(float(i)*TAU/4.0)*area*0.55
    g._add_blast(p,area*0.42,art)
  "fan":
   for i in range(5):
    var vec:Vector2=direction.rotated((float(i)-2.0)*0.34)
    var at2:Vector2=player_at+vec*(area*1.15+float(i%2)*24.0)
    g._aoe_damage(at2,area*0.46,damage*0.44)
    g._add_blast(at2,area*0.52,art)
  "pierce":
   for i in range(5):
    var at2:Vector2=player_at+direction*(38.0+float(i)*area*0.65)
    g._aoe_damage(at2,area*0.41,damage*0.49)
    g._add_blast(at2,area*0.48,art)
   g.dash_cooldown=maxf(0.0,g.dash_cooldown-0.42)
  "ring":
   g.invulnerable=maxf(g.invulnerable,0.32 if apex else 0.21)
   for i in range(8):
    var at2:Vector2=player_at+Vector2.from_angle(float(i)*TAU/8.0)*area*0.92
    g._aoe_damage(at2,area*0.32,damage*0.32)
    g._add_blast(at2,area*0.32,art)
  "suppress":
   g._aoe_damage(at,area*1.25,damage*0.88)
   g._add_blast(at,area*1.25,art)
   for enemy in g.enemies:
    if not enemy.has("pos"):continue
    if Vector2(enemy["pos"]).distance_to(at)>area*1.7:continue
    enemy["stagger"]=maxf(float(enemy.get("stagger",0.0)),0.66 if apex else 0.38)
   if g.boss_active and not g.boss.is_empty():
    if Vector2(g.boss.get("pos",Vector2.ZERO)).distance_to(at)<area*1.7:
     g._aoe_damage(at,area,damage*0.30)
  "chain":
   var hits:int=0
   var visited:Array=[]
   var current:Vector2=at
   for index in range(4 if apex else 3):
    var nearest:Dictionary={}
    var best:float=370.0*370.0
    for enemy in g.enemies:
     if visited.has(enemy) or not enemy.has("pos"):continue
     var distance:float=Vector2(enemy["pos"]).distance_squared_to(current)
     if distance<best:best=distance;nearest=enemy
    if nearest.is_empty():break
    visited.append(nearest)
    current=nearest["pos"]
    g._aoe_damage(current,area*0.64,damage*(0.85-0.08*float(index)))
    g._add_blast(current,area*0.72,art)
    hits+=1
   if hits==0:
    g._aoe_damage(at,area,damage)
    g._add_blast(at,area,art)
  "guard":
   g.invulnerable=maxf(g.invulnerable,0.65 if apex else 0.42)
   g.player_hp=minf(g.build.max_hp(),g.player_hp+(13.0 if apex else 7.0))
   g._aoe_damage(player_at,area*1.30,damage*0.68)
   g._add_blast(player_at,area*1.40,art)
  "summon":
   if hero=="naruto":
    g.clone_cooldown=0.0
    g._spawn_clones()
   else:
    for i in range(4):
     var near:Vector2=at+Vector2.from_angle(float(i)*TAU/4.0)*area*.82
     g._aoe_damage(near,area*.48,damage*.56)
     g._add_blast(near,area*.54,art)
 if hero=="gaara" and tree in [1,5]:
  g.invulnerable=maxf(g.invulnerable,0.55 if apex else 0.32)
 if hero=="rock_lee" and tree in [0,2,3]:
  g.dash_cooldown=maxf(0.0,g.dash_cooldown-0.60)
 if hero=="neji" and tree in [0,2,3]:
  g.invulnerable=maxf(g.invulnerable,0.32)
 g._sfx(str(SFX.get(hero,"impact.wav")))
 return true

## Distinct neutral attacks that work before any scroll or talent is purchased.
static func attack_rate(hero:String)->float:
 return float({"naruto":1.0,"sasuke":0.94,"kakashi":0.89,
 "rock_lee":0.72,"neji":0.88,"gaara":1.11}.get(hero,1.0))
static func basic_burst(g,hero:String,sequence:int)->void:
 var enemy:Dictionary=g._closest_target(g.player_pos,345.0)
 var at:Vector2=enemy["pos"] if not enemy.is_empty() else g.player_pos+Vector2(g.player_facing*66.0,0)
 match hero:
  "sasuke":
   if sequence%4==0:
    g._aoe_damage(at,62.0,22.0)
    g._add_blast(at,72.0,"chakra_blast")
  "kakashi":
   if sequence%5==0:
    g._aoe_damage(at,50.0,19.0)
    g.dash_cooldown=maxf(0.0,g.dash_cooldown-0.16)
    g._add_blast(at,54.0,"futon_blast")
  "rock_lee":
   if sequence%2==0:
    g._aoe_damage(g.player_pos,84.0,31.0)
    g._add_blast(g.player_pos+Vector2(g.player_facing*33.0,-18.0),68.0,"smoke_blast")
  "neji":
   if sequence%4==0:
    g._aoe_damage(g.player_pos,89.0,21.0)
    g.invulnerable=maxf(g.invulnerable,0.13)
    g._add_blast(g.player_pos,85.0,"chakra_blast")
  "gaara":
   if sequence%4==0:
    g._aoe_damage(at,77.0,29.0)
    g._add_blast(at,78.0,"smoke_blast")
    g.invulnerable=maxf(g.invulnerable,0.16)
  "naruto":
   if sequence%6==0:
    g._aoe_damage(at,48.0,16.0)
    g._add_blast(at,51.0,"chakra_blast")
