extends Node
## 6 playable MUGEN heroes, 36 branching trees, 252 unique named nodes.
## Each tree splits after its root, reconverges at signature and apex.
const HEROES = {
 "naruto": {
  "name": "UZUMAKI NARUTO",
  "role": "WIR CHAKRY",
  "pack": "naruto_base",
  "color": "eea64f",
  "element": "wind",
  "trees": [
   [
    "RASENGAN",
    [
     "SPIRALA CHAKRY",
     "GĘSTOŚĆ CHAKRY",
     "PRECYZYJNY RASENGAN",
     "ŌDAMA IMPACT",
     "WIR NISZCZĄCY",
     "RASENSHURIKEN",
     "KURAMA: ZŁOTY WIR"
    ]
   ],
   [
    "KAGE BUNSHIN",
    [
     "CIENIE KONOHA",
     "DWA KLONY",
     "SPLOT CHAKRY",
     "UZUMAKI RENDAN",
     "TAJŪ BUNSHIN",
     "ARMIA KLONÓW",
     "LEGION DZIEWIĘCIOOGONIASTEGO"
    ]
   ],
   [
    "FŪTON",
    [
     "OSTRZE WIATRU",
     "SZYBKIE CIĘCIE",
     "TORNADO OCHRONNE",
     "BURZA SHURIKENÓW",
     "OSTRZE POWROTNE",
     "CYKLON SHINOBI",
     "SZEŚĆ OSTRZY WIRU"
    ]
   ],
   [
    "SENNIN",
    [
     "ZBIERANIE NATURY",
     "ŻABIA CZUJNOŚĆ",
     "FROG KATA",
     "ŻABIA SZKOŁA",
     "SENNIN BARRIER",
     "TRYB MĘDRCA",
     "PERFEKCYJNA RÓWNOWAGA"
    ]
   ],
   [
    "KYŪBI",
    [
     "PIERWSZA ISKRA",
     "CZAKRA OGONA",
     "KRWAWA AURA",
     "OGNISTY KŁY",
     "PŁASZCZ KURAMY",
     "BIJŪ PULSE",
     "ZŁOTY LIS"
    ]
   ],
   [
    "SHINOBI",
    [
     "KAWARIMI",
     "SPRINT KONOHA",
     "WYCZUCIE WROGA",
     "ODDECH BOHATERA",
     "ŻELAZNA WOLA",
     "DROGA HOKAGE",
     "NIEWZRUSZONY HOKAGE"
    ]
   ]
  ]
 },
 "sasuke": {
  "name": "UCHIHA SASUKE",
  "role": "OGIEŃ I BŁYSKAWICA",
  "pack": "sasuke",
  "color": "9984db",
  "element": "fire",
  "trees": [
   [
    "CHIDORI",
    [
     "ISKRA RAIKIRI",
     "BŁYSKAWICZNY PCHNIĘCIE",
     "PORAŻENIE",
     "CHIDORI NAGASHI",
     "PRZEBICIE OBRONY",
     "CHIDORI SENBON",
     "KIRIN"
    ]
   ],
   [
    "KATON",
    [
     "KATON: GŌKAKYŪ",
     "OGNISTA ŚCIEŻKA",
     "OGNISTE PUŁAPKI",
     "HŌSENKA",
     "SŁUP OGNIA",
     "GŌRYŪKA",
     "AMATERASU"
    ]
   ],
   [
    "SHARINGAN",
    [
     "PRZEBUDZENIE OKA",
     "WIDZENIE RUCHU",
     "ILUZJA PIERWSZEGO STOPNIA",
     "PRZEWIDYWANIE",
     "GENJUTSU: ZASŁONA",
     "MANGEKYŌ",
     "TSUKUYOMI"
    ]
   ],
   [
    "KENJUTSU",
    [
     "OSTRZE KUSANAGI",
     "BŁYSK OSTRZA",
     "PODWÓJNE CIĘCIE",
     "CHIDORI KATANA",
     "TANIEC MIECZA",
     "SZYBKA EGZEKUCJA",
     "KATANA BURZY"
    ]
   ],
   [
    "KLAN UCHIHA",
    [
     "DUMA KLANU",
     "WĘGIEL PAMIĘCI",
     "SZÓSTY ZMYSŁ",
     "CZARNE PŁOMIENIE",
     "ODPORNOŚĆ",
     "SUSANOO",
     "DOSKONAŁY SUSANOO"
    ]
   ],
   [
    "PRZEKLĘTA PIECZĘĆ",
    [
     "ZNAMIĘ OROCHIMARU",
     "WYBUCH SIŁY",
     "DODATKOWA SZYBKOŚĆ",
     "DRUGI POZIOM",
     "SKRZYDŁA CIENIA",
     "CZARNA CZAKRA",
     "ZNAK WYBRAŃCA"
    ]
   ]
  ]
 },
 "kakashi": {
  "name": "HATAKE KAKASHI",
  "role": "TAKTYKA I RAIKIRI",
  "pack": "kakashi",
  "color": "8ed3e9",
  "element": "lightning",
  "trees": [
   [
    "RAIKIRI",
    [
     "RAIKIRI",
     "PRZEJŚCIE BŁYSKAWICY",
     "SKRÓT CZASU",
     "TRZY CIOŚY",
     "PIORUN W SERCU",
     "RAIDEN",
     "SZEŚĆ BŁYSKAWIC"
    ]
   ],
   [
    "SHARINGAN",
    [
     "SKOPIOWANA TECHNIKA",
     "PATRZ UWAŻNIE",
     "OCZY ANBU",
     "ZAWIESZENIE CZASU",
     "KAMUFLAŻ",
     "MANGEKYŌ SHARINGAN",
     "KAMUI"
    ]
   ],
   [
    "NINKEN",
    [
     "PAKKUN",
     "PIES TROPICIEL",
     "OSACZENIE",
     "NINJA HOUNDS",
     "SZARPANIE",
     "DZWON PSÓW",
     "OŚMIU TROPICIELI"
    ]
   ],
   [
    "SUITON",
    [
     "WODNY KLON",
     "WODNA ŚCIANA",
     "SZPRYCA",
     "WODNY SMOK",
     "SUITON WIR",
     "HYDRO PRZEBICIE",
     "SUIRYŪDAN"
    ]
   ],
   [
    "DOTON",
    [
     "BŁOTNA ŚCIANA",
     "PUŁAPKA ZIEMNA",
     "CIĘŻKA GLEBA",
     "DOTON HENGE",
     "ZIEMNY WIĘZIEŃ",
     "ROZSTĄPIENIE ZIEMI",
     "DRŻENIE POLA"
    ]
   ],
   [
    "ANBU",
    [
     "CICHA MASKA",
     "SZYBKI ODWROT",
     "WYOSTRZENIE ZMYSŁÓW",
     "NIEWIDZIALNY KROK",
     "KRYTYCZNE CIĘCIE",
     "BIAŁY KIEŁ",
     "BOHATER KONOHA"
    ]
   ]
  ]
 },
 "rock_lee": {
  "name": "ROCK LEE",
  "role": "TAIJUTSU I BRAMY",
  "pack": "rock_lee",
  "color": "88c77c",
  "element": "impact",
  "trees": [
   [
    "TAIJUTSU",
    [
     "SZYBKA PIĘŚĆ",
     "SERIA KOPNIĘĆ",
     "LIŚCIOWY WIR",
     "KONOHA SENPŪ",
     "ODRZUT",
     "KONOHA DAI SENPŪ",
     "KWIAT MŁODOŚCI"
    ]
   ],
   [
    "OMOTE RENGE",
    [
     "LOTOS",
     "WYSKOK",
     "DOSKOK",
     "ZWROTNA RENGA",
     "DRUZGOCĄCY UPADŁEK",
     "OMOTE RENGE",
     "URA RENGE"
    ]
   ],
   [
    "BRAMY",
    [
     "BRAMA OTWARCIA",
     "BRAMA ODPOCZYNKU",
     "BRAMA ŻYCIA",
     "BRAMA BÓLU",
     "BRAMA ZAMKNIĘCIA",
     "SZÓSTA BRAMA",
     "SEKIZŌ"
    ]
   ],
   [
    "SZYBKOŚĆ",
    [
     "TRENING GAI",
     "LEKKIE OBCIĄŻNIKI",
     "SHUNSHIN",
     "ZDJĘCIE OBCIĄŻEŃ",
     "CIOS PRZED OCZAMI",
     "LOTOS SZYBKOŚCI",
     "BŁYSK LEE"
    ]
   ],
   [
    "OBRONA",
    [
     "UNIKI MISTRZA",
     "WYTRZYMAŁOŚĆ",
     "TWARDY BLOK",
     "ODPORNOŚĆ",
     "KONTROWE CIĘCIE",
     "ŻELAZNE CIAŁO",
     "WIECZNY MŁODY"
    ]
   ],
   [
    "DRUNKEN FIST",
    [
     "NIERÓWNY KROK",
     "KONTROLA RYTMU",
     "PIJANA PIĘŚĆ",
     "WĄŻ I TYGRYS",
     "PIJANY UNIK",
     "ZAKAZANA TECHNIKA",
     "NIEPRZEWIDYWALNY LOTOS"
    ]
   ]
  ]
 },
 "neji": {
  "name": "HYŪGA NEJI",
  "role": "BYAKUGAN I KAITEN",
  "pack": "neji",
  "color": "d9d0db",
  "element": "wind",
  "trees": [
   [
    "BYAKUGAN",
    [
     "BIAŁE OKO",
     "PUNKTY CHAKRY",
     "PRZEWIDYWANIE",
     "WIDZENIE 360°",
     "TENKETSU",
     "DOSKONAŁY BYAKUGAN",
     "WZROK LOSU"
    ]
   ],
   [
    "HAKKE",
    [
     "DWA UDERZENIA",
     "CZTERY UDERZENIA",
     "OSIEM UDERZEŃ",
     "SZESNAŚCIE UDERZEŃ",
     "32 DŁONIE",
     "64 DŁONIE",
     "128 DŁONI"
    ]
   ],
   [
    "KAITEN",
    [
     "ZWROT CHAKRY",
     "OBRÓT",
     "OBRONA OKRĘŻNA",
     "ODBICIE POCISKÓW",
     "WIR NIEBIOS",
     "HAKKE KAITEN",
     "ABSOLUTNY KAITEN"
    ]
   ],
   [
    "JUUKEN",
    [
     "MIĘKKA PIĘŚĆ",
     "UDERZENIE W PUNKT",
     "SKUPIENIE",
     "BLOKADA CHAKRY",
     "WYŁĄCZENIE TECHNIKI",
     "HAKKE KŪSHŌ",
     "DWA LWIĘ PAZURY"
    ]
   ],
   [
    "PRĘDKOŚĆ",
    [
     "ODDECH HYŪGA",
     "SZYBKI KROK",
     "ŚLAD CHAKRY",
     "BŁYSK DŁONI",
     "OKNO KONTRY",
     "NIEWIDOCZNY RUCH",
     "PERFEKCYJNY RUCH"
    ]
   ],
   [
    "LOS HYŪGA",
    [
     "ZNAK LOSU",
     "PRZEŁAMANIE",
     "BRAMA WOLNOŚCI",
     "PRZETRWANIE",
     "OSŁONA RODU",
     "NIEZŁOMNY",
     "WOLNOŚĆ HYŪGA"
    ]
   ]
  ]
 },
 "gaara": {
  "name": "GAARA",
  "role": "PIASEK I OCHRONA",
  "pack": "gaara",
  "color": "d8a36d",
  "element": "sand",
  "trees": [
   [
    "SABAKU",
    [
     "PIASKOWA KULA",
     "PIASKOWE RĘCE",
     "ZŁAPANIE",
     "PIASKOWA TRUMNA",
     "SABAKU KYŪ",
     "SABAKU SŌSŌ",
     "PUSTYNIA BEZ KRESU"
    ]
   ],
   [
    "TARCZA",
    [
     "AUTOMATYCZNY PIASEK",
     "TWARDY PIACH",
     "ZBROJA PIASKU",
     "ŚCIANA",
     "OSŁONA BLISKICH",
     "ABSOLUTNA OBRONA",
     "ŻELAZNA OCHRONA"
    ]
   ],
   [
    "SHUKAKU",
    [
     "SZEPT DEMONA",
     "KŁY PIASKU",
     "BESTIA W PIASKU",
     "NOCNY WIATR",
     "CZAKRA BIJŪ",
     "RAMIĘ SHUKAKU",
     "SZALEŃSTWO SHUKAKU"
    ]
   ],
   [
    "PUSTYNIA",
    [
     "FALA PIASKU",
     "PŁYNĄCY PIACH",
     "SZYBKI ZASYP",
     "BURZA PIASKOWA",
     "PIASKOWA KOPUŁA",
     "PIASKOWE TSUNAMI",
     "ZMIANA KRAJOBRAZU"
    ]
   ],
   [
    "PIASKOWE IGŁY",
    [
     "ZIARNO",
     "PODWÓJNY POCISK",
     "OSTRY PIASEK",
     "TYSIĄC IGIEŁ",
     "ZATRZYMANIE",
     "SABAKU SHIGURE",
     "DESZCZ CIĘŻKIEGO PIASKU"
    ]
   ],
   [
    "KAZEKAGE",
    [
     "SPOKÓJ",
     "WOLNA WOLA",
     "OBRONA WIOSKI",
     "CZUJNE OKO",
     "NIEZŁOMNY",
     "PIĄTY KAZEKAGE",
     "STRAŻNIK WIOSKI"
    ]
   ]
  ]
 }
}
const AWAKENINGS={
 "sasuke":{"kyubi":["CHIDORI DRIVE","PRZEKLĘTA PIECZĘĆ"],"sage":["SHARINGAN","MANGEKYŌ SHARINGAN"]},
 "kakashi":{"kyubi":["RAIKIRI CHARGE","RAIDEN STORM"],"sage":["SHARINGAN FOCUS","KAMUI MASTERY"]},
 "rock_lee":{"kyubi":["TRZECIA BRAMA","SZÓSTA BRAMA"],"sage":["DRUNKEN FIST","LOTUS DEFENSE"]},
 "neji":{"kyubi":["HAKKE KOMBO","128 DŁONI"],"sage":["BYAKUGAN","KAITEN MASTERY"]},
 "gaara":{"kyubi":["AURA SHUKAKU","RAMIĘ SHUKAKU"],"sage":["ZBROJA PIASKU","STRAŻNIK KAZEKAGE"]}
}
const IDS = ["naruto", "sasuke", "kakashi", "rock_lee", "neji", "gaara"]
const FOCI = ["damage", "tempo", "projectile", "mobility", "defense", "ultimate"]
const NODE_EFFECTS = ["damage", "tempo", "guard", "projectile", "mobility", "signature", "apex"]
var selected: String = "naruto"
var owned: Dictionary = {}
var points: int = 4
var tree_open: bool = false
var tree_tab: int = 0
var level_awarded: int = 1
var proc_sequence: int = 0

func hero() -> Dictionary:
 return HEROES.get(selected, HEROES["naruto"])

func choose(id: String) -> bool:
 if not HEROES.has(id): return false
 selected = id
 return true

func reset_run() -> void:
 owned.clear()
 points = 4
 tree_open = false
 tree_tab = 0
 level_awarded = 1
 proc_sequence = 0

func award_for_level(new_level: int) -> void:
 if new_level <= level_awarded: return
 var levels_gained := mini(100, new_level - level_awarded)
 points += levels_gained * 2
 level_awarded = new_level

func key(tree_index: int, node_index: int) -> String:
 return "%s.%d.%d" % [selected, tree_index, node_index]

func node_name(tree_index: int, node_index: int) -> String:
 return str(hero()["trees"][tree_index][1][node_index])

func tree_name(index: int) -> String:
 return str(hero()["trees"][index][0])

func invested(tree_index: int, node_index: int) -> bool:
 return owned.has(key(tree_index, node_index))

func node_cost(index: int) -> int:
 return 3 if index == 6 else 2 if index == 5 else 1

func prerequisite(tree_index: int, node_index: int) -> bool:
 match node_index:
  0:return true
  1,2:return invested(tree_index,0)
  3:return invested(tree_index,1)
  4:return invested(tree_index,2)
  5:return invested(tree_index,3) or invested(tree_index,4)
  6:return invested(tree_index,5)
 return false

func can_buy(tree_index: int, node_index: int) -> bool:
 if tree_index < 0 or tree_index >= 6 or node_index < 0 or node_index >= 7:return false
 if invested(tree_index,node_index) or points < node_cost(node_index):return false
 # The left and right evolution routes are true choices, not cosmetic forks.
 if node_index==1 and invested(tree_index,2):return false
 if node_index==2 and invested(tree_index,1):return false
 return prerequisite(tree_index,node_index)

func buy(tree_index: int, node_index: int) -> bool:
 if not can_buy(tree_index,node_index):return false
 owned[key(tree_index,node_index)] = true
 points -= node_cost(node_index)
 return true

func count_effect(effect: String) -> int:
 var count := 0
 for t in range(6):
  for n in range(7):
   if invested(t,n) and (NODE_EFFECTS[n] == effect or n == 6 and effect == "damage"):
    count += 1
 return count

func count_focus(tree_index: int) -> int:
 var amount := 0
 for n in range(7):
  if invested(tree_index,n):amount+=1
 return amount

func damage_multiplier() -> float:
 return 1.0 + 0.065 * count_effect("damage") + 0.10 * count_effect("signature") + 0.15 * count_effect("apex")

func attack_interval_multiplier() -> float:
 return maxf(0.50, 1.0 - 0.035 * count_effect("tempo") - 0.025 * count_effect("mobility"))

func move_multiplier() -> float:
 return 1.0 + 0.037 * count_effect("mobility") + 0.018 * count_effect("tempo")

func guard_multiplier() -> float:
 return maxf(0.55,1.0 - 0.048 * count_effect("guard"))

func additional_projectiles() -> int:
 return mini(4,int(count_effect("projectile")/2))

func special_unlocked(tree_index: int) -> bool:
 return invested(tree_index,5)

func apex_unlocked(tree_index: int) -> bool:
 return invested(tree_index,6)

func proc_ready() -> bool:
 proc_sequence += 1
 var total := 0
 for i in range(6):
  if special_unlocked(i):total+=1
 return total > 0 and proc_sequence % maxi(3,8-total) == 0

func current_signature() -> int:
 var active: Array[int] = []
 for i in range(6):
  if special_unlocked(i):active.append(i)
 if active.is_empty():return -1
 return active[posmod(proc_sequence, active.size())]

func snapshot() -> Dictionary:
 return {"selected":selected,"owned":owned.duplicate(true),"points":points,"level_awarded":level_awarded}

func restore(data: Dictionary) -> bool:
 var id: String = str(data.get("selected","naruto"))
 if not HEROES.has(id) or not data.get("owned",{}) is Dictionary:return false
 var saved:Dictionary=data.get("owned",{})
 var spent:=0
 for key_saved in saved:
  var parts = str(key_saved).split(".")
  if parts.size()!=3 or parts[0]!=id or not str(parts[1]).is_valid_int() or not str(parts[2]).is_valid_int():return false
  var t=int(parts[1]);var n=int(parts[2])
  if t<0 or t>=6 or n<0 or n>=7 or not bool(saved[key_saved]):return false
  # Reject impossible talent graphs and mutually exclusive branches on load.
  if n==1 and saved.has("%s.%d.2"%[id,t]):return false
  if n==2 and saved.has("%s.%d.1"%[id,t]):return false
  if n>0:
   var requires:Array=[]
   match n:
    1,2:requires=[0]
    3:requires=[1]
    4:requires=[2]
    5:requires=[3,4]
    6:requires=[5]
   var path_unlocked:=false
   for parent in requires:
    if saved.has("%s.%d.%d"%[id,t,parent]):path_unlocked=true
   if not path_unlocked:return false
  spent+=node_cost(n)
 var level=maxi(1,int(data.get("level_awarded",1)))
 var earned=4+2*(level-1)
 if spent>earned or int(data.get("points",0))<0 or spent+int(data.get("points",0))>earned:return false
 selected=id;owned=saved.duplicate(true);points=int(data.get("points",0));level_awarded=level
 return true

func awakening_title(branch:String,stage:int)->String:
 if selected=="naruto":
  if stage==0:return "NARUTO"
  if branch=="kyubi":return "KYŪBI CLOAK" if stage==1 else "KURAMA CHAKRA MODE"
  return "SAGE MODE" if stage==1 else "SENNIN MASTERY"
 var awaken:Dictionary=AWAKENINGS.get(selected,{})
 var levels:Array=awaken.get(branch,[])
 if stage==0 or levels.is_empty():return str(hero()["name"])
 return str(levels[clampi(stage-1,0,levels.size()-1)])
