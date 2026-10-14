extends RefCounted
## Six-character Alpha roster and 48 fully specified skill families.
## Content metadata only: MUGEN packs must be checked before claiming a playable hero.
const IDS=["naruto","sasuke","rock_lee","kakashi","neji","gaara"]
const SLOT_IDS=["rasengan","naruto_rendan","fuma_shuriken","shuriken_barrage","kunai_kibaku","kuchiyose","henge_feint","gama_teppo"]
const ROLES=["BURST","COMBO","PROJECTILE","VOLLEY","TRAP","SUMMON","CONTROL","ELEMENT"]
const HEROES={
"naruto":{"name":"UZUMAKI NARUTO","pack":["naruto_base","naruto_kyubi","naruto_kcm"],"alternate":["naruto_base","naruto_sage","naruto_sennin"],"branch_names":["KYŪBI / KCM","SAGE / SENNIN"],"accent":"f6a42e","hp":165.0,"attack":1.0,"speed":1.0,"skills":[
["Rasengan","Ōdama Rasengan","Fūton: Rasenshuriken"],["Naruto Rendan","Nisen Rendan","Bunshin Combo Rush"],["Fūma Shuriken","Double Fūma","Blade Orbit"],["Shuriken Barrage","Shuriken Rain","Shadow Shuriken"],["Kibaku Fuda","Chain Blast","Fragment Trap"],["Kuchiyose","Gamabunta","Gamakichi Assault"],["Henge Feint","Double Feint","Clone Counter"],["Gama Teppō","Suiton Wave","Fūton Wave"]]},
"sasuke":{"name":"UCHIHA SASUKE","pack":["sasuke_base","sasuke_sharingan","sasuke_mangekyo"],"alternate":["sasuke_base","sasuke_curse1","sasuke_curse2"],"branch_names":["SHARINGAN / MANGEKYŌ","CURSE MARK / LEVEL 2"],"accent":"a9a0ef","hp":146.0,"attack":1.12,"speed":1.05,"skills":[
["Chidori","Chidori Sharp Spear","Chidori Current"],["Shishi Rendan","Lion's Barrage","Lightning Finisher"],["Kusanagi","Sword Dance","Chidori Blade"],["Hōsenka","Phoenix Ember Rain","Katon Chain"],["Gōkakyū","Great Fireball","Dragon Flame"],["Kuchiyose: Hebi","Serpent Strike","Orochi Crush"],["Sharingan Feint","Genjutsu Trap","Counter Illusion"],["Kirin","Thunder Descent","Heavenly Lightning"]]},
"rock_lee":{"name":"ROCK LEE","pack":["lee_base","lee_gates","lee_gates6"],"alternate":["lee_base","lee_drunken","lee_lotus"],"branch_names":["EIGHT GATES / SIXTH","DRUNKEN FIST / LOTUS"],"accent":"6dcb7d","hp":177.0,"attack":1.03,"speed":1.18,"skills":[
["Konoha Senpū","Double Senpū","Leaf Cyclone"],["Dynamic Entry","Meteor Kick","Air Combo"],["Konoha Reppū","Gale Sweep","Rising Hurricane"],["Konoha Shōfū","Updraft Combo","Sky Breaker"],["Front Lotus","Ura Renge","Giant Impact"],["Leaf Hurricane","Whirlwind Kick","Vortex Field"],["Drunken Feint","Sway Counter","Unpredictable Rush"],["Gate Burst","Morning Peacock","Speed Blitz"]]},
"kakashi":{"name":"HATAKE KAKASHI","pack":["kakashi_base","kakashi_sharingan","kakashi_mangekyo"],"alternate":["kakashi_base","kakashi_war","kakashi_raikiri"],"branch_names":["SHARINGAN / KAMUI","RAIKIRI / WAR ARC"],"accent":"b4d8e5","hp":153.0,"attack":1.09,"speed":1.06,"skills":[
["Raikiri","Lightning Fang","Lightning Beast"],["Lightning Clone","Electric Chain","Clone Counter"],["Kusanagi Tanto","Twin Slash","Ghost Cut"],["Raiton: Gian","Thunder Shower","Chain Lightning"],["Doton Wall","Earth Spikes","Mud Prison"],["Ninken","Eight Dogs","Tracking Fang"],["Sharingan Copy","Copy Counter","Mirrored Jutsu"],["Suiton Dragon","Water Vortex","Lightning Water"]]},
"neji":{"name":"HYŪGA NEJI","pack":["neji_base","neji_byakugan","neji_master"],"alternate":["neji_base","neji_kaiten","neji_hakke"],"branch_names":["BYAKUGAN / JŪKEN","KAITEN / HAKKE"],"accent":"c0d6ee","hp":166.0,"attack":0.99,"speed":1.11,"skills":[
["Jūken","Chakra Point Lock","Tenketsu Burst"],["Hakke 64 Palms","128 Palms","Heavenly Rotation"],["Air Palm","Vacuum Fist","Double Palm"],["Hakke Kūshō","Piercing Current","Gale Palm"],["Kaiten","Grand Kaiten","Absolute Defense"],["Gentle Fist Clone","Phantom Palm","Hyūga Formation"],["Byakugan Focus","Vision Counter","Point Exposure"],["Hakke 8 Trigrams","Eight Gates Field","Hakke Domination"]]},
"gaara":{"name":"GAARA","pack":["gaara_base","gaara_armor","gaara_shukaku"],"alternate":["gaara_base","gaara_kazekage","gaara_sandstorm"],"branch_names":["SAND ARMOR / SHUKAKU","KAZEKAGE / SANDSTORM"],"accent":"ddaf78","hp":190.0,"attack":0.96,"speed":0.87,"skills":[
["Sabaku Kyū","Sand Coffin","Desert Burial"],["Sand Clones","Sand Legion","Sand Ambush"],["Sand Spear","Sand Lance","Piercing Dune"],["Sand Shuriken","Shrapnel Storm","Flying Sand"],["Desert Avalanche","Great Sand Tsunami","Quicksand Abyss"],["Sand Guardian","Sand Shield","Sand Dome"],["Sand Prison","Grasping Sand","Chakra Seal"],["Shukaku Wind","Wind Bullets","Desert Tempest"]]}
}
const UTILITIES={
"naruto":[["Kage Bunshin","Oiroke","Gamakichi Support","Bunshin Decoy"]],
"sasuke":[["Sharingan Slow","Substitution Lightning","Orochi Guard","Lightning Clone"]],
"rock_lee":[["Drunken Fist","Gate Guard","Lotus Counter","Iron Stance"]],
"kakashi":[["Kamui Warp","Ninken Guard","Copy Counter","Mud Decoy"]],
"neji":[["Kaiten","Byakugan Radar","Tenketsu Guard","Hakke Step"]],
"gaara":[["Sand Shield","Sand Decoy","Dune Heal","Sand Armor"]]
}
static func hero(id:String) -> Dictionary:return HEROES.get(id,{}).duplicate(true)
static func pack(id:String,branch:int,stage:int) -> String:
 var h:Dictionary=hero(id)
 if h.is_empty():return ""
 var packs:Array=h["pack"] if branch==0 else h["alternate"]
 return str(packs[clampi(stage,0,2)])
static func asset_ready(id:String,branch:int=0,stage:int=0) -> bool:
 var p=pack(id,branch,stage)
 return p!="" and FileAccess.file_exists("res://assets/mugen/%s/manifest.json"%p)
static func all_assets_ready(id:String) -> bool:
 for branch in range(2):
  for stage in range(3):
   if not asset_ready(id,branch,stage):return false
 return true
static func skills(id:String) -> Array:
 var h=hero(id)
 if h.is_empty():return []
 var rows:Array=[]
 for i in range(SLOT_IDS.size()):
  var v:Array=h.skills[i]
  rows.append({"id":SLOT_IDS[i],"hero_id":id,"name":v[0],"role":ROLES[i],"branches":[v[1],v[2]],"max_rank":3,"capstone_rank":2,"slot":i})
 return rows
static func title(id:String,family:String,branch:String="") -> String:
 if not id in HEROES:return ""
 var idx=SLOT_IDS.find(family)
 if idx<0:return ""
 var node:Array=HEROES[id].skills[idx]
 if branch=="left":return str(node[1])
 if branch=="right":return str(node[2])
 return str(node[0])
static func validate() -> Array:
 var faults:Array=[]
 for id in IDS:
  if not HEROES.has(id):faults.append("Missing hero "+id);continue
  var entry:Dictionary=HEROES[id]
  if entry.skills.size()!=8:faults.append("8 families missing "+id)
  for row in entry.skills:
   if row.size()!=3 or str(row[0])=="" or str(row[1])=="" or str(row[2])=="":
    faults.append("Malformed branch "+id)
  if entry.pack.size()!=3 or entry.alternate.size()!=3:faults.append("Forms missing "+id)
 return faults
