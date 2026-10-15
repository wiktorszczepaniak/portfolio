extends RefCounted
const ClassDescriptions=preload("res://scripts/core/class_jutsu_descriptions.gd")
const OFFENSIVE = ["rasengan", "naruto_rendan", "fuma_shuriken", "shuriken_barrage", "kunai_kibaku", "kuchiyose", "henge_feint", "gama_teppo"]
const UTILITY = ["kage_bunshin", "oiroke", "gamakichi_support", "bunshin_decoy"]
const DATA = {"rasengan": {"name": "RASENGAN", "short": "Rasengan", "desc": "Doskok i uderzenie chakry. II: odrzut. III: większy zasięg.", "cooldowns": [4.4, 5.2], "damage": 80, "startup": 0.24, "active": 0.16, "recovery": 0.32, "art": "rasengan", "evolutions": ["odama", "rasenshuriken"]}, "naruto_rendan": {"name": "NARUTO RENDAN", "short": "Rendan", "desc": "Seria ciosów klonów. II: dodatkowy cios. III: silny finał. Działa bez Rasengana.", "cooldowns": [5.6, 6.4], "damage": 27, "startup": 0.18, "active": 0.8, "recovery": 0.23, "art": "clone", "evolutions": ["nisen", "combo_rush"]}, "fuma_shuriken": {"name": "FŪMA SHURIKEN", "short": "Fūma", "desc": "Przebijające ostrze. II: powrót. III: szerszy tor.", "cooldowns": [3.6, 4.8], "damage": 58, "startup": 0.18, "active": 0.16, "recovery": 0.25, "art": "fuma", "evolutions": ["double_fuma", "blade_orbit"]}, "shuriken_barrage": {"name": "SHURIKEN BARRAGE", "short": "Shurikeny", "desc": "Salwa ostrzy. II: oznaczanie celu. III: większa salwa.", "cooldowns": [3, 3.6], "damage": 22, "startup": 0.12, "active": 0.3, "recovery": 0.2, "art": "shuriken", "evolutions": ["shuriken_rain", "shadow_shuriken"]}, "kunai_kibaku": {"name": "KUNAI + KIBAKU FUDA", "short": "Kibaku Fuda", "desc": "Notka wybuchowa. II: większy obszar. III: szybsza detonacja.", "cooldowns": [4.8, 5.4], "damage": 112, "startup": 0.2, "active": 0.15, "recovery": 0.22, "art": "note", "evolutions": ["chain_blast", "fragment_trap"]}, "kuchiyose": {"name": "KUCHIYOSE: ATAK", "short": "Kuchiyose", "desc": "Żaba ląduje na wrogu. II: druga fala. III: większy zasięg.", "cooldowns": [7, 8.5], "damage": 140, "startup": 0.52, "active": 0.22, "recovery": 0.32, "art": "frog", "evolutions": ["gamabunta", "gamakichi_assault"]}, "henge_feint": {"name": "HENGE: SHURIKEN FEINT", "short": "Henge Feint", "desc": "Shuriken zamienia się w klona za celem. II: kontra. III: wabik. Adaptacja.", "cooldowns": [4.5, 6], "damage": 100, "startup": 0.25, "active": 0.2, "recovery": 0.25, "art": "clone", "evolutions": ["double_feint", "clone_counter"]}, "gama_teppo": {"name": "FŪTON: GAMA TEPPŌ", "short": "Gama Teppō", "desc": "Żaba i fala wody/wiatru. II: podwójny strumień. III: odrzut.", "cooldowns": [5.8, 7.2], "damage": 28, "startup": 0.48, "active": 0.75, "recovery": 0.3, "art": "water", "evolutions": ["suiton_wave", "futon_wave"]}, "kage_bunshin": {"name": "KAGE BUNSHIN", "short": "Kage Bunshin", "desc": "Klony wspierają ataki; synergia z Rasenganem i Rendan.", "cooldowns": [18, 19], "art": "clone"}, "oiroke": {"name": "OIROKE NO JUTSU", "short": "Oiroke No Jutsu", "desc": "Przemiana i para. Rani wrogów i przerywa podatne ataki bossa.", "cooldowns": [17, 18], "art": "oiroke"}, "gamakichi_support": {"name": "GAMAKICHI: OCHRONA", "short": "Gamakichi: Ochrona", "desc": "Defensywna żaba pochłania pociski i zmniejsza obrażenia.", "cooldowns": [19, 20], "art": "frog"}, "bunshin_decoy": {"name": "BUNSHIN DECOY", "short": "Bunshin Decoy", "desc": "Wabik odciąga wrogów i celowanie bossa; okno kontry.", "cooldowns": [14, 16], "art": "clone"}}
const EVOLUTIONS = {"odama": ["ŌDAMA RASENGAN", "Większa eksplozja i druga fala."], "rasenshuriken": ["FŪTON: RASENSHURIKEN", "Rzut wirującą chakrą zamiast doskoku."], "nisen": ["NISEN RENDAN", "Dwa dodatkowe ciosy i szerszy finisher."], "combo_rush": ["BUNSHIN COMBO RUSH", "Szybsze ciosy; klony śledzą poruszający się cel."], "double_fuma": ["PODWÓJNY FŪMA", "Dwa oddzielne tory i powrót."], "blade_orbit": ["WIRUJĄCE OSTRZA", "Ostrze zatrzymuje się i tnie wielokrotnie."], "shuriken_rain": ["DESZCZ SHURIKENÓW", "Ostrza spadają nad celem."], "shadow_shuriken": ["SHURIKEN KAGE BUNSHIN", "Klon powtarza salwę."], "chain_blast": ["ŁAŃCUCH EKSPLOZJI", "Trzy kolejne detonacje."], "fragment_trap": ["PUŁAPKA ODŁAMKOWA", "Wybuch wyrzuca osiem odłamków."], "gamabunta": ["GAMABUNTA", "Duża żaba i szeroka fala lądowania."], "gamakichi_assault": ["GAMAKICHI ASSAULT", "Trzy lądowania w stronę celu."], "double_feint": ["PODWÓJNY ZWÓD", "Dwie przemiany z różnych stron."], "clone_counter": ["KONTRATAK Z KLONEM", "Po zwodzie zostaje wabik i okno kontry."], "suiton_wave": ["SUITON: SILNA FALA", "Dłuższa fala odpycha i spowalnia."], "futon_wave": ["FŪTON: TNĄCA FALA", "Szybka, przebijająca fala wiatru."]}
const PASSIVES = {"speed": ["SHUNSHIN", "Ruch i częstsze Kawarimi.", 5], "magnet": ["WYCZUCIE CHAKRY", "Przyciąganie XP; regen chakry w duelu.", 5], "max_hp": ["WITALNOŚĆ", "+18 maks. HP i leczenie.", 5], "regeneration": ["MEDYTACJA", "Leczenie po pokonaniu wrogów; regen w duelu.", 3], "chakra_flow": ["PRZEPŁYW CHAKRY", "Jutsu odnawiają się o 6% szybciej.", 4], "crit": ["OSTRZE WIATRU", "+7% obrażeń jutsu.", 4], "survivor_instinct": ["INSTYNKT SHINOBI", "O 9% mniej obrażeń.", 3], "kunai_twin": ["PODWÓJNE KUNAI", "Więcej kunai; mocniejsze kombo F.", 3], "kunai_rapid": ["SZYBKIE RZUTY", "Szybsze kunai i kombo.", 3], "kunai_pierce": ["PRZEBIJAJĄCE KUNAI", "Przebijanie; kombo osłabia gardę.", 3]}
const CLASS_NAMES = {
 "sasuke": {
  "rasengan": "CHIDORI",
  "naruto_rendan": "SHISHI RENDAN",
  "fuma_shuriken": "SHURIKEN UCHIHA",
  "shuriken_barrage": "KATON: HŌSENKA",
  "kunai_kibaku": "KATON: GŌKAKYŪ",
  "kuchiyose": "SUMMON: AODA",
  "henge_feint": "SHARINGAN FEINT",
  "gama_teppo": "KATON: GŌRYŪKA",
  "kage_bunshin": "CHIDORI NAGASHI",
  "oiroke": "GENJUTSU",
  "gamakichi_support": "SUSANOO: OSŁONA",
  "bunshin_decoy": "KAWARIMI"
 },
 "kakashi": {
  "rasengan": "RAIKIRI",
  "naruto_rendan": "RAIJŪ TSUIGA",
  "fuma_shuriken": "KUNAI: ANBU",
  "shuriken_barrage": "RAITON: BŁYSK",
  "kunai_kibaku": "DOTON: ŚCIANA",
  "kuchiyose": "NINKEN: PAKKUN",
  "henge_feint": "KAMUI FEINT",
  "gama_teppo": "SUITON: SUIRYŪDAN",
  "kage_bunshin": "SHADOW CLONE",
  "oiroke": "KAMUI ZASŁONA",
  "gamakichi_support": "PIES OBRONNY",
  "bunshin_decoy": "MGLISTY KOPIA"
 },
 "rock_lee": {
  "rasengan": "OMOTE RENGE",
  "naruto_rendan": "KONOHA SENPŪ",
  "fuma_shuriken": "KONOHA REPPŪ",
  "shuriken_barrage": "KONOHA DAI SENPŪ",
  "kunai_kibaku": "KONOHA SHŌFŪ",
  "kuchiyose": "DYNAMIC ENTRY",
  "henge_feint": "DRUNKEN FEINT",
  "gama_teppo": "URA RENGE",
  "kage_bunshin": "KONOHA BUNSHIN",
  "oiroke": "BRAMY: FALA",
  "gamakichi_support": "TRENING GAI",
  "bunshin_decoy": "UNIK MŁODOŚCI"
 },
 "neji": {
  "rasengan": "HAKKE KŪSHŌ",
  "naruto_rendan": "HAKKE 64 PALMS",
  "fuma_shuriken": "JŪKEN: TENKETSU",
  "shuriken_barrage": "JUUKEN: SERIA",
  "kunai_kibaku": "HAKKE KAITEN",
  "kuchiyose": "HAKKE KŪHEKISHŌ",
  "henge_feint": "BYAKUGAN COUNTER",
  "gama_teppo": "HAKKE: WIR",
  "kage_bunshin": "BIAŁE OKO",
  "oiroke": "KAITEN: KULA",
  "gamakichi_support": "TENKETSU OSŁONA",
  "bunshin_decoy": "WABIK HYŪGA"
 },
 "gaara": {
  "rasengan": "SABAKU KYŪ",
  "naruto_rendan": "SABAKU SŌSŌ",
  "fuma_shuriken": "PIASKOWE OSTRZA",
  "shuriken_barrage": "DESZCZ IGIEŁ",
  "kunai_kibaku": "BURZA PIASKOWA",
  "kuchiyose": "SHUKAKU: ATAK",
  "henge_feint": "PIASKOWY SOBOWTÓR",
  "gama_teppo": "TSUNAMI PIASKU",
  "kage_bunshin": "PIASKOWY KLON",
  "oiroke": "PIASKOWA PUŁAPKA",
  "gamakichi_support": "TARCZA KAZEKAGE",
  "bunshin_decoy": "PIASKOWY WABIK"
 }
}
static func hero_jutsu_name(id:String) -> String:
 var game_loop:MainLoop=Engine.get_main_loop()
 if game_loop is SceneTree:
  var alpha=(game_loop as SceneTree).root.get_node_or_null("AlphaProgress")
  if alpha!=null and CLASS_NAMES.has(alpha.selected):return str(CLASS_NAMES[alpha.selected].get(id,DATA.get(id,{}).get("name",id)))
 return str(DATA.get(id,{}).get("name",id))

static func cards() -> Dictionary:
 var out={}
 for id in DATA:
  var d=DATA[id].duplicate(true)
  d["name"]=hero_jutsu_name(str(id))
  if Engine.get_main_loop() is SceneTree:
   var alpha=(Engine.get_main_loop() as SceneTree).root.get_node_or_null("AlphaProgress")
   if alpha!=null and alpha.selected!="naruto":d["desc"]=str(ClassDescriptions.DATA.get(str(alpha.selected),{}).get(id,d["desc"]))
  d.merge({"tier":1 if id in OFFENSIVE else 2,"max":3,"kind":"offensive" if id in OFFENSIVE else "utility"});out[id]=d
  for e in d.get("evolutions",[]):out[id+":"+e]={"name":EVOLUTIONS[e][0],"desc":EVOLUTIONS[e][1],"tier":3,"max":1,"kind":"evolution","art":d.art}
 for id in PASSIVES:out[id]={"name":PASSIVES[id][0],"desc":PASSIVES[id][1],"tier":0,"max":PASSIVES[id][2],"kind":"passive"}
 out["recovery"]={"name":"ZAPAS RAMENU","desc":"Odzyskaj 40 HP.","tier":0,"max":99,"kind":"recovery"}
 return out
static func title(id) -> String:
 var name=hero_jutsu_name(str(id))
 return "PUSTY SLOT" if name==str(id) else name.substr(0,19)+"…" if name.length()>20 else name
static func cost(id:String) -> float:return float({"rasengan":22,"naruto_rendan":23,"fuma_shuriken":16,"shuriken_barrage":12,"kunai_kibaku":18,"kuchiyose":28,"henge_feint":20,"gama_teppo":26}.get(id,0))
