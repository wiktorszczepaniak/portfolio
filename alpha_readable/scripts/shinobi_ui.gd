extends Control
const NinjaTheme=preload("res://scripts/ninja_theme.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
## Resolution-independent parchment UI. All text stays native and readable.
const INK := Color("141d2a")
const PAPER := Color("f1dfb7")
const CREAM := Color("fff2d3")
const MUTED := Color("aab6ae")
const RED := Color("ba4c32")
const GOLD := Color("efac59")
const TIERS := [Color("65715a"),Color("277d8a"),Color("825884"),Color("aa741e")]
const TIER_NAMES := ["ZWYKŁY", "RZADKI", "EPICKI", "LEGENDARNY"]
var g
var body: FontFile
var title: FontFile
var mono: FontFile
var hero
var icons: Dictionary = {}
var age := 0.0
var reveal := 0.0
var was_picking := false
var hover_card := -1
var selected_focus := -1
var victory := false
var from_scroll := false

func _ready() -> void:
    size = Vector2(1280,720)
    mouse_filter = Control.MOUSE_FILTER_STOP
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    body = _font("body")
    title = _font("ninja")
    mono = _font("mono")
    hero = load("res://scripts/mugen_actor.gd").new()
    hero.pack_name = str(g.alpha.hero()["pack"])
    hero.position = Vector2(957,523)
    hero.scale = Vector2.ONE * 4.0
    add_child(hero)
    for name in ["naruto_base", "naruto_kyubi", "naruto_sage", "naruto_sennin", "naruto_kcm", "sasuke", "kakashi", "rock_lee", "neji", "gaara"]:
        var m = JSON.parse_string(FileAccess.get_file_as_string("res://assets/mugen/%s/manifest.json" % name))
        var key: String = m["actions"]["0"][0]["key"]
        icons[name] = g._read_png("res://assets/mugen/%s/%s" % [name,m["sprites"][key]["file"]])
        # Source-matched MUGEN attack poses for class scrolls; genuine skill-specific
        # elemental atlases remain P4 (tracked as not yet implemented).
        for action_id in ["200","210","220"]:
            if not m["actions"].has(action_id) or m["actions"][action_id].is_empty():continue
            var attack_key:String=str(m["actions"][action_id][0]["key"])
            var frame_info:Dictionary=m["sprites"].get(attack_key,{})
            if frame_info.has("file"):
                icons[name+":action:"+action_id]=g._read_png("res://assets/mugen/%s/%s"%[name,frame_info["file"]])
    icons["kunai"] = g.item_art.get("kunai")
    icons["rasengan"] = g.rasengan_frames[0] if not g.rasengan_frames.is_empty() else null
    icons["rasenshuriken"] = g.shuriken_frames[0] if not g.shuriken_frames.is_empty() else null
    icons["fuma_shuriken"] = g.item_art.get("shuriken",null)
    icons["fuma_boomerang"] = icons["fuma_shuriken"]
    icons["oiroke"] = g.oiroke_figure
    icons["naruto_rendan"] = g.barrage_frames[0] if not g.barrage_frames.is_empty() else icons["naruto_base"]
    icons["melee_rasengan"] = g.source_rasengan_frames[0] if not g.source_rasengan_frames.is_empty() else icons["rasengan"]
    icons["melee_combo"] = icons["melee_rasengan"]
    var art=load("res://scripts/combat/combat_art.gd")
    for id in g.JUTSU:
        if g.JUTSU[id].has("art"):
            icons[id]=icons["naruto_base"] if g.JUTSU[id].art=="clone" else art.frame(g.JUTSU[id].art,0)


func _font(name: String) -> FontFile:
    var f := FontFile.new()
    f.data = FileAccess.get_file_as_bytes("res://assets/fonts/%s.ttf" % name)
    return f

func _process(dt: float) -> void:
    age += dt
    hero.visible = not g.playing
    if hero.visible: hero.tick(dt)
    if g.picking and not was_picking:
        reveal = 0.0
        selected_focus = -1
    was_picking = g.picking
    reveal += dt
    hover_card = -1
    if g.picking:
        for i in range(g.selected_cards.size()):
            if _card_rect(i).has_point(get_local_mouse_position()): hover_card = i
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _over_button() else Control.CURSOR_ARROW
    queue_redraw()

func _card_rect(i: int) -> Rect2:
    return Rect2(14+i*314,150,304,450) if g.selected_cards.size()==4 else Rect2(136+i*352,150,304,450)

func _hero_rect(i:int) -> Rect2:
    return Rect2(686+(i%3)*194,495+(i/3)*72,186,64)

func _gacha_rect(i:int,count:int) -> Rect2:
    var cx:float=640.0+(float(i)-float(count-1)*0.5)*337.0
    return Rect2(cx-151.0,358.0,302.0,189.0)

func _over_button() -> bool:
    var p := get_local_mouse_position()
    if g.gacha_active:
        if not g.gacha_revealed:return false
        for i in range(g.gacha_rewards.size()):
            if _gacha_rect(i,g.gacha_rewards.size()).has_point(p):return true
        return false
    if g.picking: return hover_card >= 0
    if not g.playing:
        for i in range(6):
            if _hero_rect(i).has_point(p):return true
        return Rect2(82,463,390,62).has_point(p) or Rect2(82,551,470,86).has_point(p) or Rect2(82,415,470,38).has_point(p)
    if g.finished: return Rect2(467,551,346,56).has_point(p)
    if g.paused: return Rect2(467,400,346,56).has_point(p) or Rect2(467,476,346,42).has_point(p) or Rect2(467,531,346,48).has_point(p)
    return Rect2(1090,647,160,44).has_point(p)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var p: Vector2 = event.position
        if g.form_choice:
            for i in range(2):
                if Rect2(180+i*480,225,440,350).has_point(p):g._choose_form(i)
            accept_event();return
        if g.gacha_active:
            if g.gacha_revealed:
                for i in range(g.gacha_rewards.size()):
                    if _gacha_rect(i,g.gacha_rewards.size()).has_point(p):
                        g._choose_chest_reward(i)
                        break
            accept_event()
            return
        if g.picking:
            for i in range(g.selected_cards.size()):
                if _card_rect(i).has_point(p):
                    g._choose_card(i)
                    accept_event()
                    return
        elif not g.playing:
            for i in range(6):
                if _hero_rect(i).has_point(p):
                    g.choose_character(str(g.alpha.IDS[i]))
                    accept_event();return
            if Rect2(82,415,220,38).has_point(p):g.select_map("desert")
            elif Rect2(318,415,232,38).has_point(p):g.select_map("forest")
            elif Rect2(82,463,390,62).has_point(p): g._start()
            elif Rect2(82,551,220,36).has_point(p): g._toggle_fx()
            elif Rect2(320,551,230,36).has_point(p): g._toggle_godmode()
            elif Rect2(82,601,220,36).has_point(p): _sound()
        elif g.finished:
            if Rect2(467,551,346,56).has_point(p): g._start()
        elif g.paused:
            if Rect2(467,400,346,56).has_point(p): g.paused = false
            elif Rect2(467,476,346,42).has_point(p): _sound()
            elif Rect2(467,531,346,48).has_point(p): g.return_to_menu()
        elif Rect2(1090,647,160,44).has_point(p): g.speed_index = (g.speed_index+1)%g.speeds.size()
        accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:return
    if g.gacha_active and g.gacha_revealed:
        if event.keycode in [KEY_1,KEY_2,KEY_3]:
            g._choose_chest_reward(event.keycode-KEY_1)
            accept_event()
        return
    if not g.picking:return
    if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_TAB]:
        var step := -1 if event.keycode == KEY_LEFT else 1
        selected_focus = posmod(selected_focus+step,g.selected_cards.size())
        accept_event()
    elif event.keycode == KEY_ENTER and selected_focus >= 0:
        g._choose_card(selected_focus)
        accept_event()

func _sound() -> void:
    g.muted = not g.muted
    g.music_player.volume_db = -80.0 if g.muted else -10.0
    g.sfx_player.volume_db = -80.0 if g.muted else -6.0
    g.special_sfx_player.volume_db = -80.0 if g.muted else -5.0

func _text(s: String, pos: Vector2, px: int = 16, color: Color = CREAM, font: Font = null) -> void:
    draw_string(body if font == null else font,pos,s,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)

func _center(s: String, x: float, y: float, px: int = 16, color: Color = CREAM, font: Font = null) -> void:
    var f: Font = body if font == null else font
    _text(s,Vector2(x-f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x*0.5,y),px,color,f)

func _wrap(s: String, rect: Rect2, px: int, color: Color, font: Font = null, centered: bool = false) -> int:
    var f: Font = body if font == null else font
    var lines: Array[String] = []
    var line := ""
    for word in s.split(" "):
        var candidate := word if line.is_empty() else line + " " + word
        if f.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x > rect.size.x and not line.is_empty():
            lines.append(line)
            line = word
        else: line = candidate
    if not line.is_empty(): lines.append(line)
    for i in range(lines.size()):
        if centered: _center(lines[i],rect.get_center().x,rect.position.y+i*(px+7),px,color,f)
        else: _text(lines[i],rect.position+Vector2(0,i*(px+7)),px,color,f)
    return lines.size()

func _box(r: Rect2, color: Color, stroke: Color = Color.TRANSPARENT, radius: int = 4) -> void:
    NinjaTheme.panel(self,r,color,stroke)

func _button(r: Rect2, label: String, primary: bool = true) -> void:
    var hot := r.has_point(get_local_mouse_position())
    var c := RED.lightened(0.10) if hot else RED
    if not primary: c = Color("344145") if hot else Color("293538")
    _box(r,c,GOLD if hot else Color(1,1,1,0.12),3)
    _center(label,r.get_center().x,r.get_center().y+6,17,CREAM)

func _line(y: float, x: float, width: float, color: Color) -> void:
    draw_line(Vector2(x,y),Vector2(x+width,y),color,1.0)

func _seal(at: Vector2, radius: float, color: Color) -> void:
    draw_arc(at,radius,0,TAU,64,color,2.0,true)
    draw_arc(at,radius-6,0,TAU,64,color,1.0,true)
    var pts := PackedVector2Array()
    for i in range(50):
        var t := float(i)/49.0
        pts.append(at+Vector2.from_angle(t*TAU*1.8)*radius*0.70*t)
    draw_polyline(pts,color,2.0,true)
    draw_line(at+Vector2(radius*0.4,radius*0.5),at+Vector2(radius*0.9,radius*0.8),color,2.0,true)

func _bar(r: Rect2, fraction: float, color: Color) -> void:
    NinjaTheme.meter(self,r,fraction,color)

func _draw() -> void:
    if g == null or body == null: return
    if not g.playing:
        _title()
        return
    if g.form_choice:
        _forms()
    elif g.transition_time>=0:
        _hud();draw_rect(Rect2(0,0,1280,720),Color(0.03,0.05,0.05,clampf(g.transition_time/2.1,0,1)));_center("SASORI / POJEDYNEK",640,350,34,CREAM,title)
    elif g.finished:
        _result()
    elif g.gacha_active:
        _gacha()
    elif g.picking:
        _upgrades()
    elif g.paused:
        _pause()
    else:
        _hud()
        if g.transform_pause > 0:
            draw_rect(Rect2(0,0,1280,720),Color(0.05,0.07,0.08,0.25))
            _center(g.alpha.awakening_title(g.build.form_branch,g.transform_target_form),640,191,31,CREAM,title)
            _center("PRZEBUDZENIE CHAKRY",640,222,13,GOLD,mono)

func _title() -> void:
    draw_rect(Rect2(0,0,1280,720),INK)
    draw_colored_polygon(PackedVector2Array([Vector2(780,0),Vector2(1280,0),Vector2(1280,720),Vector2(615,720)]),Color("e5d6b4"))
    for i in range(12):
        var x=730+i*58
        draw_line(Vector2(x,0),Vector2(x-170,720),Color(0.17,0.20,0.23,0.05),18)
    draw_circle(Vector2(971,331),191,Color("b74935"))
    draw_circle(Vector2(971,331),174,Color("cc6943"))
    NinjaTheme.seal(self,Vector2(971,331),153,Color(0.97,0.83,0.58,0.28))
    for i in range(9):
        draw_line(Vector2(691,184+i*30),Vector2(1260,146+i*30),Color(.1,.15,.2,.08),2)
    NinjaTheme.panel(self,Rect2(82,40,314,27),Color("243040"),GOLD)
    _text("NINJA ARTS  /  SHIPPUDEN",Vector2(94,59),12,GOLD,mono)
    _text("SHINOBI",Vector2(77,178),66,CREAM,title)
    _text("SURVIVORS",Vector2(79,250),52,CREAM,title)
    _line(294,82,410,Color("6b7166"))
    _text("MISJA: PUSTYNIA  /  ALPHA" if g.selected_map=="desert" else "MISJA: LAS ŚMIERCI  /  ALPHA",Vector2(84,331),15,GOLD,mono)
    _wrap("Przetrwaj napór ninja. Zbieraj zwoje i odblokowuj jutsu. Wybierz mapę:",Rect2(84,362,450,54),17,MUTED)
    _button(Rect2(82,415,220,38),("●  PUSTYNIA" if g.selected_map=="desert" else "PUSTYNIA"),g.selected_map=="desert")
    _button(Rect2(318,415,232,38),("●  LAS ŚMIERCI" if g.selected_map=="forest" else "LAS ŚMIERCI"),g.selected_map=="forest")
    _button(Rect2(82,463,390,62),"ROZPOCZNIJ MISJĘ    ↵")
    _button(Rect2(82,551,220,36),"EFEKTY: " + ("NISKIE" if g.low_fx else "PEŁNE"),false)
    _button(Rect2(320,551,230,36),"NIEŚMIERTELNOŚĆ: " + ("TAK" if g.godmode else "NIE"),false)
    _button(Rect2(82,601,220,36),"DŹWIĘK: " + ("WYŁ." if g.muted else "WŁ."),false)
    _text("WASD  RUCH    SHIFT  KAWARIMI    X  WSPARCIE    T  DRZEWKA",Vector2(83,682),11,MUTED,mono)
    _center(str(g.alpha.hero()["name"]),967,443,22,INK,title)
    _center("6 POSTACI   •   36 DRZEWEK   •   252 TALENTY",967,470,12,Color("695b47"),mono)
    for i in range(6):
        var id:String=str(g.alpha.IDS[i]);var data:Dictionary=g.alpha.HEROES[id];var r:Rect2=_hero_rect(i)
        var active:bool=g.alpha.selected==id
        _box(r,Color("513f31") if active else Color("283641"),GOLD if active else Color("87949a"))
        var icon_pack:String=str(data["pack"])
        if icons.has(icon_pack) and icons[icon_pack]!=null:
            var tex:Texture2D=icons[icon_pack]
            var dims:Vector2=tex.get_size()*minf(0.72,45.0/tex.get_height())
            draw_texture_rect(tex,Rect2(Vector2(r.position.x+30-dims.x*.5,r.position.y+55-dims.y),dims),false)
        _text(str(data["name"]).replace("UZUMAKI ","").replace("HATAKE ","").replace("HYŪGA ","").replace("UCHIHA ",""),Vector2(r.position.x+58,r.position.y+27),12,CREAM,title)
        _text("[%d] %s"%[i+1,str(data["role"])],Vector2(r.position.x+58,r.position.y+46),8,GOLD if active else MUTED,mono)
    _text("ROZWÓJ: T  •  WALKA: J K L  •  DRZEWKA ZOSTAJĄ W RUNIE",Vector2(693,692),10,Color("695b47"),mono)

func _hud() -> void:
    _box(Rect2(22,18,360,99),INK,GOLD)
    NinjaTheme.seal(self,Vector2(65,67),33,Color("d38843"))
    var tex:Texture2D=icons.get(g.build.actor_pack(),icons["naruto_base"])
    var dims=tex.get_size()*minf(1.15,76.0/tex.get_height())
    draw_texture_rect(tex,Rect2(Vector2(65-dims.x/2,107-dims.y),dims),false)
    _text(str(g.alpha.hero()["name"]),Vector2(111,43),14,CREAM,title)
    _text("%02d"%g.level,Vector2(337,43),17,GOLD,mono)
    var hp_max:float=g.PLAYER_MAX_HP+float(g.upgrades.get("max_hp",0))*18
    _bar(Rect2(111,54,251,17),g.player_hp/hp_max,Color("df7855"))
    _bar(Rect2(111,79,251,7),g.exp_value/g.exp_needed,NinjaTheme.CYAN)
    _text("HP %d/%d"%[ceili(g.player_hp),hp_max],Vector2(111,104),10,CREAM,mono)
    _text("XP %d/%d"%[g.exp_value,g.exp_needed],Vector2(253,104),10,NinjaTheme.CYAN,mono)
    _box(Rect2(514,18,252,71),INK,GOLD)
    _center("%02d:%02d"%[int(g.clock/60),int(g.clock)%60],583,64,27,CREAM,mono)
    _text("POKONANI",Vector2(669,40),10,MUTED,mono)
    _text(str(g.stat_kills),Vector2(670,67),23,GOLD,title)
    _box(Rect2(974,18,284,71),INK,GOLD)
    _text(g.build.form_name(),Vector2(993,43),14,CREAM,title)
    var next="WYBÓR DROGI · %ds"%ceili(maxf(0,150-g.clock)) if g.player_form==0 else "PRZEBUDZENIE · %ds"%ceili(maxf(0,330-g.clock)) if g.player_form==1 else "SASORI · %ds"%ceili(maxf(0,480-g.clock))
    _text(next,Vector2(993,69),11,GOLD,mono)
    if g.godmode:
        # Keep status badge inside the form card, not over the playfield.
        _text("GOD",Vector2(1217,68),11,Color("ffb275"),mono)
    if g.miniboss_active:
        for e in g.enemies:
            if e.get("mini_boss",false):
                _box(Rect2(383,110,514,66),Color("271b1e"),Color("df6b3f"),3)
                var mini_stage:int=int(e.get("mini_stage",1))
                _center("!  WARNING  !    "+g.MIDBOSS_NAMES[mini_stage],640,137,15,Color("ffbd70"),mono)
                _bar(Rect2(408,153,464,9),float(e["hp"])/maxf(1.0,float(e["max_hp"])),RED)
                break
    if g.boss_active and not g.boss.is_empty():
        _box(Rect2(393,109,494,54),INK,Color("9e6e51"),3)
        _center("SASORI  /  FAZA %s" % ["I","II"][clampi(g.boss_phase_reached-1,0,1)],640,130,13,CREAM,mono)
        _bar(Rect2(408,141,464,9),float(g.boss.hp)/float(g.boss.max_hp),RED)
    for i in range(3):
        var id=g.build.offensive_slots[i]
        _cooldown(Rect2(24+i*222,638,214,59),["J","K","L"][i],g.Registry.title(id),g.skill_adapter.cooldown(id),id!=null)
    _cooldown(Rect2(690,638,300,59),"AUTO" if g.build.utility_id=="oiroke" else "X",g.Registry.title(g.build.utility_id),g.skill_adapter.utility_cd,g.build.utility_id!="")
    _text("SHIFT KAWARIMI: "+("GOTOWE" if g.dash_cooldown<=0 else "%.1f s"%g.dash_cooldown),Vector2(24,620),11,CREAM,mono)
    _button(Rect2(1090,647,160,44),g.speed_labels[g.speed_index]+"  [SPACJA]",false)
    _text("ESC  PAUZA",Vector2(1015,620),11,CREAM,mono)
    _text("[T] DRZEWKA  •  %d PKT"%g.alpha.points,Vector2(974,605),12,GOLD,mono)
    if g.event_time > 0:
        var msg: String = g.event_msg
        var w := minf(920,body.get_string_size(msg,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+48)
        _box(Rect2(640-w/2,576,w,36),Color(0.10,0.15,0.16,0.92),Color(0.75,0.62,0.36,0.5),3)
        _center(msg,640,600,16,CREAM)

func _cooldown(r: Rect2, key: String, label: String, cooldown: float, unlocked: bool) -> void:
    var ready=unlocked and cooldown<=0
    _box(r,INK,NinjaTheme.CYAN if ready else Color("6c655b"))
    draw_colored_polygon(PackedVector2Array([r.position+Vector2(8,29),r.position+Vector2(30,7),r.position+Vector2(52,29),r.position+Vector2(30,51)]),Color("2c3c4c"))
    _center(key,r.position.x+30,r.position.y+16,9,GOLD,mono)
    var skill_id=""
    for id in g.JUTSU:
        if g.Registry.title(id)==label:skill_id=id;break
    if icons.has(skill_id) and icons[skill_id]!=null:
        var tex:Texture2D=icons[skill_id];var dims=tex.get_size()*minf(30/tex.get_width(),30/tex.get_height())
        draw_texture_rect(tex,Rect2(r.position+Vector2(30,36)-dims*.5,dims),false)
    else:NinjaTheme.seal(self,r.position+Vector2(30,35),10,Color(GOLD,.7))
    _text(label,r.position+Vector2(62,23),12,CREAM,title)
    _text("ZWÓJ WYMAGANY" if not unlocked else "GOTOWE" if ready else "%.1f s"%cooldown,r.position+Vector2(62,44),11,NinjaTheme.CYAN if ready else MUTED,mono)
    draw_line(r.position+Vector2(62,r.size.y-7),r.position+Vector2(r.size.x-12,r.size.y-7),Color(NinjaTheme.CYAN,.7) if ready else Color("414854"),2)

func _gacha() -> void:
    # An actual reel: 2.55 seconds of acceleration/deceleration, then a reward reveal.
    var t:float=g.gacha_elapsed
    var spin:bool=not g.gacha_revealed
    draw_rect(Rect2(Vector2.ZERO,Vector2(1280,720)),Color(0.035,0.06,0.08,0.97))
    for i in range(26):
        var x:float=28.0+float(i)*49.0
        var drop:float=absf(sin(age*2.5+float(i)*1.9))*65.0
        draw_line(Vector2(x,0),Vector2(x+19.0,drop),Color(0.99,0.77,0.35,0.09),2.0)
    _seal(Vector2(640,355),272,Color(1,0.69,0.20,0.11))
    _center("SKRZYNIA SHINOBI",640,76,16,GOLD,mono)
    _center("SZANSA NA EPICKĄ TECHNIKĘ" if g.gacha_jackpot else "TRZY ZWOJE • JEDEN WYBÓR",640,121,28,CREAM,title)
    _center("Ładowanie chakry..." if spin else "ODPIECZĘTOWANO! WYBIERZ JEDNĄ NAGRODĘ",640,160,15,MUTED,mono)
    var chest:Texture2D=g.chest_texture if spin else g.chest_open_texture
    if chest!=null:
        var bob:float=6.0*sin(age*11.0) if spin else 0.0
        draw_texture_rect(chest,Rect2(Vector2(574,179+bob),Vector2(132,132)),false)
    if spin:
        var charge:float=clampf(t/2.55,0.0,1.0)
        var running:float=1.0-pow(1.0-charge,2.3)
        var offset:int=int(90.0*running)
        for i in range(3):
            var r:=Rect2(168+i*330,346,288,193)
            var a:int=posmod(offset+i*13+int(age*12.0*(1.0-charge)),maxi(1,g.gacha_candidates.size()))
            var key:String=g.gacha_candidates[a] if not g.gacha_candidates.is_empty() else "rasengan"
            var data:Dictionary=g.JUTSU[key]
            var tier:int=int(data["tier"])
            var rarity:Color=TIERS[tier]
            _box(r,INK,rarity,6)
            _box(Rect2(r.position.x+8,r.position.y+8,r.size.x-16,8),rarity)
            _center(TIER_NAMES[tier],r.get_center().x,r.position.y+38,12,rarity,mono)
            _center(str(data["name"]),r.get_center().x,r.position.y+112,15,CREAM,title)
            _center("? ? ?" if i!=1 else "★   ★   ★",r.get_center().x,r.position.y+166,17,GOLD,mono)
        _box(Rect2(174,583,932,17),Color("3a3730"),Color("b9a671"),3)
        _box(Rect2(178,587,924*running,9),GOLD,Color.TRANSPARENT,2)
        _center("LOSOWANIE   %d%%" % int(charge*100.0),640,630,14,CREAM,mono)
    else:
        var count:int=g.gacha_rewards.size()
        for i in range(count):
            var key:String=g.gacha_rewards[i]
            var tier:int=int(g.JUTSU[key]["tier"])
            var cx:float=640.0 + (float(i)-float(count-1)*0.5)*337.0
            var r:=Rect2(cx-151,358,302,189)
            var pulse:float=sin(age*6.0+float(i)*1.3)*0.09
            _box(Rect2(r.position-Vector2.ONE*4.0,r.size+Vector2.ONE*8.0),Color(TIERS[tier],0.25+pulse),Color(1.0,0.79,0.39,0.55),6)
            _box(r,PAPER,TIERS[tier],6)
            _center(TIER_NAMES[tier],cx,389,13,TIERS[tier],mono)
            _center(str(g.JUTSU[key]["name"]),cx,463,19,INK,title)
            _center("WYBIERZ   [ %d ]" % (i+1),cx,505,14,RED,mono)
            if r.has_point(get_local_mouse_position()):
                _box(Rect2(cx-145,352,290,7),GOLD,Color.TRANSPARENT,3)
            for j in range(10):
                var angle:float=TAU*float(j)/10.0+age*1.3
                var at:Vector2=Vector2(cx,444)+Vector2.from_angle(angle)*(110.0+sin(age*4.0)*6.0)
                draw_circle(at,2.0,Color(1.0,0.87,0.38,0.55))
        _center("KLIKNIJ KARTĘ LUB NACIŚNIJ 1 / 2 / 3  •  OTRZYMASZ JEDNĄ",640,606,16,GOLD,mono)
    _center("GRA WSTRZYMANA NA CZAS OTWIERANIA SKRZYNI",640,679,11,MUTED,mono)

func _upgrades() -> void:
    draw_rect(Rect2(0,0,1280,720),Color(0.065,0.105,0.115,0.94))
    _seal(Vector2(1160,87),126,Color(0.83,0.72,0.47,0.055))
    _center("ZNALEZIONO STAROŻYTNY ZWÓJ" if from_scroll else "AWANS  /  POZIOM %02d" % g.level,640,62,13,GOLD,mono)
    _center("Wybierz swoją technikę",640,108,35,CREAM,title)
    _center("Jeden zwój. Nowa przewaga w walce.",640,137,15,MUTED)
    for i in range(g.selected_cards.size()):
        var r := _card_rect(i)
        var t := clampf((reveal-float(i)*0.10)*4.0,0.0,1.0)
        var hot := i == hover_card or i == selected_focus
        r.position.y += (1.0-t)*28.0 - (7.0 if hot else 0.0)
        draw_set_transform(r.position,0,Vector2.ONE)
        _scroll(g.selected_cards[i],i,hot)
        draw_set_transform(Vector2.ZERO)
    _center("OFENSYWA: %d/3  •  X: %s"%[g.build.owned().size(),g.Registry.title(g.build.utility_id)],640,651,13,GOLD,mono)
    _center("1 / 2 / 3 / 4 LUB KLIK — WYBIERZ JEDEN ZWÓJ",640,684,12,MUTED,mono)

func _scroll(card: Dictionary, index: int, hot: bool) -> void:
    var tier: int = card.tier
    var color: Color = TIERS[tier]
    var key: String = card.stat
    var data: Dictionary = g.JUTSU[key]
    _box(Rect2(9,36,290,402),Color(0,0,0,0.27),Color.TRANSPARENT,7)
    _box(Rect2(13,22,278,435),PAPER.lightened(0.05) if hot else PAPER,color if hot else Color("b49d70"),1)
    for y in range(42,424,13):
        draw_line(Vector2(19,y),Vector2(285,y+1),Color(0.4,0.27,0.09,0.033),1)
    draw_rect(Rect2(23,44,258,35),Color(color,0.14))
    _center(TIER_NAMES[tier],152,66,12,color,mono)
    draw_circle(Vector2(152,151),78,Color("e4d0a5"))
    draw_arc(Vector2(152,151),79,0,TAU,64,Color(color,0.40),2.0,true)
    _icon(key,Vector2(152,151),color)
    _wrap(str(data.name),Rect2(29,240,246,60),18,INK,title,true)
    _line(284,37,230,Color("cbb387"))
    _wrap(str(data.desc),Rect2(39,312,226,80),14,Color("62583f"),body,true)
    var current: int = int(g.upgrades.get(key,0))
    var maximum: int = mini(5,int(data.max))
    var start: float = 152.0-float(maximum)*7.0
    for i in range(maximum):
        _box(Rect2(start+i*15.0,373,9,5),color if i<=current else Color("c9b58b"),Color.TRANSPARENT,1)
    if data.has("req"):
        var needed:Dictionary=g.JUTSU[str(data["req"])]
        _center("EWOLUCJA: " + str(needed["name"]).substr(0,21),152,409,10,Color("6e4d41"),mono)
    else:
        _center("ODKRYJ JUTSU" if current==0 else "POZIOM %d → %d" % [current,current+1],152,399,12,color,mono)
    _box(Rect2(33,412,238,29),color,Color.TRANSPARENT,2)
    _center("[ %d ]   OTWÓRZ ZWÓJ" % (index+1),152,432,12,CREAM,mono)
    for y in [18.0,449.0]:
        _box(Rect2(4,y,296,16),Color("604937"),Color("a17a47"),5)
        draw_line(Vector2(17,y+4),Vector2(286,y+4),Color("a28053"),2.0)
        for x in [4.0,282.0]:
            _box(Rect2(x,y-3,18,22),GOLD,Color("8a683c"),4)
            draw_line(Vector2(x+4,y),Vector2(x+4,y+15),Color("f1d492"),2)

func _icon(key: String, at: Vector2, color: Color) -> void:
    # Never show Naruto's Rasengan/clone icon for another character's technique.
    var hero_id:String=str(g.alpha.selected)
    var basic:String=key.get_slice(":",0)
    if hero_id!="naruto" and Registry.DATA.has(basic):
        var pack:String=str(g.alpha.hero()["pack"])
        var pose:String="200" if basic in ["rasengan","naruto_rendan","henge_feint"] else "210" if basic in ["fuma_shuriken","shuriken_barrage","kunai_kibaku"] else "220"
        var art_key:String=pack+":action:"+pose
        if icons.has(art_key) and icons[art_key]!=null:
            var art:Texture2D=icons[art_key]
            var size:Vector2=art.get_size()
            var scale:float=minf(139.0/maxf(1.0,size.x),139.0/maxf(1.0,size.y))
            var dimensions:Vector2=size*scale
            draw_texture_rect(art,Rect2(at-dimensions*0.5,dimensions),false)
            draw_arc(at,78.0,-PI*.86,PI*.14,36,Color(color,0.62),2.0,true)
            return
    if icons.has(key) and icons[key]!=null and key not in ["kunai"]:
        var icon_tex:Texture2D=icons[key]
        var width:float=132.0 if key=="oiroke" else 145.0 if key in ["naruto_rendan","melee_rasengan","melee_combo"] else 128.0
        var original_dims:Vector2=icon_tex.get_size()
        var aspect:float=original_dims.x/maxf(1.0,original_dims.y)
        var dimensions:Vector2=Vector2(minf(width,width*aspect),minf(width,width/aspect))
        draw_texture_rect(icon_tex,Rect2(at-dimensions*0.5,dimensions),false)
    elif key=="clones":
        var tex: Texture2D = icons["naruto_base"]
        for i in range(3):
            var dims := tex.get_size()*1.12
            draw_texture_rect(tex,Rect2(at+Vector2(-48+i*29,-35),dims),false,Color(1,1,1,0.45 if i!=1 else 1.0))
    elif key.begins_with("kunai"):
        var tex: Texture2D = icons["kunai"]
        draw_texture_rect(tex,Rect2(at-Vector2(42,12),Vector2(84,29.4)),false)
        if key=="kunai_twin": draw_texture_rect(tex,Rect2(at+Vector2(-35,10),Vector2(70,24.5)),false,Color(1,1,1,0.65))
    elif key in ["max_hp","regeneration"]:
        draw_rect(Rect2(at-Vector2(7,28),Vector2(14,56)),color)
        draw_rect(Rect2(at-Vector2(28,7),Vector2(56,14)),color)
    elif key=="speed":
        for i in range(3):
            var x := at.x-28+i*20
            draw_polyline(PackedVector2Array([Vector2(x-10,at.y-20),Vector2(x+7,at.y),Vector2(x-10,at.y+20)]),color,5,true)
    elif key in ["magnet","sage_focus","crit"]:
        _seal(at,35,color)
    else:
        draw_circle(at,30,Color("3796ac"))
        for i in range(4):
            draw_arc(at,12+i*5,age*0.5+i,age*0.5+i+PI*1.6,32,Color("9decdf"),2.0,true)
        draw_circle(at+Vector2(-9,-9),6,Color("ddfff1"))

func _card_index(key: String) -> int:
    for i in range(g.selected_cards.size()):
        if g.selected_cards[i].stat==key: return i
    return 0

func _pause() -> void:
    draw_rect(Rect2(0,0,1280,720),Color(0.06,0.10,0.11,0.88))
    _seal(Vector2(640,222),47,GOLD)
    _center("Chwila oddechu",640,324,37,CREAM,title)
    _center("Misja wstrzymana. Twoje zwoje czekają.",640,359,16,MUTED)
    _button(Rect2(467,400,346,56),"WRÓĆ DO WALKI    [ ESC ]")
    _button(Rect2(467,476,346,42),"DŹWIĘK: " + ("WYŁ." if g.muted else "WŁ."),false)
    _button(Rect2(467,531,346,48),"POWRÓT DO MENU    [BACKSPACE]",false)
    _center("WASD RUCH   SHIFT KAWARIMI   X WSPARCIE",640,630,12,MUTED,mono)
    _center("SPACJA  1x–5x   F EFEKTY   G NIEŚMIERTELNOŚĆ",640,661,11,MUTED,mono)

func _result() -> void:
    draw_rect(Rect2(0,0,1280,720),Color(0.06,0.10,0.11,0.93))
    _box(Rect2(377,93,526,537),PAPER,Color("a18b61"),3)
    for y in [84.0,630.0]:
        _box(Rect2(355,y,570,22),Color("664b34"),GOLD,6)
        _box(Rect2(355,y-3,24,28),GOLD,Color.TRANSPARENT,4)
        _box(Rect2(901,y-3,24,28),GOLD,Color.TRANSPARENT,4)
    _center("RAPORT Z MISJI",640,145,12,Color("806840"),mono)
    _center("Misja wykonana" if victory else "Następnym razem…",640,199,30,INK,title)
    _center("SASORI POKONANY" if victory else "NINJA NIGDY SIĘ NIE PODDAJE",640,234,12,RED,mono)
    _line(269,426,428,Color("c3ac7f"))
    var rows := [["CZAS MISJI","%02d:%02d" % [int(g.clock/60),int(g.clock)%60]],["POKONANI NINJA",str(g.stat_kills)],["ZEBRANA CHAKRA",str(g.stat_exp_collected)],["ZNALEZIONE ZWOJE",str(g.scroll_count)],["POZIOM KOŃCOWY",str(g.level)]]
    for i in range(rows.size()):
        _text(rows[i][0],Vector2(430,312+i*40),12,Color("796748"),mono)
        _text(rows[i][1],Vector2(769,312+i*40),19,INK,mono)
    _button(Rect2(467,551,346,56),"JESZCZE JEDNA MISJA    ↵")

func _forms() -> void:
    draw_rect(Rect2(0,0,1280,720),Color(0.03,0.06,0.07,0.96))
    _center("WYBIERZ SWOJĄ DROGĘ",640,125,36,CREAM,title)
    _center("Jedna gałąź. Dwa przebudzenia. Jutsu zachowują swoje sloty.",640,174,16,MUTED)
    for i in range(2):
        var r=Rect2(180+i*480,225,440,350)
        _box(r,PAPER,GOLD,4)
        var pack:String=("naruto_kyubi" if i==0 else "naruto_sage") if g.alpha.selected=="naruto" else str(g.alpha.hero()["pack"])
        var tex:Texture2D=icons[pack]
        var dims=tex.get_size()*minf(1.7,110.0/tex.get_height())
        draw_texture_rect(tex,Rect2(Vector2(r.get_center().x-dims.x/2,r.position.y+28),dims),false)
        var path:String="kyubi" if i==0 else "sage"
        var first:String=g.alpha.awakening_title(path,1)
        var last:String=g.alpha.awakening_title(path,2)
        _center(first,r.get_center().x,392,20,INK,title)
        _center("DALEJ: "+last,r.get_center().x,422,13,RED,mono)
        var description:String=("Szybsza ofensywa. Przy 05:30 KCM: dodatkowe ramiona chakry wspierają ataki." if i==0 else "Frog Kata: zasięg, przełamanie gardy i kontra. Przy 05:30 Sennin Mastery.") if g.alpha.selected=="naruto" else ("Wyzwól ukrytą moc swojego shinobi, by zadać większe obrażenia i walczyć agresywniej." if i==0 else "Zyskuj okna na kontry, niezłomność i większą kontrolę walki.")
        _wrap(description,Rect2(r.position+Vector2(35,190),Vector2(370,100)),16,INK)
        _center("[ %d ] WYBIERZ"%(i+1),r.get_center().x,550,16,RED,mono)
    _center("Sennin Mastery to adaptacja, nie Six Paths." if g.alpha.selected=="naruto" else "Drzewka talentów i wybrane jutsu zostają z tobą.",640,641,13,MUTED)
