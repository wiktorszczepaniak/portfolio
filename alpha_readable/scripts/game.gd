extends Node2D
const CleanFX=preload("res://scripts/combat/ninja_fx.gd")
const AlphaSystem=preload("res://scripts/core/alpha_progress.gd")
const AlphaAbilities=preload("res://scripts/combat/alpha_abilities.gd")
const AlphaMelee=preload("res://scripts/combat/alpha_melee.gd")
const Pickups=preload("res://scripts/core/pickup_manager.gd")
const SpawnDirector=preload("res://scripts/core/enemy_spawn_director.gd")
## NEW Godot gameplay architecture, not a port of the abandoned Go/Win32 code.
## MUGEN frames are loaded from imported community packs; temporary debug markers
## are visible only while a pack has not yet been supplied.

const MugenActor = preload("res://scripts/mugen_actor.gd")
const ShinobiUI = preload("res://scripts/shinobi_ui.gd")
const Registry=preload("res://scripts/core/jutsu_registry.gd")
const Draft=preload("res://scripts/core/upgrade_draft.gd")
const Forms=preload("res://scripts/core/transformation_controller.gd")
const Adapter=preload("res://scripts/combat/survival_skill_adapter.gd")
const Resolver=preload("res://scripts/combat/combat_resolver.gd")
var JUTSU=Registry.cards()
var build
var draft
var skill_adapter
var form_choice:=false
var transition_time:=-1.0
const VIEW := Vector2(1280.0, 720.0)
const TILE_SIZE := 64
const MAX_ENEMIES := 108
const MAX_SHOTS := 90
const MAX_DROPS := 190
const MAX_FX := 110
const TRANSFORM_SAGE := 120.0
const TRANSFORM_KCM := 330.0
const BOSS_TIME := 480.0
const BOSS_HP := 15000.0  # Legacy constant; dynamic two-pool boss below
const PLAYER_SPEED := 168.0
const PLAYER_MAX_HP := 165.0
const TRANSFORM_DAMAGE_BOOST := [1.0, 1.49, 2.00]
const TRANSFORM_RATE_BOOST := [1.0, 0.85, 0.73]
const TRANSFORM_SHOT_SCALE := [1.0, 1.16, 1.32]
const ENEMY_PACKS := ["sound_scythe", "sound_pole", "sound_mirror", "sound_heavy"]
const QUALITY_LABELS := ["LOW FX", "NORMAL FX"]
const MIDBOSS_TIMES := [160.0, 255.0, 385.0]
const MIDBOSS_NAMES := ["STRAŻNIK ŻÓŁTEGO PIASKU", "STRAŻNIK CZERWONEGO PIASKU", "STRAŻNIK MOKREGO PIASKU"]
const ROOT_SKILLS := ["rasengan", "oiroke", "naruto_rendan", "fuma_shuriken", "melee_rasengan"]
const MAX_ROOT_SLOTS := 2
const LEGACY_JUTSU := {
    "rasengan":{"name":"RASENGAN","desc":"Odblokuj kulę chakry, która wspiera podstawowe kunai.","tier":1,"max":1},
    "kunai_twin":{"name":"PODWÓJNE KUNAI","desc":"Rzucaj dodatkowym kunai w każdej salwie.","tier":0,"max":3},
    "kunai_rapid":{"name":"SZYBKIE RZUTY","desc":"Skróć przerwę między kolejnymi salwami kunai.","tier":0,"max":4},
    "kunai_pierce":{"name":"PRZEBIJAJĄCE KUNAI","desc":"Każde kunai przebija kolejnego przeciwnika.","tier":1,"max":3},
    "kunai_explosive":{"name":"WYBUCHOWA PIECZĘĆ","desc":"Co kilka rzutów kunai wybucha przy trafieniu.","tier":1,"max":2},
    "naruto_rendan":{"name":"NARUTO RENDAN","desc":"Klony pod X wykonują serię ciosów. Siła rośnie z Kage Bunshin.","tier":1,"max":3},
    "oiroke":{"name":"OIROKE NO JUTSU","desc":"Automatyczna bariera rani i zatrzymuje pobliskich ninja.","tier":2,"max":3},
    "oodama":{"name":"ŌDAMA RASENGAN","desc":"Większa kula chakry zadaje wyższe obrażenia.","tier":1,"max":3},
    "rasenshuriken":{"name":"RASENSHURIKEN","desc":"Dodaj wybuchowe shurikeny do salw Rasengana.","tier":2,"max":2},
    "rasenrendan":{"name":"RASENRENDAN","desc":"Wystrzel serię dodatkowych Rasenganów.","tier":1,"max":3},
    "rasenornado":{"name":"RASENORNADO","desc":"Tornada chakry ścigają i ranią grupy przeciwników.","tier":2,"max":2},
    "chakra_flow":{"name":"PRZEPŁYW CHAKRY","desc":"Skróć przerwę między seriami Rasengana.","tier":0,"max":5},
    "clones":{"name":"KAGE BUNSHIN","desc":"Więcej klonów, dłuższy czas działania i silniejszy Rendan.","tier":1,"max":4},
    "speed":{"name":"SHUNSHIN","desc":"Poruszaj się szybciej i częściej używaj Kawarimi.","tier":0,"max":5},
    "magnet":{"name":"WYCZUCIE CHAKRY","desc":"Przyciągaj kule chakry i zwoje z większej odległości.","tier":0,"max":5},
    "max_hp":{"name":"WITALNOŚĆ UZUMAKI","desc":"Zwiększ maksymalne HP i natychmiast odzyskaj zdrowie.","tier":0,"max":5},
    "pierce":{"name":"PENETRACJA CHAKRY","desc":"Rasengany przenikają przez kolejnych przeciwników.","tier":1,"max":3},
    "multishot":{"name":"PODWÓJNY RASENGAN","desc":"Dodaj kolejną kulę chakry do każdego wachlarza.","tier":1,"max":3},
    "regeneration":{"name":"MEDYTACJA SENNINA","desc":"Odzyskuj HP po pokonaniu kolejnej grupy ninja.","tier":1,"max":3},
    "crit":{"name":"OSTRZE WIATRU","desc":"Zwiększ szansę na trafienie krytyczne.","tier":1,"max":4},
    "sage_focus":{"name":"MOC NATURY","desc":"Zwiększ zasięg Rasenshurikena i tornad chakry.","tier":3,"max":1},
    "kunai_fan":{"name":"DESZCZ KUNAI","desc":"Ścieżka Podwójnych Kunai. Dodaj dwa boczne ostrza do salwy.","tier":1,"max":3,"req":"kunai_twin","min":1},
    "kunai_return":{"name":"OSTRZA POWROTNE","desc":"Ścieżka Deszczu Kunai. Ostrza zawracają i trafiają ponownie.","tier":2,"max":2,"req":"kunai_fan","min":2},
    "kunai_bleed":{"name":"KRWAWIĄCE CIĘCIE","desc":"Ścieżka Przebicia. Kunai nakłada obrażenia przez 3 sekundy.","tier":1,"max":3,"req":"kunai_pierce","min":1},
    "kunai_chain":{"name":"ŁAŃCUCH PIECZĘCI","desc":"Ścieżka Eksplozji. Wybuch kunai trafia też dalsze cele.","tier":2,"max":2,"req":"kunai_explosive","min":1},
    "chakra_overload":{"name":"PRZECIĄŻENIE CHAKRY","desc":"Ścieżka Rasengana. Rosną obrażenia wszystkich technik chakry.","tier":2,"max":3,"req":"chakra_flow","min":2},
    "chakra_surge":{"name":"FALA SENNINA","desc":"Ścieżka Przeciążenia. Co piąty Rasengan tworzy falę uderzeniową.","tier":3,"max":1,"req":"chakra_overload","min":2},
    "shuriken_storm":{"name":"BURZA FUUTON","desc":"Ścieżka Rasenshurikena. Wybuchy mają większy promień i wtórną falę.","tier":3,"max":2,"req":"rasenshuriken","min":1},
    "oiroke_cloud":{"name":"HAREM NO JUTSU","desc":"Ścieżka Oiroke. Gęsta chmura dymu zadaje obrażenia cyklicznie.","tier":2,"max":3,"req":"oiroke","min":1},
    "clone_army":{"name":"TAJUU KAGE BUNSHIN","desc":"Ścieżka Klonów. Przywołuj dodatkowe klony i skróć ich odnowienie.","tier":2,"max":3,"req":"clones","min":2},
    "rendan_finisher":{"name":"UZUMAKI NARUTO RENDAN","desc":"Ścieżka Rendan. Ostatni cios klonów wywołuje potężny podmuch.","tier":3,"max":2,"req":"naruto_rendan","min":1},
    "kawarimi_echo":{"name":"KAWARIMI: KONTRATAK","desc":"Ścieżka Shunshin. Pień po dashu wybucha chakrą w pobliskich ninja.","tier":1,"max":3,"req":"speed","min":2},
    "survivor_instinct":{"name":"INSTYNKT SHINOBI","desc":"Ścieżka Witalności. Przy niskim zdrowiu zyskujesz ochronę.","tier":2,"max":2,"req":"max_hp","min":2},
    "fuma_shuriken":{"name":"FŪMA SHURIKEN","desc":"Alternatywna ścieżka główna. Olbrzymi wirujący shuriken przebija szeregi ninja.","tier":1,"max":3},
    "fuma_boomerang":{"name":"CIEŃ FŪMA","desc":"Ewolucja Fūma: podwójny lot i powrót przez hordę.","tier":2,"max":2,"req":"fuma_shuriken","min":2},
    "melee_rasengan":{"name":"RASENGAN: ZWARCIE","desc":"Alternatywna ścieżka główna. Klony uderzają Rasenganem z bliska.","tier":1,"max":3},
    "melee_combo":{"name":"RASENGAN RUSH","desc":"Ewolucja Zwarcia. Seria eksplozji Rasengana wokół Naruto.","tier":2,"max":3,"req":"melee_rasengan","min":2},
    "oiroke_pressure":{"name":"HAREM: PUŁAPKA","desc":"Wzmocnienie Oiroke: częstsze pulsy, mocniejsze odrzucenie.","tier":2,"max":3,"req":"oiroke","min":1},
    "futon_edge":{"name":"FUUTON: CIĘCIE","desc":"Ewolucja Rasengana: wiatr przecina wrogów za eksplozją.","tier":2,"max":2,"req":"rasengan","min":1}
}
const RARITY_NAMES := ["COMMON","RARE","EPIC","LEGENDARY"]
const RARITY_COLORS := [Color("dee4d7"),Color("70c8ff"),Color("d29dff"),Color("ffe287")]


var ui_view
var alpha: Node
var visual_delta := 0.0166667
var rng := RandomNumberGenerator.new()
var clock := 0.0
var speed_index := 0
# Former 2x is now NORMAL, with two optional acceleration settings.
var speeds := [1.0,1.5,2.0,3.0,4.0,5.0]
const SIMULATION_DT := 1.0/60.0
var simulation_accumulator := 0.0
var speed_labels := ["1x","1.5x","2x","3x","4x","5x"]
var playing := false
var paused := false
var finished := false
var muted := false
var low_fx := false
var godmode := false
var transform_pause := 0.0
var transform_total := 0.0
var transform_target_form := -1
var transform_stage := 0
var burst_frames: Array[Texture2D] = []
var godmode_button: Button
var godmode_hud_button: Button
var result_body: Label
var upgrade_footer: Label
var upgrade_sub: Label
var transform_overlay: ColorRect
var special_sfx_player: AudioStreamPlayer
var result_meta: Label
var hostile_orb_clock := 0.0
var stat_kills := 0
var stat_exp_collected := 0
var player
var player_hp := PLAYER_MAX_HP
var player_pos := Vector2.ZERO
var player_form := 0
var player_facing := 1.0
var player_vel := Vector2.ZERO
var dash_timer := 0.0
var dash_cooldown := 0.0
var invulnerable := 0.0
var attack_timer := 0.0
var rasengan_timer := 0.0
var kunai_sequence := 0
var melee_combo:int=-1
var melee_cast:Dictionary={}
var melee_64:Dictionary={}
var oiroke_cd := 10.0
var oiroke_time := 0.0
var oiroke_hits: Dictionary = {}
var oiroke_pos := Vector2.ZERO
var selected_map := "desert"
var voice_last:Dictionary={}
var kawarimi_fx: Array[Dictionary] = []
var stage_ground: Texture2D
var item_art: Dictionary = {}
var naruto_effects: Array[Texture2D] = []
var naruto_combo_frames: Array[Texture2D] = []
var kawarimi_log: Texture2D
var clone_timer := 0.0
var clone_cooldown := 0.0
var clones: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var fx: Array[Dictionary] = []
var upgrades: Dictionary = {}
var burst_remaining := 0
var burst_timer := 0.0
var rasenshuriken_counter := 0
var tornado_timer := 0.0
var tornadoes: Array[Dictionary] = []
var recovery_kills := 0
var level := 1
var exp_value := 0.0
var exp_needed := 16.8
var spawn_timer := 0.0
var boss: Dictionary = {}
var boss_active := false
var boss_vfx: Dictionary = {}
var boss_telegraphs: Array[Dictionary] = []
var boss_phase_reached := 0
var boss_attack_history: Array[String] = []
var boss_label: Label
var event_banner: Label
var selected_cards: Array[Dictionary] = []
var picking := false
var scroll_count := 0
var title_controls: Control
var ui: CanvasLayer
var hud: Label
var hud_info: Label
var boss_bar: ProgressBar
var panel: PanelContainer
var upgrade_overlay: ColorRect
var card_art: Array[TextureRect] = []
var card_titles: Array[Label] = []
var card_descriptions: Array[Label] = []
var card_rarities: Array[Label] = []
var card_levels: Array[Label] = []
var result_text: Label
var card_buttons: Array[Button] = []
var quality_button: Button
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var rasengan_frames: Array[Texture2D] = []
var shuriken_frames: Array[Texture2D] = []
var tornado_frames: Array[Texture2D] = []
var tiles: Array[Texture2D] = []
var prop_textures: Array[Texture2D] = []
var hud_scroll_texture: Texture2D
var boss_banner_texture: Texture2D
var title_font: Font
var body_font: Font
var hud_back: TextureRect
var camera: Camera2D
var quicksand_zones: Array[Dictionary] = []
var hazard_timer := 0.0
var miniboss_timer := 0.0
var miniboss_spawned := false
var miniboss_next := 0
var rune_summoners_spawned := 0
var rune_traps: Array[Dictionary] = []
var rune_hit_timer := 0.0
var aura_frames: Array[Texture2D] = []
var rune_frames: Array[Texture2D] = []
var suiton_frames: Array[Texture2D] = []
var wet_runes: Array[Texture2D] = []
var barrage_frames: Array[Texture2D] = []
var melee_frames: Array[Texture2D] = []
var sound_ninja_frames: Array[Texture2D] = []
var ramen_texture: Texture2D
var source_rasengan_frames: Array[Texture2D] = []
var puppet_frames: Array[Texture2D] = []
var fuma_cd := 0.0
var melee_cd := 0.0
var oiroke_puff_player: AudioStreamPlayer
var miniboss_uid := -1
var miniboss_active := false
var scenery_nodes: Dictionary = {}
var scenery_layer: Node2D
var scenery_scan_time := 0.0
var scenery_hit_flash := 0.0
var chest_texture: Texture2D
var chest_open_texture: Texture2D
var oiroke_cloud_timer := 0.0
var oiroke_cast_age := 0.0
var oiroke_figure: Texture2D
var oiroke_figure_frames:Array[Texture2D]=[]
var gacha_active := false
var gacha_elapsed := 0.0
var gacha_rewards: Array[String] = []
var gacha_candidates: Array[String] = []
var gacha_jackpot := false
var gacha_revealed := false
var chest_count := 0
var gacha_sound: AudioStreamPlayer
var boss_music_stream: AudioStream
var normal_music_stream: AudioStream
var event_msg := ""
var event_time := 0.0
var log: FileAccess

func _read_png(asset_path:String) -> Texture2D:
    if not FileAccess.file_exists(asset_path):
        return null
    var raw := FileAccess.get_file_as_bytes(asset_path)
    var img := Image.new()
    if img.load_png_from_buffer(raw) != OK:
        return null
    return ImageTexture.create_from_image(img)

func _ready() -> void:
    alpha=get_node("/root/AlphaProgress")
    build=get_node("/root/RunBuild")
    draft=Draft.new(build)
    skill_adapter=Adapter.new();skill_adapter.configure(self,build);add_child(skill_adapter)
    rng.randomize()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _log_boot()
    for i in range(6):
        var path := "res://assets/stage_desert/desert_ground_1024.png" if selected_map=="desert" else "res://assets/v10/forest_ground.png"
        var tex := _read_png(path)
        if tex != null:
            tiles.append(tex)
    for i in range(4):
        var p := "res://assets/world/prop_%02d.png" % i
        var tex := _read_png(p)
        if tex != null:
            prop_textures.append(tex)
    for i in range(12):
        var path := "res://assets/vfx/rasengan_%02d.png" % i
        var tex := _read_png(path)
        if tex != null:
            rasengan_frames.append(tex)
    # Original Naruto MUGEN action 100: six transition frames used before Oiroke appears.
    for i in range(6):
        var transform_tex := _read_png("res://assets/mugen/naruto_base/100_%d.png" % i)
        if transform_tex!=null:naruto_effects.append(transform_tex)
    for i in range(12):
        var p_s := "res://assets/vfx/rasenshuriken_%02d.png" % i
        var p_t := "res://assets/vfx/rasenornado_%02d.png" % i
        var p_b := "res://assets/vfx/burst_%02d.png" % i
        var tex_s := _read_png(p_s)
        var tex_t := _read_png(p_t)
        var tex_b := _read_png(p_b)
        if tex_s != null: shuriken_frames.append(tex_s)
        if tex_t != null: tornado_frames.append(tex_t)
        if tex_b != null: burst_frames.append(tex_b)
    for fx_name in ["senbon","chakra","sand","blast","poison","smoke","hit","slash","meteor"]:
        var frames: Array[Texture2D] = []
        for j in range(18):
            var effect_path := "res://assets/boss_sasori/%s_%02d.png" % [fx_name,j]
            var boss_tex := _read_png(effect_path)
            if boss_tex != null:
                frames.append(boss_tex)
        boss_vfx[fx_name] = frames
    hud_scroll_texture = _read_png("res://assets/ui/hud_scroll.png")
    boss_banner_texture = _read_png("res://assets/ui/boss_banner.png")
    title_font = SystemFont.new()
    (title_font as SystemFont).font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Garamond"])
    body_font = SystemFont.new()
    (body_font as SystemFont).font_names = PackedStringArray(["Georgia", "Cambria", "Times New Roman"])
    stage_ground = _read_png("res://assets/stage_desert/desert_ground_1024.png" if selected_map=="desert" else "res://assets/v10/forest_ground.png")
    prop_textures.clear()
    for i in range(4):
        var prop := _read_png(("res://assets/stage_desert/prop_%02d.png" if selected_map=="desert" else "res://assets/v10/tree_%02d.png") % i)
        if prop != null: prop_textures.append(prop)
    for kind in ["kunai", "shuriken", "projectile_dart", "chakra_bomb", "explosive_note", "metal_needle", "small_shuriken"]:
        item_art[kind] = _read_png("res://assets/vfx_items/%s.png" % kind)
    kawarimi_log = _read_png("res://assets/stage_desert/kawarimi_log.png")
    chest_texture = _read_png("res://assets/v8/chest_closed.png")
    chest_open_texture = _read_png("res://assets/v8/chest_open.png")
    oiroke_figure = _read_png("res://assets/v8/oiroke_figure.png")
    for i in range(6):
        var fig=_read_png("res://assets/v10/oiroke_%02d.png"%i)
        if fig!=null:oiroke_figure_frames.append(fig)
    # V9 asset atlas imports from the original Items, Effects, Sound Ninja and Naruto sheets.
    ramen_texture=_read_png("res://assets/v9/ramen.png")
    for j in range(9):
        var texr=_read_png("res://assets/v9/rune_%02d.png" % j)
        if texr!=null:rune_frames.append(texr)
    for j in range(8):
        var texw=_read_png("res://assets/v10/water_%02d.png" % (j%2))
        if texw!=null:suiton_frames.append(texw)
        var texz=_read_png("res://assets/v9/waterrune_%02d.png" % j)
        if texz!=null:wet_runes.append(texz)
    for j in range(5):
        var texa=_read_png("res://assets/v9/red_aura_%02d.png" % j)
        if texa!=null:aura_frames.append(texa)
    for j in range(7):
        var texs=_read_png("res://assets/v9/sound_summoner_%02d.png" % j)
        if texs!=null:sound_ninja_frames.append(texs)
    for j in range(6):
        var texb=_read_png("res://assets/v9/barrage_%02d.png" % j)
        if texb!=null:barrage_frames.append(texb)
        var texm=_read_png("res://assets/v9/rasengan_sheet_%02d.png" % j)
        if texm!=null:source_rasengan_frames.append(texm)
    for j in range(5):
        var texpuppet=_read_png("res://assets/v9/kazekage_puppet_%02d.png" % j)
        if texpuppet!=null:puppet_frames.append(texpuppet)
    source_rasengan_frames=rasengan_frames.duplicate()

    scenery_layer=Node2D.new()
    add_child(scenery_layer)
    camera = Camera2D.new()
    camera.zoom = Vector2(1.5,1.5)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 10.0
    add_child(camera)
    camera.make_current()
    player = MugenActor.new()
    player.pack_name = "naruto_base"
    player.fallback_color = Color("ea8429")
    add_child(player)
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    sfx_player = AudioStreamPlayer.new()
    add_child(sfx_player)
    special_sfx_player = AudioStreamPlayer.new()
    add_child(special_sfx_player)
    gacha_sound = AudioStreamPlayer.new()
    add_child(gacha_sound)
    oiroke_puff_player=AudioStreamPlayer.new()
    add_child(oiroke_puff_player)
    if FileAccess.file_exists("res://assets/v9/oiroke_puff.wav"):
        oiroke_puff_player.stream=AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes("res://assets/v9/oiroke_puff.wav"))
        oiroke_puff_player.volume_db=-19.0

    if FileAccess.file_exists("res://assets/audio/forest_music.mp3"):
        music_player.stream = AudioStreamMP3.load_from_buffer(FileAccess.get_file_as_bytes("res://assets/audio/forest_music.mp3"))
        music_player.volume_db = -10.0
        if music_player.stream is AudioStreamMP3:
            (music_player.stream as AudioStreamMP3).loop = true
        normal_music_stream = music_player.stream
    if FileAccess.file_exists("res://assets/v8/miniboss_arcade.wav"):
        boss_music_stream = AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes("res://assets/v8/miniboss_arcade.wav"))
        if boss_music_stream is AudioStreamWAV:
            (boss_music_stream as AudioStreamWAV).loop_mode=AudioStreamWAV.LOOP_FORWARD
    ui = CanvasLayer.new()
    add_child(ui)
    _make_ui()
    var talent_screen=load("res://scripts/alpha_skill_ui.gd").new()
    talent_screen.g=self
    ui.add_child(talent_screen)
    _show_title()
    _log("boot: loaded %d tiles / %d rasengan frames" % [tiles.size(),rasengan_frames.size()])

func _log_boot() -> void:
    var path := "user://startup.log"
    log = FileAccess.open(path,FileAccess.WRITE)
    _log("Boot Godot %s | OS=%s" % [Engine.get_version_info().get("string","unknown"),OS.get_name()])

func _log(txt:String) -> void:
    print("[SHINOBI] ",txt)
    if log != null:
        log.store_line("[%.3f] %s" % [Time.get_ticks_msec()/1000.0,txt])
        log.flush()

func _make_label(parent:Node, text_value:String, size:int, color:Color) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size",size)
    if body_font != null:
        label.add_theme_font_override("font", body_font)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
    return label

func _scroll_label(parent: Node, text_value: String, font_size: int, color: Color, rect: Rect2, centered: bool = true) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_size_override("font_size",font_size)
    if body_font != null:
        label.add_theme_font_override("font", body_font)
    label.add_theme_color_override("font_color",color)
    label.add_theme_color_override("font_shadow_color",Color(0.05,0.03,0.01,0.07))
    label.add_theme_constant_override("shadow_offset_x",1)
    label.add_theme_constant_override("shadow_offset_y",1)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _make_ui() -> void:
    ui_view = ShinobiUI.new()
    ui_view.g = self
    ui.add_child(ui_view)

func _show_title() -> void:
    ui_view.queue_redraw()

func select_map(which:String) -> void:
    if playing:return
    selected_map="forest" if which=="forest" else "desert"
    stage_ground=_read_png("res://assets/stage_desert/desert_ground_1024.png" if selected_map=="desert" else "res://assets/v10/forest_ground.png")
    prop_textures.clear()
    for i in range(4):
        var prop=_read_png(("res://assets/stage_desert/prop_%02d.png" if selected_map=="desert" else "res://assets/v10/tree_%02d.png")%i)
        if prop!=null:prop_textures.append(prop)
    ui_view.queue_redraw()

func _start(seed_value:int=0) -> void:
    build.reset(seed_value);alpha.reset_run();rng.seed=build.rng_seed;skill_adapter.reset();form_choice=false;transition_time=-1
    _log("run started")
    clock=0.0
    speed_index=0
    simulation_accumulator=0.0
    playing=true
    paused=false
    picking=false
    finished=false
    player_hp=PLAYER_MAX_HP
    player_pos=Vector2.ZERO
    player_form=0
    player_facing=1.0
    dash_timer=0
    dash_cooldown=0
    invulnerable=0
    attack_timer=0
    rasengan_timer=1.0
    kunai_sequence=0
    melee_combo=-1
    melee_cast.clear()
    melee_64.clear()
    oiroke_cd=12.0
    oiroke_time=0.0
    oiroke_hits.clear()
    kawarimi_fx.clear()
    clone_cooldown=0
    spawn_timer=0
    scroll_count=0
    event_time=0
    transform_pause=0.0
    transform_total=0.0
    transform_target_form=-1
    transform_stage=0
    boss_active=false
    if boss.has("actor") and is_instance_valid(boss["actor"]): boss["actor"].queue_free()
    boss={}
    boss_telegraphs.clear()
    boss_phase_reached = 0
    boss_attack_history.clear()
    quicksand_zones.clear()
    _update_scenery_nodes(true)
    hazard_timer = 8.0
    miniboss_timer = 0.0
    miniboss_spawned = false
    miniboss_next=0
    rune_summoners_spawned=0
    rune_traps.clear()
    rune_hit_timer=0.0
    fuma_cd=0.0
    melee_cd=0.0
    miniboss_active = false
    miniboss_uid = -1
    level=1
    exp_value=0
    exp_needed=16.8
    gacha_active=false
    gacha_revealed=false
    gacha_elapsed=0.0
    gacha_rewards.clear()
    gacha_candidates.clear()
    chest_count=0
    oiroke_cloud_timer=0.0
    oiroke_cast_age=0.0
    voice_last.clear()
    if gacha_sound.playing: gacha_sound.stop()
    if oiroke_puff_player.playing: oiroke_puff_player.stop()
    if normal_music_stream != null: music_player.stream = normal_music_stream
    upgrades.clear()
    for skill in LEGACY_JUTSU.keys(): upgrades[skill]=0
    for skill in JUTSU.keys():upgrades[skill]=0
    burst_remaining=0
    burst_timer=0.0
    rasenshuriken_counter=0
    tornado_timer=0.0
    recovery_kills=0
    stat_kills=0
    stat_exp_collected=0
    tornadoes.clear()
    for e in enemies: e["actor"].queue_free()
    enemies.clear()
    for c in clones: c["actor"].queue_free()
    clones.clear()
    shots.clear()
    drops.clear()
    fx.clear()
    player.set_pack(str(alpha.hero()["pack"]))
    if music_player.stream != null:
        music_player.volume_db = -80.0 if muted else -11.0
        music_player.play()
    queue_redraw()

func choose_character(id:String) -> void:
    if playing:return
    if alpha.choose(id):
        JUTSU=Registry.cards()
        player.set_pack(str(alpha.hero()["pack"]))
        ui_view.hero.set_pack(str(alpha.hero()["pack"]))
        ui_view.queue_redraw()

func _input(event:InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_T and playing and not finished and not form_choice and not gacha_active and not picking and transition_time<0:
            alpha.tree_open=not alpha.tree_open
            ui_view.queue_redraw()
            return
        if alpha.tree_open:
            if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]:
                alpha.tree_tab=int(event.keycode-KEY_1)
            elif event.keycode==KEY_ESCAPE:alpha.tree_open=false
            ui_view.queue_redraw()
            return
        if not playing and event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]:
            choose_character(str(alpha.IDS[int(event.keycode-KEY_1)]))
            return
        if form_choice:
            if event.keycode in [KEY_1,KEY_2]:_choose_form(event.keycode-KEY_1)
            return
        if event.keycode==KEY_ENTER and (not playing or finished):
            _start()
        elif event.keycode==KEY_ESCAPE and playing and not picking and not finished and not gacha_active:
            paused=not paused
            _flash("PAUZA" if paused else "WALKA")
        elif event.keycode==KEY_BACKSPACE and playing and paused:
            return_to_menu()
            return
        elif event.keycode==KEY_SPACE and playing and not finished:
            speed_index=(speed_index+1)%speeds.size()
            _flash("TEMPO: %s" % speed_labels[speed_index])
        elif event.keycode==KEY_X and playing and not picking and not paused and not finished:
            if not gacha_active and transition_time<0:skill_adapter.utility()
        elif event.keycode==KEY_G:
            _toggle_godmode()
        elif event.keycode==KEY_F9 and playing and not finished and not picking and not gacha_active:
            clock=BOSS_TIME
            _begin_duel_transition()
        elif event.keycode==KEY_M:
            muted=not muted
            music_player.volume_db=-80.0 if muted else -10.0
            sfx_player.volume_db=-80.0 if muted else -6.0
            special_sfx_player.volume_db=-80.0 if muted else -5.0
        elif event.keycode==KEY_F:
            _toggle_fx()
        elif gacha_active and gacha_revealed and event.keycode in [KEY_1,KEY_2,KEY_3]:
            _choose_chest_reward(event.keycode-KEY_1)
        elif picking and event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:
            _choose_card(event.keycode-KEY_1)

func return_to_menu() -> void:
    # Full scene restart clears actors, audio players and projectile pools safely.
    var active_hero:String=str(alpha.selected)
    paused=false
    alpha.tree_open=false
    alpha.reset_run()
    alpha.choose(active_hero)
    build.reset()
    var director=get_node_or_null("/root/AudioDirector")
    if director!=null:director.silence()
    get_tree().reload_current_scene()

func _toggle_fx() -> void:
    low_fx=not low_fx

func _toggle_godmode() -> void:
    godmode = not godmode
    if godmode: player_hp = PLAYER_MAX_HP + float(upgrades.get("max_hp",0))*18.0
    _flash("NIEŚMIERTELNOŚĆ WŁĄCZONA" if godmode else "NIEŚMIERTELNOŚĆ WYŁĄCZONA",1.3)

func _process(delta:float) -> void:
    visual_delta = minf(delta,0.06)
    if not playing or finished:
        return
    if alpha.tree_open:
        queue_redraw()
        return
    if transition_time>=0:
        transition_time+=delta
        if transition_time>=2.1:get_tree().change_scene_to_file("res://scenes/boss_duel.tscn")
        queue_redraw();return
    if form_choice:return
    hostile_orb_clock += delta
    if gacha_active:
        _update_gacha(delta)
        _update_hud()
        queue_redraw()
        return
    if transform_pause > 0.0:
        transform_pause = maxf(0.0, transform_pause - delta)
        if player != null:
            player.tick(delta * 0.7)
        _update_fx(delta)
        _update_hud()
        camera.position = player_pos
        queue_redraw()
        if transform_pause <= 0.0 and transform_target_form >= 0:
            _complete_transform(transform_target_form)
        return
    if paused or picking:
        queue_redraw()
        return
    # Test-speed is simulated in fixed 60 Hz steps; 5x cannot skip projectile collision.
    simulation_accumulator=minf(simulation_accumulator+minf(delta,0.06)*speeds[speed_index],0.36)
    var count:int=0
    while simulation_accumulator>=SIMULATION_DT and count<24:
        simulation_accumulator-=SIMULATION_DT
        visual_delta=SIMULATION_DT
        _simulation_step(SIMULATION_DT)
        count+=1
        if paused or picking or gacha_active or form_choice or transition_time>=0 or finished:
            simulation_accumulator=0.0
            break
    queue_redraw()

func _simulation_step(dt:float) -> void:
    clock+=dt
    _update_player(dt)
    build.elapsed=clock
    var due=Forms.due(build,clock)
    if due=="choice":form_choice=true;return
    if due=="second":_transform(2);return
    if build.utility_id=="" and clock>=8:_open_draft("utility");return
    if build.owned().size()<3 and clock>=[18.0,80.0,160.0][build.owned().size()]:_open_draft("new");return
    if miniboss_next<MIDBOSS_TIMES.size() and clock>=MIDBOSS_TIMES[miniboss_next]:
        _spawn_miniboss(miniboss_next)
        miniboss_next+=1
    if not boss_active and clock>=BOSS_TIME:
        if miniboss_active: _remove_miniboss()
        _begin_duel_transition()
        return
    _update_spawns(dt)
    skill_adapter.tick(dt)
    _update_enemies(dt)
    _update_boss_telegraphs(dt)
    _update_projectiles(dt)
    _update_hazards(dt)
    _update_runes(dt)
    _update_drops(dt)
    _update_fx(dt)
    _update_hud()
    _update_scenery_nodes(false)
    camera.position=player_pos
    queue_redraw()
    if player_hp<=0:
        _finish(false)

func _update_player(dt:float) -> void:
    var vel=Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_A): vel.x-=1
    if Input.is_physical_key_pressed(KEY_D): vel.x+=1
    if Input.is_physical_key_pressed(KEY_W): vel.y-=1
    if Input.is_physical_key_pressed(KEY_S): vel.y+=1
    vel=vel.normalized()
    dash_timer=maxf(0.0,dash_timer-dt)
    dash_cooldown=maxf(0.0,dash_cooldown-dt)
    invulnerable=maxf(0.0,invulnerable-dt)
    if Input.is_key_pressed(KEY_SHIFT) and dash_cooldown<=0 and vel.length()>0:
        dash_timer=0.22
        dash_cooldown=maxf(1.7,3.2-float(upgrades["speed"])*0.22)
        invulnerable=0.46
        if build.form_branch=="sage" and build.form_stage==2:
            skill_adapter.counter_time=1.8
            skill_adapter.projectile("frog_kata_counter","wind",player_pos+Vector2(0,-25),vel,520,90,30,1.2,{"pierce":3})
        kawarimi_fx.append({"pos":player_pos,"life":0.68,"max":0.68})
        if int(upgrades.get("kawarimi_echo",0))>0:
            _aoe_damage(player_pos,56.0+12.0*float(upgrades["kawarimi_echo"]),25.0+17.0*float(upgrades["kawarimi_echo"]))
            _add_blast(player_pos,75.0,"smoke_blast")
        _sfx("dash.wav")
    var mul=3.7 if dash_timer>0 else 1.0
    var hazard_mul := 1.0
    for q in quicksand_zones:
        if player_pos.distance_to(q["pos"]) < float(q["radius"]):
            hazard_mul = minf(hazard_mul, 0.68)
    player_vel=vel* (PLAYER_SPEED+float(upgrades["speed"])*7.0 + player_form*5.0)*mul*hazard_mul*alpha.move_multiplier()*(1.16 if alpha.selected=="rock_lee" else 1.0)
    player_pos=_move_scenery(player_pos,player_vel*dt,14.0)
    player.position=player_pos
    if vel.x!=0: player_facing=signf(vel.x)
    player.facing=player_facing
    player.moving=vel.length_squared()>0
    player.dashing = dash_timer > 0.0
    player.tick(visual_delta)
    clone_cooldown=maxf(0.0,clone_cooldown-dt)
    AlphaMelee.tick(self,dt)
    attack_timer-=dt
    if attack_timer<=0:
        if AlphaMelee.uses_melee(alpha.selected):
            AlphaMelee.begin(self)
        else:
            _fire_kunai()
        attack_timer=maxf(0.12,0.54-float(upgrades["kunai_rapid"])*0.07)*TRANSFORM_RATE_BOOST[player_form]*alpha.attack_interval_multiplier()*AlphaAbilities.attack_rate(alpha.selected)

func _transform(form:int) -> void:
    if transform_pause > 0.0:
        return
    transform_target_form = form
    transform_total = 1.45
    transform_pause = transform_total
    transform_stage = form
    invulnerable = 2.5
    player.attack = true
    player.moving = false
    if player.actions.has("100"):
        player.set_action("100")
    _flash("PRZEBUDZENIE CHAKRY",3.0)
    _sfx("transform.mp3")
    _log("transformation begin %d at %.2f" % [form,clock])

func _complete_transform(form:int) -> void:
    player_form=form
    build.form_stage=form
    player.set_pack(build.actor_pack())
    player.attack = false
    invulnerable=2.1
    player_hp=minf(PLAYER_MAX_HP+float(upgrades["max_hp"])*18.0,player_hp+34.0+8.0*form)
    var class_tints={
        "sasuke":Color(1.10,0.81,1.25),"kakashi":Color(0.88,1.13,1.28),
        "rock_lee":Color(0.94,1.24,0.86),"neji":Color(0.95,1.12,1.22),
        "gaara":Color(1.24,1.09,0.84)
    }
    player.form_tint=Color.WHITE if alpha.selected=="naruto" else Color(class_tints.get(alpha.selected,Color.WHITE)).lerp(Color.WHITE,0.22 if form==1 else 0.0)
    _flash(build.form_name(),2.5)
    if fx.size()<MAX_FX:
        fx.append({"pos":player_pos,"life":0.72,"max":0.72,"radius":150.0 + 20.0*form,"kind":"pulse"})
    transform_target_form = -1
    transform_stage = 0
    _log("transformation end %d at %.2f" % [form,clock])

func _flash(txt:String,duration:float=2.0) -> void:
    event_msg=txt
    event_time=duration

func _enemy_actor(pack:String,at:Vector2,tint:Color):
    var actor:=MugenActor.new()
    actor.pack_name=pack
    actor.fallback_color=tint
    actor.position=at
    add_child(actor)
    return actor

func _update_spawns(dt:float) -> void:
    spawn_timer -= dt
    if boss_active: return
    if spawn_timer > 0.0: return
    var wave=SpawnDirector.wave(clock,BOSS_TIME,miniboss_active)
    for i in range(wave.amount):
        if enemies.size()<mini(MAX_ENEMIES,wave.maximum): _spawn_enemy(false)
    spawn_timer=wave.interval
    if clock>92.0 and not boss_active and _sound_ninja_count()<3 and rng.randf()<0.20:
        _spawn_sound_ninja()


func _spawn_enemy(elite:bool) -> void:
    if enemies.size()>=MAX_ENEMIES: return
    var theta=rng.randf_range(0.0,TAU)
    var at=player_pos+Vector2.from_angle(theta)*rng.randf_range(505.0,615.0)
    var pressure:float=clampf(clock/BOSS_TIME,0.0,1.0)
    var kinds=["sound_scythe","sound_pole","sound_mirror","sound_heavy"]
    var kind:String="sound_heavy" if elite else kinds[rng.randi_range(0,3)]
    # First 45 seconds are mostly melee enemies with low HP.
    if not elite and clock<45.0: kind="sound_scythe" if rng.randf()<0.80 else "sound_mirror"
    if not elite and clock<115.0 and kind=="sound_heavy": kind="sound_scythe"
    var ranged=clock>42.0 and (kind=="sound_mirror" or kind=="sound_pole" or kind=="sound_heavy")
    var hp_table={"sound_scythe":49.0,"sound_pole":69.0,"sound_mirror":64.0,"sound_heavy":134.0}
    var speed_table={"sound_scythe":81.0,"sound_pole":60.0,"sound_mirror":52.0,"sound_heavy":41.0}
    var maxhp=float(hp_table[kind])*(1.0+pressure*1.02)
    if elite: maxhp*=4.8
    var actor=_enemy_actor(kind,at,Color("d0bd95"))
    if elite: actor.sprite_scale*=1.42
    enemies.append({"pos":at,"hp":maxhp,"max_hp":maxhp,"actor":actor,"ranged":ranged,
        "kind":kind,"speed":float(speed_table[kind])*(1.0+pressure*0.10),"hit_cd":0.0,
        "missile_cd":rng.randf_range(3.8,6.2),"elite":elite,"stagger":0.0,"bleed":0.0,"bleed_dps":0.0,
        "mini_boss":false,"attack_cd":2.0})

func _hurt_player(amount:float) -> void:
    if alpha!=null:amount*=alpha.guard_multiplier()*(0.90 if alpha.selected=="gaara" else 1.0)
    if godmode or invulnerable>0.0:return
    if int(upgrades.get("survivor_instinct",0))>0 and player_hp < (PLAYER_MAX_HP+float(upgrades["max_hp"])*18.0)*0.34:
        amount *= maxf(0.48,1.0-float(upgrades["survivor_instinct"])*0.23)
    amount=Resolver.mitigated(amount,build)
    if skill_adapter.support_time>0:amount*=0.65
    player_hp=maxf(0.0,player_hp-amount)
    invulnerable=0.86
    _sfx("impact.wav")

func _spawn_miniboss(stage:int=1) -> void:
    if boss_active:return
    miniboss_spawned=true
    miniboss_active=true
    var at:Vector2=player_pos+Vector2(380.0,-170.0)
    var tints=[Color(1.08,0.95,0.44),Color(1.25,0.72,0.67),Color(0.60,0.90,1.20)]
    var sizes=[1.56,1.82,1.97]
    var actor=_enemy_actor("sound_heavy",at,tints[stage])
    actor.sprite_scale*=sizes[stage]
    actor.form_tint=tints[stage]
    var hp:float=clampf(_estimated_current_dps()*(27.0+float(stage)*5.0),700.0,5200.0)
    miniboss_uid=actor.get_instance_id()
    enemies.append({"pos":at,"hp":hp,"max_hp":hp,"actor":actor,"ranged":true,
        "kind":"sound_heavy","speed":60.0+stage*7.0,"hit_cd":0.0,"missile_cd":2.1,"elite":true,
        "stagger":0.0,"bleed":0.0,"bleed_dps":0.0,"mini_boss":true,"mini_stage":stage})
    invulnerable=maxf(invulnerable,1.2)
    _flash("! WARNING ! " + MIDBOSS_NAMES[stage],4.0)
    _set_miniboss_music(true)
    _sfx("boss.wav")

func _remove_miniboss() -> void:
    for e in enemies.duplicate():
        if e.get("mini_boss",false):
            e["actor"].queue_free()
            enemies.erase(e)
    miniboss_active=false
    miniboss_uid=-1
    _set_miniboss_music(false)

func _set_miniboss_music(active:bool) -> void:
    if active and boss_music_stream!=null:
        music_player.stop()
        music_player.stream=boss_music_stream
        music_player.volume_db=-14.0 if not muted else -80.0
        music_player.play()
    elif not active and normal_music_stream!=null:
        music_player.stop()
        music_player.stream=normal_music_stream
        music_player.volume_db=-11.0 if not muted else -80.0
        music_player.play()

func _estimated_current_dps() -> float:
    var kunai:float = (21.5*TRANSFORM_DAMAGE_BOOST[player_form])*(1.0+float(upgrades["kunai_twin"])*0.77+float(upgrades.get("kunai_fan",0))*0.55)
    var cd:float=maxf(0.15,0.54-float(upgrades["kunai_rapid"])*0.07)*TRANSFORM_RATE_BOOST[player_form]
    var output:float=kunai*0.58/cd
    if int(upgrades["rasengan"])>0:
        output+=(37.0+float(upgrades["oodama"])*8.0)*TRANSFORM_DAMAGE_BOOST[player_form]*0.54/maxf(1.0,3.5-float(upgrades["chakra_flow"])*0.3)
    output+=float(upgrades["clones"])*5.0+float(upgrades["rasenshuriken"])*9.0
    var fuma:int=int(upgrades.get("fuma_shuriken",0))
    if fuma>0:
        output+=(27.0+13.0*fuma)*(1.0+float(upgrades.get("fuma_boomerang",0))*0.37)*0.70/maxf(1.55,4.4-0.65*fuma)
    var melee:int=int(upgrades.get("melee_rasengan",0))
    if melee>0:
        output+=(40.0+19.0*melee)*(1.0+float(upgrades.get("melee_combo",0))*0.70)*0.5/maxf(1.7,5.25-melee*0.68)
    var lure:int=int(upgrades.get("oiroke",0))
    if lure>0:
        output+=float(lure)*5.5+float(upgrades.get("oiroke_pressure",0))*4.5
    output+=float(upgrades.get("naruto_rendan",0))*4.8
    return output

func _prop_for_cell(xx:int,yy:int) -> Dictionary:
    var hash_value=posmod(xx*23819+yy*47149,7919)
    if hash_value%5!=0 or prop_textures.is_empty():return {}
    var index=hash_value%prop_textures.size()
    var place=Vector2(float(xx)*190.0+float(hash_value%69),float(yy)*190.0+float(hash_value%57))
    if place.length_squared()<210.0*210.0:return {}
    return {"pos":place,"index":index,"texture":prop_textures[index]}

func _update_scenery_nodes(force:bool=false) -> void:
    if scenery_layer==null:return
    scenery_scan_time-=visual_delta
    if not force and scenery_scan_time>0.0:return
    scenery_scan_time=0.33
    var current:Dictionary={}
    var cell_x=int(floor(player_pos.x/190.0))
    var cell_y=int(floor(player_pos.y/190.0))
    for yy in range(cell_y-4,cell_y+5):
        for xx in range(cell_x-5,cell_x+6):
            var key="%d:%d" % [xx,yy]
            var entry=_prop_for_cell(xx,yy)
            if entry.is_empty():continue
            current[key]=true
            var node:Sprite2D
            if scenery_nodes.has(key):node=scenery_nodes[key]
            else:
                node=Sprite2D.new()
                node.centered=false
                node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
                node.texture=entry["texture"]
                node.scale=Vector2.ONE*1.8
                scenery_layer.add_child(node)
                scenery_nodes[key]=node
            var tex:Texture2D=entry["texture"]
            var at:Vector2=entry["pos"]
            node.position=at-Vector2(tex.get_width()*0.9,tex.get_height()*1.8)
            node.z_index=clampi(int(at.y-camera.position.y)+1000,1,2000)
    for key in scenery_nodes.keys():
        if not current.has(key):
            scenery_nodes[key].queue_free()
            scenery_nodes.erase(key)

func _scenery_radius(index:int) -> float:
    # Collision at the trunk/rock base, not around the entire canopy.
    return 24.0 if index in [0,1,2,3] else 16.0

func _move_scenery(origin:Vector2, movement:Vector2, body_radius:float) -> Vector2:
    # Substeps prevent dash tunnelling and radial projection naturally slides on trunks.
    var steps=maxi(1,int(ceil(movement.length()/15.0)))
    var pos=origin
    for step in range(steps):
        var attempt=pos+movement/float(steps)
        var xx=int(floor(attempt.x/190.0))
        var yy=int(floor(attempt.y/190.0))
        for y in range(yy-1,yy+2):
            for x in range(xx-1,xx+2):
                var entry=_prop_for_cell(x,y)
                if entry.is_empty():continue
                var block:Vector2=entry["pos"]
                var sep=attempt-block
                var needed=body_radius+_scenery_radius(int(entry["index"]))
                if sep.length_squared()<needed*needed:
                    var normal=sep.normalized() if sep.length_squared()>0.001 else Vector2.RIGHT
                    attempt=block+normal*needed
        pos=attempt
    return pos

func _estimated_dps() -> float:
    var amount := 1.0 + float(upgrades.get("multishot",0))*0.75
    var damage := 37.0 * (1.0 + float(upgrades.get("oodama",0))*0.22) * TRANSFORM_DAMAGE_BOOST[2]
    var delay := maxf(1.4,3.5 - float(upgrades.get("chakra_flow",0))*0.30)*TRANSFORM_RATE_BOOST[2]
    var rendan := 1.0 + float(upgrades.get("rasenrendan",0))*0.16
    var clone_damage := float(upgrades.get("clones",0))*8.0
    var aoe_damage := float(upgrades.get("rasenshuriken",0))*19.0 + float(upgrades.get("rasenornado",0))*18.0
    # Approximate useful contact DPS, not theoretical point-blank maximum.
    var kunai_dps := (1.0 + float(upgrades.get("kunai_twin",0)))*(12.5*TRANSFORM_DAMAGE_BOOST[2])/maxf(0.18,0.71-float(upgrades.get("kunai_rapid",0))*0.09)*0.42
    return kunai_dps + (amount * damage / delay * rendan * 0.52 if upgrades.get("rasengan",0)>0 else 0.0) + clone_damage + aoe_damage

func _spawn_boss() -> void:
    boss_active=true
    for e in enemies:
        e["actor"].queue_free()
    enemies.clear()
    boss_telegraphs.clear()
    # Previous ranged shots are removed at the arena transition.
    for sh in shots.duplicate():
        if sh.get("hostile",false): shots.erase(sh)
    var at=player_pos+Vector2(360,-180)
    var actor = _enemy_actor("sasori",at,Color("bd253f"))
    actor.sprite_scale = maxf(actor.sprite_scale,1.62)
    var dynamic_hp := clampf(_estimated_current_dps()*135.0,9800.0,43000.0)
    boss={"pos":at,"hp":dynamic_hp,"max_hp":dynamic_hp,"actor":actor,
          "attack_cd":1.9,"phase":1,"wave_cd":4.0,"attack_index":0,"phase_pause":1.25,
          "phase2_pool":maxf(6500.0,dynamic_hp*0.82),"phase2_max":maxf(6500.0,dynamic_hp*0.82),
          "damage_window":0.0,"damage_acc":0.0}
    boss_phase_reached=1
    _flash("AKATSUKI: SASORI  /  THE RED SAND",4.3)
    _sfx("boss.wav")
    _log("Sasori spawned at %.1f: HP %.0f / estimated current DPS %.0f" % [clock,dynamic_hp,_estimated_current_dps()])

func _closest_target(at:Vector2,max_distance:float)->Dictionary:
    var best:Dictionary={}
    var dist=max_distance*max_distance
    for e in enemies:
        var d=at.distance_squared_to(e["pos"])
        if d<dist:
            dist=d
            best=e
    if boss_active:
        var d=at.distance_squared_to(boss["pos"])
        if d<dist: best=boss
    return best

func _alpha_proc() -> void:
    var tree:int=alpha.current_signature()
    if tree<0:return
    if alpha.selected=="neji" and tree==1 and alpha.special_unlocked(1):
        if AlphaMelee.start_palms(self,alpha.apex_unlocked(1)):
            return
    var fork:int=-1 if alpha.invested(tree,1) else 1 if alpha.invested(tree,2) else 0
    var focus_power:float=alpha.damage_multiplier()*(1.0+0.035*float(alpha.count_focus(tree)))
    if AlphaAbilities.activate(self,alpha.selected,tree,alpha.apex_unlocked(tree),focus_power,fork):
        _flash("%s  /  %s" % [alpha.hero()["name"],alpha.tree_name(tree)],1.05)

func _fire_kunai() -> void:
    if shots.size()>MAX_SHOTS-12: return
    var target := _closest_target(player_pos,670.0)
    if target.is_empty(): return
    var aim:Vector2=(target["pos"]-player_pos).normalized()
    _sfx("throw.wav")
    kunai_sequence+=1
    var count := mini(11,1+int(upgrades["kunai_twin"])+int(upgrades.get("kunai_fan",0))*2+(1 if player_form==2 and kunai_sequence%3==0 else 0)+alpha.additional_projectiles())
    var explosive := int(upgrades["kunai_explosive"])>0 and kunai_sequence%maxi(3,7-int(upgrades["kunai_explosive"])*2)==0
    var tint := Color.WHITE if player_form==0 else Color(1.0,0.4,0.42) if player_form==1 else Color(1.0,0.7,0.23)
    match alpha.selected:
        "sasuke":tint=Color("ff673f")
        "kakashi":tint=Color("81dfff")
        "rock_lee":tint=Color("91e178")
        "neji":tint=Color("e7d9ff")
        "gaara":tint=Color("d6a269")
    if alpha.proc_ready():_alpha_proc()
    AlphaAbilities.basic_burst(self,alpha.selected,kunai_sequence)

    for i in range(count):
        var heading := aim.rotated((float(i)-float(count-1)*0.5)*0.105)
        shots.append({"pos":player_pos+Vector2(0,-23),"dir":heading,"life":1.6,
            "damage":(21.5+float(upgrades["kunai_explosive"])*2.0)*TRANSFORM_DAMAGE_BOOST[player_form]*alpha.damage_multiplier()*(1.10 if alpha.selected=="sasuke" else 1.0),
            "size":1.0,"kind":"kunai_explosive" if explosive and i==0 else "kunai",
            "tint":tint,"pierced":0,"hit":{},"velocity":540.0,"returning":int(upgrades.get("kunai_return",0))>0,"returned":false})

func _fire_rasengan(rapid:bool=false) -> void:
    if shots.size()>MAX_SHOTS-12: return
    var target=_closest_target(player_pos,670.0)
    if target.is_empty():return
    var base_dir:Vector2=(target["pos"]-player_pos).normalized()
    var amount=1+int(upgrades["multishot"])
    if player_form==2 and upgrades["multishot"] < 3:
        amount += 1
    rasenshuriken_counter+=1 if not rapid else 0
    var shuriken_on=not rapid and int(upgrades["rasenshuriken"])>0 and rasenshuriken_counter%maxi(3,7-int(upgrades["rasenshuriken"])*2)==0
    for i in range(amount):
        var rot=(float(i)-float(amount-1)/2.0)*0.20
        var angle=base_dir.rotated(rot)
        var big=(1.0+float(upgrades["oodama"])*0.26)*TRANSFORM_SHOT_SCALE[player_form]
        var kind="shuriken" if shuriken_on and i==0 else "rasengan"
        var chance=0.04+0.055*float(upgrades["crit"])
        var critical=rng.randf()<chance
        var damage=37.0*(1.0+float(upgrades["oodama"])*0.22)*TRANSFORM_DAMAGE_BOOST[player_form]
        damage *= 1.0+float(upgrades.get("chakra_overload",0))*0.19
        if kind=="shuriken":damage*=1.55
        if rapid:damage*=0.63
        if critical:damage*=1.8
        var shot_tint := Color.WHITE if player_form==0 else Color(1.0,0.44,0.38,1.0) if player_form==1 else Color(1.0,0.67,0.21,1.0)
        shots.append({"pos":player_pos+Vector2(0,-28),"dir":angle,
            "life":1.32,"damage":damage,"size":big*(1.18 if kind=="shuriken" else 1.0),
            "kind":kind,"critical":critical,"pierced":0,"hit":{},"tint":shot_tint})
    if int(upgrades.get("chakra_surge",0))>0 and rasenshuriken_counter%5==0 and not rapid:
        _aoe_damage(player_pos,128.0,45.0*TRANSFORM_DAMAGE_BOOST[player_form])
        _add_blast(player_pos,128.0,"chakra_blast")
    _sfx("rasengan.wav")

func _fire_fuma_shuriken() -> void:
    var target=_closest_target(player_pos,680.0)
    if target.is_empty() or shots.size()>MAX_SHOTS-10:return
    var direction:Vector2=(target["pos"]-player_pos).normalized()
    var count:int=1 if int(upgrades.get("fuma_shuriken",0))<3 else 2
    for i in range(count):
        shots.append({"pos":player_pos+Vector2(0,-26),"dir":direction.rotated((i-(count-1)*0.5)*0.19),
            "life":1.35,"damage":(27.0+float(upgrades["fuma_shuriken"])*13.0)*TRANSFORM_DAMAGE_BOOST[player_form],
            "size":2.9,"kind":"fuma","pierced":0,"hit":{},"velocity":440.0,
            "returning":int(upgrades.get("fuma_boomerang",0))>0,"returned":false})

func _melee_rasengan_burst() -> void:
    # Clone-driven Naruto melee combo, Naruto's Rasengan effects + short-range impact.
    var lv=float(upgrades.get("melee_rasengan",0))
    var power=(40.0+lv*19.0)*TRANSFORM_DAMAGE_BOOST[player_form]
    for i in range(1+int(upgrades.get("melee_combo",0))):
        var direction=Vector2.from_angle(TAU*float(i)/maxf(1.0,1.0+float(upgrades.get("melee_combo",0))))
        var center=player_pos+direction*44.0
        _aoe_damage(center,71.0+lv*13.0,power)
        if fx.size()<MAX_FX:fx.append({"pos":center,"life":0.53,"max":0.53,"radius":84.0,"kind":"melee_rasengan"})
    _sfx("rasengan.wav")

func _sound_ninja_count() -> int:
    var count=0
    for e in enemies:
        if e.get("summoner",false):count+=1
    return count

func _spawn_sound_ninja() -> void:
    if _sound_ninja_count()>=3 or enemies.size()>=MAX_ENEMIES:return
    var a=player_pos+Vector2.from_angle(rng.randf_range(0.0,TAU))*rng.randf_range(385.0,500.0)
    var actor=_enemy_actor("sound_mirror",a,Color(0.83,0.83,1.0))
    actor.visible=false
    # The renderer overlays his exact original Sound Ninja sprite; this actor owns shadow/position.
    var health=83.0*(1.0+clampf(clock/BOSS_TIME,0.0,1.0))
    enemies.append({"pos":a,"hp":health,"max_hp":health,"actor":actor,"kind":"sound_mirror",
        "speed":44.0,"ranged":false,"hit_cd":0.0,"missile_cd":4.5,"elite":false,
        "stagger":0.0,"bleed":0.0,"bleed_dps":0.0,"mini_boss":false,"summoner":true})

func _update_runes(dt:float) -> void:
    rune_hit_timer=maxf(0.0,rune_hit_timer-dt)
    for r in rune_traps.duplicate():
        r["age"]+=dt
        r["life"]-=dt
        if float(r["life"])<=0.0:
            rune_traps.erase(r)
            continue
        if float(r["age"])<1.35:continue # visual warning > 1 sec before damage
        if player_pos.distance_squared_to(r["pos"])<float(r["radius"])*float(r["radius"]):
            if rune_hit_timer<=0.0 and not godmode and invulnerable<=0:
                _hurt_player(4.0+float(clock)/210.0)
                rune_hit_timer=0.69
                scenery_hit_flash=0.26
                _flash("! PIECZĘĆ CHAKRY: UCIEKAJ ZE STREFY !",0.75)

func _aoe_damage(at:Vector2, radius:float, damage:float) -> void:
    for e in enemies.duplicate():
        if enemies.has(e) and at.distance_squared_to(e["pos"])<=radius*radius:
            _damage_target(e,damage)
    if boss_active and boss.get("hp",0.0)>0.0 and at.distance_squared_to(boss["pos"])<=radius*radius:
        _damage_target(boss,damage)

func _add_blast(at:Vector2, radius:float, kind:String="rasen_blast") -> void:
    if fx.size()<MAX_FX:
        fx.append({"pos":at,"life":0.72,"max":0.72,"radius":radius,"kind":kind,"twist":rng.randf_range(0.0,TAU)})

func _projectile_impact(shot:Dictionary,at:Vector2) -> void:
    _sfx("heavy_hit.wav" if shot.get("kind","")=="kunai_explosive" else "impact.wav")
    if shot.get("kind","")=="kunai_explosive":
        var radius=49.0+float(upgrades["kunai_explosive"])*15.0
        _aoe_damage(at,radius,float(shot["damage"])*0.68)
        _add_blast(at,radius,"smoke_blast")
        if int(upgrades.get("kunai_chain",0))>0:
            var target=_closest_target(at+Vector2(30,0),radius+95.0)
            if not target.is_empty() and target["pos"].distance_to(at)>23.0:
                _aoe_damage(target["pos"],34.0+float(upgrades["kunai_chain"])*12.0,float(shot["damage"])*0.48)
                _add_blast(target["pos"],60.0,"smoke_blast")
    if shot.get("kind","")=="shuriken":
        var storm:float=float(upgrades.get("shuriken_storm",0))
        var radius=104.0+float(upgrades["rasenshuriken"])*34.0+storm*27.0+(37.0 if int(upgrades["sage_focus"])>0 else 0.0)
        _aoe_damage(at,radius,float(shot["damage"])*(0.85+storm*0.16))
        _add_blast(at,radius,"futon_blast")
        if storm>0.0:
            _aoe_damage(at,radius*1.23,float(shot["damage"])*0.23*storm)
        _sfx("explosion_v8.wav")
    elif shot.get("kind","")=="rasengan":
        if int(upgrades["oodama"])>0:
            _add_blast(at,32.0+int(upgrades["oodama"])*12.0,"chakra_blast")
        if int(upgrades.get("futon_edge",0))>0:
            var edge:float=float(upgrades["futon_edge"])
            _aoe_damage(at,44.0+edge*26.0,11.0+edge*13.0)
            _add_blast(at,45.0+edge*17.0,"futon_blast")
    if shot.get("critical",false) and fx.size()<MAX_FX:
        fx.append({"pos":at,"life":0.35,"max":0.35,"radius":29.0,"kind":"critical"})

func _summon_tornadoes() -> void:
    for i in range(mini(4,int(upgrades["rasenornado"]))):
        var angle=float(i)*TAU/maxi(1,int(upgrades["rasenornado"]))
        var at=player_pos+Vector2.from_angle(angle)*70.0
        tornadoes.append({"pos":at,"life":4.4,"tick":0.03,"orbit":angle})
    _flash("FUUTON: RASENORNADO",1.3)
    _sfx("transform.wav")

func _update_tornadoes(dt:float) -> void:
    for t in tornadoes.duplicate():
        t["life"]-=dt
        if float(t["life"])<=0.0:
            tornadoes.erase(t)
            continue
        var pos:Vector2=t["pos"]
        var target=_closest_target(pos,510.0)
        if not target.is_empty():
            pos+=(target["pos"]-pos).normalized()*122.0*dt
        else:
            t["orbit"]+=dt*1.8
            var at=player_pos+Vector2.from_angle(t["orbit"])*105.0
            pos=pos.move_toward(at,130.0*dt)
        t["pos"]=pos
        for e in enemies:
            if pos.distance_squared_to(e["pos"])<80.0*80.0:
                e["pos"]+=(pos-e["pos"]).normalized()*dt*25.0
        t["tick"]-=dt
        if t["tick"]<=0:
            var radius=61.0+(22.0 if int(upgrades["sage_focus"])>0 else 0.0)
            _aoe_damage(pos,radius,13.0+float(upgrades["rasenornado"])*8.0)
            t["tick"]=0.29

func _damage_target(target:Dictionary,damage:float) -> void:
    if alpha!=null and alpha.selected!="naruto":damage*=1.05
    if target.has("actor"): target["actor"].hit_flash = 0.13
    if target.is_empty() or not target.has("hp"):return
    if target==boss and boss.get("phase_pause",0.0) > 0.0:
        return
    if target==boss:
        # Per-hit safeguard against multishot AoE deleting both phases in one frame.
        var cap:float=float(boss.get("max_hp",9800.0))*0.035
        target["hp"]-=minf(damage,cap)
        if target["hp"]<=0.0 and int(boss.get("phase",1))==1:
            _sasori_phase_two()
            return
    else:
        target["hp"]-=damage
    var at:Vector2=target["pos"]
    if fx.size()<MAX_FX and not low_fx:
        fx.append({"pos":at,"life":0.23,"max":0.23,"kind":"impact"})
    if target["hp"]<=0:
        if target==boss:
            boss["hp"]=0.0
            _finish(true)
        else:
            _kill_enemy(target)

func _kill_enemy(e:Dictionary) -> void:
    if not enemies.has(e):return
    var at:Vector2=e["pos"]
    var elite:bool=e["elite"]
    var mini:bool=e.get("mini_boss",false)
    e["actor"].queue_free()
    enemies.erase(e)
    recovery_kills+=1
    stat_kills+=1
    if mini:
        miniboss_active=false
        for enemy in enemies:
            if enemy.get("mini_boss",false):miniboss_active=true
        miniboss_uid=-1
        if not miniboss_active:_set_miniboss_music(false)
        _flash("STRAŻNIK POKONANY! RAMEN + SKRZYNIA!",2.2)
        _add_blast(at,148.0)
        _sfx("explosion_v8.wav")
    if int(upgrades["regeneration"])>0 and recovery_kills>=20-int(upgrades["regeneration"])*4:
        recovery_kills=0
        player_hp=minf(PLAYER_MAX_HP+float(upgrades["max_hp"])*18.0,player_hp+8.0+float(upgrades["regeneration"])*5.0)
        if fx.size()<MAX_FX:fx.append({"pos":player_pos,"life":0.6,"max":0.6,"radius":38.0,"kind":"heal"})
    if mini:
        while drops.size()>MAX_DROPS-3:
            var oldest_xp=-1
            for i in range(drops.size()):
                if drops[i].type=="xp":oldest_xp=i;break
            drops.remove_at(oldest_xp if oldest_xp>=0 else 0)
    if drops.size()<MAX_DROPS:
        drops.append({"pos":at,"type":"xp","value":17.0 if mini else 11.0 if elite else 4.5})
        if mini:
            drops.append({"pos":at+Vector2(0,-18),"type":"chest","value":1.0})
            drops.append({"pos":at+Vector2(24,5),"type":"ramen","value":40.0})
        elif (clock>55.0 and rng.randf()<0.009) or (elite and rng.randf()<0.80):
            drops.append({"pos":at+Vector2(0,-13),"type":"chest","value":1.0})
        if rng.randf()<0.017: drops.append({"pos":at+Vector2(12,0),"type":"heal","value":24.0})
        if rng.randf()<0.014: drops.append({"pos":at+Vector2(-10,-8),"type":"scroll","value":1.0})

func _update_enemies(dt:float) -> void:
    for e in enemies.duplicate():
        if not enemies.has(e):continue
        var at:Vector2=e["pos"]
        if at.distance_squared_to(player_pos)>1450.0*1450.0 and not e.get("mini_boss",false):
            e["actor"].queue_free()
            enemies.erase(e)
            continue
        if float(e.get("bleed",0.0))>0.0:
            e["bleed"]=maxf(0.0,float(e["bleed"])-dt)
            _damage_target(e,float(e.get("bleed_dps",0.0))*dt)
            if not enemies.has(e): continue
        var target:Vector2=skill_adapter.decoy_pos if skill_adapter.decoy_time>0 else player_pos
        for c in clones:
            if c["pos"].distance_squared_to(at)<target.distance_squared_to(at):target=c["pos"]
        var direction:Vector2=(target-at).normalized()
        var kind:String=e["kind"]
        var distance=at.distance_to(target)
        var mini:bool=e.get("mini_boss",false)
        var separation=135.0 if kind=="sound_mirror" else 100.0 if kind=="sound_pole" else 0.0
        if e.get("summoner",false):separation=290.0
        if mini:separation=130.0
        e["stagger"]=maxf(0.0,float(e["stagger"])-dt)
        if distance>separation and float(e["stagger"])<=0:
            at=_move_scenery(at,direction*float(e["speed"])*dt*(0.62 if float(e.get("slowed_until",0))>skill_adapter.clock else 1.0),18.0 if mini else 11.5)
        e["pos"]=at
        e["actor"].position=at
        e["actor"].moving=distance>separation and float(e["stagger"])<=0
        e["actor"].attack=false
        if absf(direction.x)>0.07:e["actor"].facing=signf(direction.x)
        e["actor"].tick(visual_delta)
        e["hit_cd"]=maxf(0.0,float(e["hit_cd"])-dt)
        if at.distance_squared_to(player_pos)<(1150.0 if mini else 880.0) and e["hit_cd"]<=0.0 and invulnerable<=0.0 and not godmode:
            _hurt_player(12.0 if mini else 8.0 if kind=="sound_heavy" else 5.5)
            e["hit_cd"]=1.45
        for c in clones.duplicate():
            if at.distance_squared_to(c["pos"])<760: c["hp"]-=9.0*dt
        e["missile_cd"]-=dt
        if e.get("summoner",false):
            if e["missile_cd"]<=0.0 and distance<680.0 and rune_traps.size()<9:
                var rune_at=player_pos + player_vel.normalized()*54.0
                rune_traps.append({"pos":rune_at,"age":0.0,"life":5.9,"radius":55.0,"wet":false})
                e["missile_cd"]=4.7
                e["actor"].hit_flash=0.12
            continue
        if e["missile_cd"]>0.0 or distance>475.0 or shots.size()>=MAX_SHOTS-18:continue
        if not e.get("ranged",false) and not mini:continue
        e["actor"].pose_action="200"
        e["actor"].pose_time=0.45
        if mini:
            var stage=int(e.get("mini_stage",1))
            if stage==2:
                _boss_telegraph("blast",player_pos+player_vel.normalized()*25.0,Vector2.RIGHT,1.25,115.0,115.0,11.5)
                _boss_fan(at,7,"suiton",7.5,225.0,0.15)
                _flash("SUITON: WODNY GRAD",1.0)
                e["missile_cd"]=4.0
            elif stage==0:
                _boss_fan(at,5,"sand",7.0,175.0,0.20)
                _flash("PIASEK: IGŁY",1.0)
                e["missile_cd"]=5.2
            elif int(clock*0.6)%2==0:
                _boss_fan(at,5,"sand",7.0,182.0,0.22)
                _flash("UWAGA: ŻELAZNY GRAD",1.05)
            else:
                _boss_telegraph("blast",player_pos,Vector2.RIGHT,1.4,125.0,125.0,12.0)
                _flash("UWAGA: ATAK OBSZAROWY",1.10)
            if stage==1:e["missile_cd"]=4.8
        elif kind=="sound_mirror":
            for offs in [-0.11,0.11]:_enemy_shot(at,direction.rotated(offs),"small_shuriken",6.0,195.0,2.6)
            e["missile_cd"]=6.0
        elif kind=="sound_pole":
            _enemy_shot(at,direction,"projectile_dart",6.5,220.0,2.5)
            e["missile_cd"]=5.7
        elif kind=="sound_heavy":
            for i in range(4):
                _enemy_shot(at,Vector2.from_angle(float(i)*TAU/4.0),"chakra_bomb",7.5,152.0,2.9)
            e["missile_cd"]=7.1
        else:e["missile_cd"]=6.5
    if boss_active and boss.get("hp",0.0)>0.0:_update_boss(dt)

func _enemy_shot(at:Vector2, direction:Vector2, art:String, damage:float, velocity:float, ttl:float)->void:
    if shots.size()>=MAX_SHOTS-6:return
    shots.append({"pos":at+Vector2(0,-22),"dir":direction.normalized(),"life":ttl,"damage":damage,
        "size":0.8,"hostile":true,"item_vfx":art,"velocity":velocity,"hit":{}})

func _boss_shot(origin:Vector2, heading:Vector2, art:String, size:float, damage:float, speed:float, ttl:float=3.6) -> void:
    if shots.size() >= MAX_SHOTS - 4:
        return
    shots.append({"pos":origin,"dir":heading.normalized(),"life":ttl,"damage":damage,
        "size":size,"hostile":true,"vfx":art,"velocity":speed,"hit":{}})

func _boss_ring(at:Vector2, count:int, art:String, damage:float, speed:float, rotation:float=0.0) -> void:
    for i in range(count):
        var heading=Vector2.from_angle(rotation + TAU * float(i)/maxf(1.0,float(count)))
        _boss_shot(at,heading,art,0.84,damage,speed)

func _boss_fan(at:Vector2,count:int,art:String,damage:float,speed:float,width:float) -> void:
    var aim=(player_pos-at).normalized()
    for i in range(count):
        var offset=(float(i)-float(count-1)/2.0)*width
        _boss_shot(at,aim.rotated(offset),art,0.78,damage,speed)

func _boss_telegraph(kind:String,origin:Vector2,heading:Vector2,windup:float,length:float,width:float,damage:float) -> void:
    boss_telegraphs.append({"kind":kind,"pos":origin,"dir":heading.normalized(),
        "windup":windup,"duration":windup,"length":length,"width":width,"damage":damage})

func _boss_attack(phase:int) -> void:
    var at:Vector2=boss["pos"]
    var aim:Vector2=(player_pos-at).normalized()
    var index:int=boss["attack_index"]
    boss["attack_index"]=index+1
    var actor=boss["actor"]
    if phase==1:
        actor.pose_action="200" if index%2==0 else "203"
        actor.pose_time=0.68
        match index%3:
            0:
                _boss_fan(at,11,"senbon",9.0,256.0,0.102)
                boss_attack_history.append("P1 Hiruko poisoned senbon spread")
                _flash("HIRUKO: ZATRUTE SENBONY",1.1)
            1:
                _boss_telegraph("sand_lane",at,aim,1.25,690.0,92.0,13.0)
                boss_attack_history.append("P1 Hiruko tail sweep")
                _flash("HIRUKO: SKORPIONI OGON",1.1)
            2:
                _boss_ring(at,13,"chakra",8.0,187.0,float(index)*0.4)
                boss_attack_history.append("P1 black chakra spheres")
                _flash("HIRUKO: CZARNE KULE CHAKRY",1.1)
        boss["attack_cd"]=2.4
    else:
        actor.pose_action="3000" if index%2==0 else "200"
        actor.pose_time=1.0
        match index%5:
            0:
                _boss_telegraph("sand_lane",at,aim,1.45,770.0,110.0,16.0)
                boss_attack_history.append("P2 Satetsu iron sand lance")
                _flash("SATETSU: ŻELAZNA WŁÓCZNIA",1.25)
            1:
                _boss_ring(at,17,"sand",9.8,207.0,float(index)*0.32)
                boss_attack_history.append("P2 iron sand drizzle")
                _flash("SATETSU: KAIHŌ",1.25)
            2:
                _boss_telegraph("poison_pool",player_pos+player_vel.normalized()*55.0,Vector2.RIGHT,1.45,150.0,150.0,12.5)
                _boss_fan(at,9,"senbon",9.0,293.0,0.12)
                boss_attack_history.append("P2 poison sand + needles")
                _flash("SASORI: TRUCIZNA!",1.25)
            3:
                _boss_ring(at,17,"chakra",11.0,231.0,float(index)*0.35)
                _boss_telegraph("blast",player_pos,Vector2.RIGHT,1.55,120.0,120.0,12.0)
                boss_attack_history.append("P2 chakra black spheres and seal")
                _flash("OSTRZEŻENIE: CZAKRA I PIECZĘĆ",1.25)
            4:
                _boss_telegraph("sand_lane",at,aim.rotated(-0.38),1.5,740.0,95.0,15.0)
                _boss_telegraph("sand_lane",at,aim.rotated(0.38),1.5,740.0,95.0,15.0)
                boss_attack_history.append("P2 iron sand crossfire")
                _flash("SATETSU: KRZYŻOWY OGIEŃ",1.4)
        boss["attack_cd"]=2.30
    _sfx("boss.wav")

func _sasori_phase_two() -> void:
    boss["hp"]=float(boss["phase2_pool"])
    boss["max_hp"]=float(boss["phase2_max"])
    boss["phase"]=2
    boss_phase_reached=2
    boss["phase_pause"]=2.3
    boss["attack_cd"]=3.0
    boss["attack_index"]=0
    boss_telegraphs.clear()
    for sh in shots.duplicate():
        if sh.get("hostile",false):shots.erase(sh)
    boss["actor"].pose_action="3000"
    boss["actor"].pose_time=2.15
    boss["actor"].sprite_scale=1.95
    boss["actor"].form_tint=Color(1.13,0.87,0.87)
    _flash("FAZA II: KUKŁA TRZECIEGO KAZEKAGE!",3.0)
    _add_blast(boss["pos"],175.0,"sand_blast")
    invulnerable=maxf(invulnerable,2.1)
    _sfx("transform.mp3")
    _log("Sasori phase 2: separate HP pool %.1f" % boss["hp"])

func _update_boss(dt:float) -> void:
    if boss.is_empty() or boss.get("hp",0.0)<=0.0:return
    var at:Vector2=boss["pos"]
    var dir=(player_pos-at).normalized()
    var phase=int(boss["phase"])
    if boss["phase_pause"]>0:
        boss["phase_pause"]-=dt
    else:
        var dist=at.distance_to(player_pos)
        if dist>185.0: at+=dir*(62.0+phase*9.0)*dt
        elif dist<125.0: at-=dir*55.0*dt
    boss["pos"]=at
    boss["actor"].position=at
    boss["actor"].moving=boss["phase_pause"]<=0.0
    boss["actor"].facing=signf(dir.x) if dir.x!=0 else 1.0
    boss["actor"].tick(visual_delta)
    boss["attack_cd"]-=dt
    if boss["attack_cd"]<=0 and boss["phase_pause"]<=0:_boss_attack(phase)

func _update_boss_telegraphs(dt:float) -> void:
    for h in boss_telegraphs.duplicate():
        h["windup"]-=dt
        if h["windup"]>0:continue
        var at:Vector2=h["pos"]
        if h["kind"]=="sand_lane":
            var start:Vector2=at
            var ending:Vector2=at+(h["dir"] as Vector2)*float(h["length"])
            var closest=Geometry2D.get_closest_point_to_segment(player_pos,start,ending)
            if closest.distance_to(player_pos)<float(h["width"])*0.5 and invulnerable<=0 and not godmode:
                _hurt_player(float(h["damage"]))
            for j in range(6):
                _boss_shot(start + (ending-start)*float(j)/8.0, h["dir"],"sand",1.15,9.0,254.0,1.4)
        else:
            if player_pos.distance_to(at)<float(h["width"])*0.5 and invulnerable<=0 and not godmode:
                _hurt_player(float(h["damage"]))
            if h["kind"]=="blast":
                _boss_ring(at,8,"blast",12.0,220.0)
            else:
                _boss_ring(at,10,"poison",10.0,195.0)
        boss_telegraphs.erase(h)
        _sfx("impact.wav")


func _update_projectiles(dt:float) -> void:
    for shot in shots.duplicate():
        if not shots.has(shot):continue
        shot["life"]-=dt
        var hostile:bool=shot.get("hostile",false)
        var travel:float=float(shot.get("velocity",205.0)) if hostile else float(shot.get("velocity",365.0+player_form*43.0))
        var previous:Vector2=shot["pos"]
        shot["pos"]+=shot["dir"]*travel*dt
        if shot["life"]<=0.0:
            if shot.get("kind","")=="shuriken" and not hostile:_projectile_impact(shot,shot["pos"])
            if shot.get("returning",false) and not shot.get("returned",false):
                shot["returned"]=true
                shot["life"]=0.72
                shot["dir"]=(player_pos-shot["pos"]).normalized()
                shot["hit"]={}
                continue
            shots.erase(shot)
            continue
        if hostile:
            if skill_adapter.intercept(shot["pos"]):shots.erase(shot);continue
            var player_center:Vector2=player_pos+Vector2(0,-19)
            if Geometry2D.get_closest_point_to_segment(player_center,previous,shot["pos"]).distance_squared_to(player_center)<(19.0*19.0):
                if not godmode and invulnerable<=0.0:_hurt_player(float(shot["damage"]))
                shots.erase(shot)
            continue
        var kunai:bool=str(shot.get("kind","")).begins_with("kunai")
        var fuma:bool=bool(shot.get("kind","")=="fuma")
        var radius:float=(9.0 if kunai else 13.0 if fuma else 16.0)*float(shot.get("size",1.0))
        for e in enemies.duplicate():
            if not shots.has(shot):break
            if not enemies.has(e):continue
            var ref=int(e["actor"].get_instance_id())
            if shot["hit"].has(ref):continue
            var center:Vector2=e["pos"]+Vector2(0,-22.0 if not e.get("mini_boss",false) else -32.0)
            var enemy_radius:float=32.0 if e.get("mini_boss",false) else 26.0 if e["kind"]=="sound_heavy" else 20.0
            var closest:Vector2=Geometry2D.get_closest_point_to_segment(center,previous,shot["pos"])
            if closest.distance_squared_to(center)<(radius+enemy_radius)*(radius+enemy_radius):
                shot["hit"][ref]=true
                _damage_target(e,float(shot["damage"]))
                if enemies.has(e) and kunai and int(upgrades.get("kunai_bleed",0))>0:
                    e["bleed"]=3.0
                    e["bleed_dps"]=float(upgrades["kunai_bleed"])*6.0*TRANSFORM_DAMAGE_BOOST[player_form]
                _projectile_impact(shot,closest)
                shot["pierced"]+=1
                var penetration:int=int(upgrades["kunai_pierce"]) if kunai else (3+int(upgrades.get("fuma_boomerang",0))*2) if fuma else int(upgrades["pierce"])
                if int(shot["pierced"])>penetration or shot.get("kind","")=="shuriken":
                    shots.erase(shot)
                    break
        if shots.has(shot) and boss_active and boss.get("hp",0.0)>0.0:
            var ref=int(boss["actor"].get_instance_id())
            var center:Vector2=boss["pos"]+Vector2(0,-36)
            if not shot["hit"].has(ref) and Geometry2D.get_closest_point_to_segment(center,previous,shot["pos"]).distance_squared_to(center)<pow(radius+48.0,2.0):
                shot["hit"][ref]=true
                _damage_target(boss,float(shot["damage"]))
                _projectile_impact(shot,shot["pos"])
                if shots.has(shot):shots.erase(shot)

func _update_drops(dt:float) -> void:
    Pickups.step(self,dt)

func _update_clones(dt:float) -> void:
    for c in clones.duplicate():
        c["life"]-=dt
        var chase_target=_closest_target(c["pos"],375.0)
        if not chase_target.is_empty():
            c["pos"]=(c["pos"] as Vector2).move_toward(chase_target["pos"],68.0*dt)
            if absf((chase_target["pos"]-c["pos"]).x)>1: c["actor"].facing=signf((chase_target["pos"]-c["pos"]).x)
        else:
            c["pos"]=(c["pos"] as Vector2).move_toward(player_pos,82.0*dt)
        c["actor"].position=c["pos"]
        c["actor"].moving=true
        c["actor"].tick(visual_delta)
        c["fire_cd"]-=dt
        if c["fire_cd"]<=0 and not chase_target.is_empty() and shots.size()<MAX_SHOTS:
            var aim:Vector2=(chase_target["pos"]-c["pos"]).normalized()
            var assist_rasengan := int(upgrades["clones"])>=2 and int(upgrades["rasengan"])>0 and rng.randi_range(0,4)==0
            shots.append({"pos":c["pos"]+Vector2(0,-25),"dir":aim,"life":0.95,
                "damage":(20.0+float(upgrades["clones"])*4.0)*TRANSFORM_DAMAGE_BOOST[player_form] if assist_rasengan else (9.0+float(upgrades["clones"])*2.5)*TRANSFORM_DAMAGE_BOOST[player_form],
                "size":1.0 if assist_rasengan else 0.85,"kind":"rasengan" if assist_rasengan else "kunai", "pierced":0,"hit":{},"velocity":425.0 if assist_rasengan else 495.0})
            c["fire_cd"]=1.55
        if c.get("rendan_hits",0)>0:
            c["rendan_cd"]-=dt
            if c["rendan_cd"]<=0:
                var victim=_closest_target(c["pos"],430.0)
                if not victim.is_empty():
                    c["pos"]=(c["pos"] as Vector2).move_toward(victim["pos"],115.0)
                    _aoe_damage(victim["pos"],36.0,((18.0+float(upgrades["naruto_rendan"])*12.0)*(1.0+float(upgrades["clones"])*0.22))*TRANSFORM_DAMAGE_BOOST[player_form])
                    if fx.size()<MAX_FX:
                        fx.append({"pos":victim["pos"],"life":0.24,"max":0.24,"radius":34.0,"kind":"rendan"})
                    c["actor"].pose_action="210" if c["actor"].actions.has("210") else "200"
                    c["actor"].pose_time=0.32
                    c["actor"].position=c["pos"]
                    c["rendan_hits"]-=1
                    if c["rendan_hits"]==0 and int(upgrades.get("rendan_finisher",0))>0:
                        _aoe_damage(victim["pos"],100.0,40.0+float(upgrades["rendan_finisher"])*35.0)
                        _add_blast(victim["pos"],120.0,"chakra_blast")
                    c["rendan_cd"]=0.34
                else:
                    c["rendan_hits"]=0
        if c["life"]<=0 or c["hp"]<=0:
            c["actor"].queue_free()
            clones.erase(c)

func _spawn_clones() -> void:
    if clone_cooldown>0:return
    clone_cooldown=maxf(7.7,20.0-float(upgrades["clones"])*2.2-float(upgrades.get("clone_army",0))*1.2)
    for i in range(2+int(upgrades["clones"])+int(upgrades.get("clone_army",0))):
        var at=player_pos+Vector2.from_angle(TAU*i/maxf(2,2+int(upgrades["clones"])+int(upgrades.get("clone_army",0)))) * 52.0
        var actor = _enemy_actor(build.actor_pack(),at,Color(str(alpha.hero()["color"])))
        actor.form_tint=Color(0.77,0.9,1,0.80)
        clones.append({"pos":at,"life":5.0+float(upgrades["clones"])*0.8,
                       "hp":90.0,"actor":actor,"fire_cd":rng.randf_range(0.18,0.7),
                       "rendan_hits":(1+int(upgrades["naruto_rendan"])+int(upgrades.get("rendan_finisher",0))) if int(upgrades["naruto_rendan"])>0 else 0,
                       "rendan_cd":0.2+float(i)*0.1})
    _flash(("NARUTO RENDAN!" if int(upgrades["naruto_rendan"])>0 else "KAGE BUNSHIN") if alpha.selected=="naruto" else (str(alpha.hero()["name"])+" / TECHNIKA KLONÓW"))
    _sfx("clone.wav")

func _update_fx(dt:float) -> void:
    event_time=maxf(0.0,event_time-dt)
    for v in fx.duplicate():
        v["life"]-=dt
        if v["life"]<=0: fx.erase(v)
    for k in kawarimi_fx.duplicate():
        k["life"]-=dt
        if k["life"]<=0:kawarimi_fx.erase(k)


func _update_hazards(dt:float) -> void:
    if boss_active:
        quicksand_zones.clear()
        return
    hazard_timer -= dt
    if hazard_timer <= 0.0 and quicksand_zones.size() < 2:
        var pos = player_pos + Vector2(rng.randf_range(-420.0,420.0), rng.randf_range(-300.0,300.0))
        quicksand_zones.append({"pos": pos, "radius": rng.randf_range(44.0,68.0), "life": rng.randf_range(10.0,15.0), "pulse": rng.randf_range(0.0,TAU)})
        hazard_timer = rng.randf_range(13.0,17.0)
    for q in quicksand_zones.duplicate():
        q["life"] -= dt
        q["pulse"] += dt * 2.4
        if q["life"] <= 0.0:
            quicksand_zones.erase(q)

func _update_oiroke(dt:float) -> void:
    var power=int(upgrades.get("oiroke",0))
    if power<=0:return
    oiroke_cd-=dt
    if oiroke_cd<=0.0:
        oiroke_time=5.0+float(power)*1.0
        oiroke_cd=maxf(8.5,16.0-float(power)*2.35-float(upgrades.get("oiroke_pressure",0))*0.7)
        oiroke_pos=player_pos
        oiroke_hits.clear()
        oiroke_cloud_timer=0.06
        oiroke_cast_age=0.0
        _flash("OIROKE NO JUTSU!  •  HAREM SMOKE",1.8)
        if not muted and oiroke_puff_player!=null:oiroke_puff_player.play()
        _add_blast(oiroke_pos,108.0,"smoke_blast")
    if oiroke_time<=0.0:return
    oiroke_time=maxf(0.0,oiroke_time-dt)
    oiroke_cast_age+=dt
    oiroke_pos=oiroke_pos.move_toward(player_pos,dt*130.0)
    # Each level adds independently drawn Oiroke figures, with fixed personal attack reach.
    var count:int=1+2*(power-1)+2*int(upgrades.get("oiroke_pressure",0))
    var ring:float=62.0+float(power-1)*38.0
    var points:Array[Vector2]=[oiroke_pos]
    for j in range(1,count):points.append(oiroke_pos+Vector2.from_angle(TAU*float(j-1)/maxf(1.0,float(count-1)))*ring)
    for e in enemies.duplicate():
        if not enemies.has(e):continue
        var uid=int(e["actor"].get_instance_id())
        var touching=false
        for spot in points:
            if e["pos"].distance_squared_to(spot)<90.0*90.0:touching=true;break
        if not touching:continue
        if not oiroke_hits.has(uid):
            oiroke_hits[uid]=true
            _damage_target(e,(41.0+float(power)*26.0)*TRANSFORM_DAMAGE_BOOST[player_form])
            if enemies.has(e):e["stagger"]=maxf(float(e["stagger"]),1.15+float(power)*0.3)
    oiroke_cloud_timer-=dt
    if oiroke_cloud_timer<=0.0:
        oiroke_cloud_timer=maxf(0.23,0.45-float(upgrades.get("oiroke_pressure",0))*0.055)
        for spot in points:_aoe_damage(spot,90.0,(8.0+float(power)*3.0+float(upgrades.get("oiroke_cloud",0))*6.0)*TRANSFORM_DAMAGE_BOOST[player_form])
        if fx.size()<MAX_FX and not low_fx:
            fx.append({"pos":oiroke_pos+Vector2(rng.randf_range(-ring,ring),rng.randf_range(-38.0,16.0)),"life":0.65,"max":0.65,"radius":56.0,"kind":"oiroke_puff"})
    if boss_active and boss.get("hp",0.0)>0.0 and not oiroke_hits.has(-1):
        var near_boss=false
        for spot in points:
            if (boss["pos"] as Vector2).distance_squared_to(spot)<90.0*90.0:near_boss=true;break
        if near_boss:
            oiroke_hits[-1]=true
            _damage_target(boss,(32.0+float(power)*22.0)*TRANSFORM_DAMAGE_BOOST[player_form])

func _pool_upgrades() -> Array[String]:
    var result:Array[String]=[]
    for id in draft.pool():result.append(str(id))
    return result

func _pick_rarity(scroll:bool) -> int:
    var r=rng.randf()
    if scroll:
        return 3 if r<0.04 else 2 if r<0.24 else 1 if r<0.73 else 0
    return 3 if r<0.007 else 2 if r<0.075 else 1 if r<0.35 else 0

func _select_skill(pool:Array[String],scroll:bool) -> String:
    var tier=_pick_rarity(scroll)
    var matches:Array[String]=[]
    for key in pool:
        if int(JUTSU[key]["tier"])==tier:matches.append(key)
    # If selected rarity is exhausted, nearest remaining tier wins.
    if matches.is_empty():
        var smallest=10
        for key in pool: smallest=mini(smallest,absi(int(JUTSU[key]["tier"])-tier))
        for key in pool:
            if absi(int(JUTSU[key]["tier"])-tier)==smallest:matches.append(key)
    return matches[rng.randi_range(0,matches.size()-1)]

func _open_upgrade(scroll:bool) -> void:
    if picking or gacha_active or form_choice or transition_time>=0:return
    scroll_count+=int(scroll);ui_view.from_scroll=scroll;_open_draft("level")
func _grant_upgrade(stat:String) -> void:
    if not build.grant(stat):return
    for id in LEGACY_JUTSU:upgrades[id]=0
    for id in build.passives:upgrades[id]=build.passives[id]
    for id in build.levels:upgrades[id]=build.levels[id]
    for id in build.evolution_choices:upgrades[id+":"+str(build.evolution_choices[id])]=1
    if stat=="max_hp":player_hp=minf(build.max_hp(),player_hp+45)
    if stat in ["regeneration","recovery"]:player_hp=minf(build.max_hp(),player_hp+40)

func _choose_card(index:int) -> void:
    if not picking or index<0 or index>=selected_cards.size():return
    var c=selected_cards[index]
    var stat:String=c["stat"]
    _grant_upgrade(stat)
    if int(c["tier"])>=2:_flash("ODKRYTO: "+str(JUTSU[stat]["name"]),2.4)
    picking=false
    _sfx("reveal.wav")

func _open_chest() -> void:
    var pool=_pool_upgrades()
    if pool.is_empty():
        player_hp=minf(PLAYER_MAX_HP+float(upgrades["max_hp"])*18.0,player_hp+30.0)
        return
    chest_count+=1
    gacha_active=true
    gacha_elapsed=0.0
    gacha_revealed=false
    # 15% chance to guarantee an available tier-3 evolution in a chest.
    # No fake jackpot when the build cannot legally evolve yet.
    var rare_pool:Array=pool.filter(func(id):return int(JUTSU[id].get("tier",0))>=3)
    gacha_jackpot=not rare_pool.is_empty() and rng.randf()<0.15
    gacha_candidates=pool.duplicate()
    gacha_rewards.clear()
    for id in draft.offer("chest",gacha_jackpot):gacha_rewards.append(str(id))
    gacha_jackpot=gacha_jackpot and gacha_rewards.any(func(id):return int(JUTSU[id].get("tier",0))>=3)
    _sfx("gacha.wav")
    if FileAccess.file_exists("res://assets/v8/gacha_roll.wav"):
        gacha_sound.stream=AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes("res://assets/v8/gacha_roll.wav"))
        gacha_sound.volume_db=-7.0 if not muted else -80.0
        gacha_sound.play()

func _update_gacha(dt:float) -> void:
    gacha_elapsed+=dt
    if gacha_elapsed>=2.55 and not gacha_revealed:
        gacha_revealed=true
        if gacha_sound.playing:gacha_sound.stop()
        _sfx("reveal.wav")
        _sfx("explosion_v8.wav")
    # Chest remains open until player CHOOSES; never give all 3 automatically.

func _choose_chest_reward(index:int) -> void:
    if not gacha_active or not gacha_revealed or index<0 or index>=gacha_rewards.size():return
    var choice:String=gacha_rewards[index]
    _grant_upgrade(choice)
    gacha_active=false
    gacha_revealed=false
    _flash("WYBRANO: "+str(JUTSU[choice]["name"]),2.7)
    _sfx("upgrade.wav")

func _update_hud() -> void:
    # Stable depth ordering keeps feet and contact shadows coherent in crowds.
    player.z_index=clampi(int(player_pos.y-camera.position.y)+1000,1,2000)
    for e in enemies: e["actor"].z_index=clampi(int(e["pos"].y-camera.position.y)+1000,1,2000)
    for c in clones: c["actor"].z_index=clampi(int(c["pos"].y-camera.position.y)+1000,1,2000)
    if boss.has("actor"): boss["actor"].z_index=clampi(int(boss["pos"].y-camera.position.y)+1000,1,2000)

func _finish(victory:bool) -> void:
    if finished:return
    finished=true
    picking=false
    gacha_active=false
    if miniboss_active:_set_miniboss_music(false)
    ui_view.victory=victory
    _log("run ended: %s at %.1f, level %d" % ["VICTORY" if victory else "DEFEAT",clock,level])

func _sfx(file:String) -> void:
    var path="res://assets/audio/"+file
    if get_node("/root/AudioDirector").play_effect(path,file,muted):
        voice_last[file]=Time.get_ticks_msec()*0.001

func _tile_id(x:int,y:int)->int:
    var hash_value=int(x*92837111)^int(y*689287499)
    return posmod(hash_value,tiles.size()) if tiles.size()>0 else 0

func _draw() -> void:
    var left:=player_pos-Vector2(610,380)
    var right:=player_pos+Vector2(610,380)
    if stage_ground!=null:
        var tile_side:float=float(stage_ground.get_width())
        for yy in range(int(floor(left.y/tile_side)),int(ceil(right.y/tile_side))+1):
            for xx in range(int(floor(left.x/tile_side)),int(ceil(right.x/tile_side))+1):
                draw_texture(stage_ground,Vector2(float(xx)*tile_side,float(yy)*tile_side))
    else:
        draw_rect(Rect2(left,right-left),Color("b9905b"),true)
    for q in quicksand_zones:
        # Stage-specific hazards, no forest-only art in the desert.
        var rad:float=float(q["radius"])
        var center:Vector2=q["pos"]
        if not suiton_frames.is_empty():
            var water:Texture2D=suiton_frames[int(hostile_orb_clock*6.0)%suiton_frames.size()]
            CleanFX.paint(self,"water",center,rad*2,hostile_orb_clock,0,0.65)
        draw_arc(center,rad*.88,0,TAU,48,Color(.3,.85,.9,.5),2,true)
    # Native seal geometry replaces the dirty rune sprites, including wet traps.
    for rune in rune_traps:
        var active:bool=float(rune.age)>=1.35
        var p:Vector2=rune.pos
        var rad:float=float(rune.radius)
        var color=Color("ed6953") if not active else Color("64cad8") if rune.get("wet",false) else Color("ce87e5")
        draw_circle(p,rad*.82,Color(color,.12 if not active else .22))
        draw_arc(p,rad*.88,0,TAU,48,Color(color,.85),2,true)
        draw_arc(p,rad*.61,hostile_orb_clock,hostile_orb_clock+TAU*.86,40,Color(color,.7),2,true)
        for j in range(8):
            var d=Vector2.from_angle(j*TAU/8)
            draw_line(p+d*rad*.73,p+d*rad*.94,Color(color,.75),2,true)
        if active:CleanFX.paint(self,"water" if rune.get("wet",false) else "chakra",p,rad*1.25,hostile_orb_clock,0,.7)

    if miniboss_active:
        for e in enemies:
            if e.get("mini_boss",false):
                var color=[Color("e5bd43"),Color("ff5d37"),Color("42b7df")][int(e.get("mini_stage",1))]
                draw_arc(e["pos"],52.0+float(e.get("mini_stage",1))*7.0+3.0*sin(hostile_orb_clock*5.0),0,TAU,52,color,2.5)

    # Sasori commands the Third Kazekage puppet in phase II.
    # It uses hand-picked recoloured frames of the user's original MUGEN Sasori sprites.
    if boss_active and not boss.is_empty() and int(boss.get("phase",1))==2 and not puppet_frames.is_empty():
        var puppet_at:Vector2=boss["pos"]+Vector2(96.0+sin(hostile_orb_clock*1.8)*9.0,-26.0+cos(hostile_orb_clock*2.0)*6.0)
        var puppet:Texture2D=puppet_frames[int(hostile_orb_clock*7.0)%puppet_frames.size()]
        draw_line(boss["pos"]+Vector2(0,-69),puppet_at+Vector2(0,-53),Color(0.68,0.82,0.92,0.32),1.25)
        draw_texture_rect(puppet,Rect2(puppet_at-Vector2(57,165),Vector2(114,157)),false)
    # Telegraphs are rendered beneath actors/projectiles and remain readable under heavy VFX.
    for h in boss_telegraphs:
        var remain:float=float(h["windup"])/maxf(0.01,float(h["duration"]))
        var warn=Color("eb593d") if h["kind"]!="poison_pool" else Color("ae52b7")
        warn.a=0.16+0.29*(1.0-remain)
        if h["kind"]=="sand_lane":
            var heading:Vector2=h["dir"]
            var ending:Vector2=h["pos"]+heading*float(h["length"])
            draw_line(h["pos"],ending,warn,float(h["width"]))
            draw_line(h["pos"],ending,Color("f2c38d"),2.5)
        else:
            draw_circle(h["pos"],float(h["width"])*0.50,warn)
            draw_arc(h["pos"],float(h["width"])*0.5,0,TAU,48,Color("ffc69a"),2.5)
    for e in enemies:
        if e.get("summoner",false) and not sound_ninja_frames.is_empty():
            var frame:Texture2D=sound_ninja_frames[int(hostile_orb_clock*8.0)%sound_ninja_frames.size()]
            var dimensions:Vector2=frame.get_size()*0.85
            var hit_color:Color=Color(1.0,0.40,0.35,1.0) if float(e["actor"].hit_flash)>0.0 else Color.WHITE
            draw_texture_rect(frame,Rect2(e["pos"]-Vector2(dimensions.x*0.5,dimensions.y),dimensions),false,hit_color)
    for d in drops:
        var at:Vector2=d["pos"]
        if d["type"]=="xp":
            var pulse := 0.5 + 0.5 * sin(hostile_orb_clock * 6.0 + at.x * 0.02)
            draw_circle(at,7.5 + pulse*1.6,Color(0.13,0.82,0.97,0.16))
            draw_circle(at,5.0 + pulse*0.9,Color("4ee8ff"))
            draw_circle(at,2.3,Color.WHITE)
            draw_arc(at,9.8 + pulse*1.4,hostile_orb_clock*3.2,hostile_orb_clock*3.2+TAU*0.72,22,Color("9cf7ff"),1.5)
        elif d["type"]=="chest":
            var float_age:float=sin(hostile_orb_clock*4.8+at.x*0.02)*3.0
            draw_circle(at+Vector2(0,3),25.0,Color(1.0,0.77,0.18,0.14))
            draw_arc(at,24.0+float_age,0,TAU,30,Color(1.0,0.79,0.30,0.72),2.0)
            if chest_texture!=null:
                draw_texture_rect(chest_texture,Rect2(at-Vector2(28,28)+Vector2(0,float_age),Vector2(56,56)),false)
        elif d["type"]=="ramen" and ramen_texture!=null:
            draw_texture_rect(ramen_texture,Rect2(at-Vector2(21,31),Vector2(42,32)),false)
        elif d["type"]=="heal":
            draw_circle(at,8.3,Color("ef6f88"))
            draw_circle(at,4.0,Color("ffd4dc"))
            draw_line(at+Vector2(-4,0),at+Vector2(4,0),Color.WHITE,2.0)
            draw_line(at+Vector2(0,-4),at+Vector2(0,4),Color.WHITE,2.0)
        else:
            var wig := 0.6 + 0.4*sin(hostile_orb_clock*4.0)
            draw_circle(at,12.0,Color(0.84,0.70,0.30,0.18))
            draw_circle(at,8.0,Color("d8b45b"))
            draw_rect(Rect2(at-Vector2(5,7),Vector2(10,14)),Color(0.40,0.23,0.07,0.88),false,2.0)
            draw_line(at+Vector2(-4,0),at+Vector2(4,0),Color(0.83,0.92,0.95,wig),2.0)
    for k in kawarimi_fx:
        var fade=float(k["life"])/maxf(0.01,float(k["max"]))
        var origin:Vector2=k["pos"]
        if kawarimi_log!=null:
            draw_texture_rect(kawarimi_log,Rect2(origin-Vector2(21,61.5),kawarimi_log.get_size()*1.5),false,Color(1.0,1.0,1.0,fade))
        else:
            draw_rect(Rect2(origin-Vector2(11,29),Vector2(22,37)),Color(0.48,0.25,0.1,fade),true)
        draw_arc(origin,35.0+(1.0-fade)*35.0,0,TAU,28,Color(0.93,0.94,0.92,fade*0.7),3.0)
    if oiroke_time>0:
        var power:float=float(upgrades["oiroke"])
        var count:int=1+2*(int(power)-1)+2*int(upgrades.get("oiroke_pressure",0))
        var ring:float=62.0+float(int(power)-1)*38.0
        var points:Array[Vector2]=[oiroke_pos]
        for k in range(1,count):points.append(oiroke_pos+Vector2.from_angle(TAU*float(k-1)/maxf(1.0,float(count-1)))*ring)
        # Smoke frames are sourced from the original MUGEN Sasori effect pack.
        var smoke:Array=boss_vfx.get("smoke",[])
        var transparency:float=clampf(oiroke_time*2.5,0.0,1.0)
        for j in range(7 if low_fx else 13):
            var theta:float=float(j)*TAU/float(7 if low_fx else 13)+hostile_orb_clock*0.29
            var shift:Vector2=Vector2.from_angle(theta)*(ring*0.85)
            var puff_at:Vector2=oiroke_pos+shift+Vector2(0,-16)
            if not smoke.is_empty():
                var frame:Texture2D=smoke[(int(hostile_orb_clock*15.0)+j*2)%smoke.size()]
                var size:float=75.0+power*15.0
                draw_texture_rect(frame,Rect2(puff_at-Vector2.ONE*size*0.5,Vector2.ONE*size),false,Color(1.0,0.93,0.97,0.66*transparency))
        if oiroke_cast_age<0.60 and not naruto_effects.is_empty():
            var stage:float=clampf(oiroke_cast_age/0.60,0.0,1.0)
            var original_frame:Texture2D=naruto_effects[clampi(int(stage*naruto_effects.size()),0,naruto_effects.size()-1)]
            var src_size:Vector2=original_frame.get_size()*1.9
            draw_texture_rect(original_frame,Rect2(oiroke_pos+Vector2(-src_size.x/2.0,-src_size.y),src_size),false,Color(1,1,1,1.0-stage))
        if oiroke_figure!=null and oiroke_cast_age>0.34:
            var breathe=sin(hostile_orb_clock*6.0)*2.0
            for k in range(points.size()):
                var spot:Vector2=points[k]
                var fig_frame:Texture2D=oiroke_figure_frames[(int(hostile_orb_clock*9.0)+k)%oiroke_figure_frames.size()] if not oiroke_figure_frames.is_empty() else null
                if fig_frame==null:fig_frame=oiroke_figure
                draw_texture_rect(fig_frame,Rect2(spot+Vector2(-30,-105+breathe),Vector2(60,96)),false,Color(1,1,1,transparency*clampf((oiroke_cast_age-0.34)*4.0,0.0,1.0)))
        if not smoke.is_empty():
            var center_smoke:Texture2D=smoke[int(hostile_orb_clock*12.0)%smoke.size()]
            draw_texture_rect(center_smoke,Rect2(oiroke_pos-Vector2(44,68),Vector2(88,88)),false,Color(1,1,1,0.31*transparency))
        # Soft vapor boundary, not a solid pink damage circle.
        for j in range(6):
            var vapor_at=oiroke_pos+Vector2.from_angle(hostile_orb_clock*0.41+float(j)*TAU/6.0)*(ring+36)
            draw_circle(vapor_at,9.0,Color(1.0,0.89,0.96,0.10*transparency))
    for s in shots:
        if not s.get("hostile",false):
            if s.get("kind","")=="fuma":
                var fuma_tex:Texture2D=item_art.get("shuriken",null)
                if fuma_tex!=null:
                    var dimension=92.0*float(s.get("size",1.0))/2.9
                    draw_set_transform(s["pos"],hostile_orb_clock*10.0,Vector2.ONE)
                    draw_texture_rect(fuma_tex,Rect2(-dimension*0.5,-dimension*0.5,dimension,dimension),false)
                    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
                continue
            if str(s.get("kind","")).begins_with("kunai"):
                # Preserve collisions but give each class a visible, coherent projectile identity.
                if alpha.selected!="naruto":
                    var art_id:String="blast" if alpha.selected=="sasuke" else "chakra" if alpha.selected=="kakashi" else "hit" if alpha.selected=="rock_lee" else "wind" if alpha.selected=="neji" else "sand"
                    var diameter:float=41.0 if alpha.selected=="rock_lee" else 56.0
                    CleanFX.paint(self,art_id,s["pos"],diameter,clock,Vector2(s["dir"]).angle())
                    continue
                var tex:Texture2D=item_art.get("kunai",null)
                if tex!=null:
                    var position:Vector2=s["pos"]
                    var direction:Vector2=s["dir"]
                    var tint:Color=s.get("tint",Color.WHITE)
                    var size:Vector2=tex.get_size()*(1.7 if s["kind"]=="kunai_explosive" else 1.45)
                    draw_set_transform(position,direction.angle(),Vector2.ONE)
                    draw_texture_rect(tex,Rect2(-size*0.5,size),false,Color.WHITE)
                    if player_form>0:
                        draw_line(Vector2(-30,0),Vector2(-3,0),Color(tint.r,tint.g,tint.b,0.65),3.0)
                    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
                continue
            var sprites=shuriken_frames if s.get("kind","")=="shuriken" else rasengan_frames
            if sprites.is_empty():continue
            var frame=sprites[int(clock*21)%sprites.size()]
            var scale=1.7 if s.get("kind","")=="shuriken" else 1.0
            var r=37.0*float(s.get("size",1.0))*scale
            var base_tint:Color = s.get("tint", Color.WHITE)
            var tint=Color("ffe282") if s.get("critical",false) else base_tint
            CleanFX.paint(self,"rasenshuriken" if s.get("kind","")=="shuriken" else "rasengan",s.pos,r,clock)
        else:
            var item_key := str(s.get("item_vfx",""))
            if item_key=="chakra_bomb":
                CleanFX.paint(self,"chakra",s.pos,34,hostile_orb_clock);continue
            var item_tex:Texture2D=item_art.get(item_key,null)
            if item_tex!=null:
                var radius=21.0 if item_key in ["shuriken","small_shuriken","chakra_bomb"] else 29.0
                var dims:Vector2=item_tex.get_size()*radius/maxf(item_tex.get_width(),item_tex.get_height())
                draw_set_transform(s["pos"],(s["dir"] as Vector2).angle(),Vector2.ONE)
                draw_texture_rect(item_tex,Rect2(-dims*0.5,dims),false,Color.WHITE)
                draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
                continue
            var effect_id := str(s.get("vfx",""))
            if effect_id in ["suiton","chakra","sand","poison"]:
                CleanFX.paint(self,"water" if effect_id=="suiton" else effect_id,s.pos,54.0*float(s.get("size",1)),hostile_orb_clock,Vector2(s.dir).angle());continue
            var images:Array = suiton_frames if effect_id=="suiton" else boss_vfx.get(effect_id,[])
            if not images.is_empty():
                var frame:Texture2D=images[int(hostile_orb_clock*13.0)%images.size()]
                var amount:float=54.0*float(s.get("size",1.0))
                if effect_id=="senbon":amount=74.0*float(s.get("size",1.0))
                if effect_id=="sand":amount=64.0*float(s.get("size",1.0))
                draw_set_transform(s["pos"],(s["dir"] as Vector2).angle(),Vector2.ONE)
                var dims:Vector2=frame.get_size()*amount/maxf(frame.get_width(),frame.get_height())
                draw_texture_rect(frame,Rect2(-dims*0.5,dims),false)
                draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
                continue
            var direction:Vector2=s["dir"]
            var style := str(s.get("style","needle"))
            if style == "burst":
                draw_circle(s["pos"],7.0,Color(0.88,0.99,0.78,0.25))
                draw_circle(s["pos"],4.8,Color("b8f56c"))
                draw_arc(s["pos"],8.5,hostile_orb_clock*7.0,hostile_orb_clock*7.0+TAU*0.8,18,Color("efffc6"),1.7)
            else:
                var side:Vector2 = Vector2(-direction.y,direction.x)
                var tail:Vector2 = s["pos"]-direction*11
                var tip:Vector2 = s["pos"]+direction*12
                var pts := PackedVector2Array([tail-side*3.0, tail+side*3.0, tip])
                draw_colored_polygon(pts,Color("cce7a5"))
                draw_line(tail,tip,Color("efffc6"),2.0)
                draw_circle(tail,2.6,Color("6ab04e"))
    for tornado in tornadoes:
        if tornado_frames.is_empty():continue
        var frame=tornado_frames[int(clock*16)%tornado_frames.size()]
        var r=92.0
        draw_texture_rect(frame,Rect2(tornado["pos"]-Vector2.ONE*r/2,Vector2.ONE*r),false)

    for v in fx:
        if str(v.get("kind","")) in ["lee_air","gentle_palm"]:
            var fade:float=clampf(float(v["life"])/maxf(0.01,float(v["max"])),0.0,1.0)
            CleanFX.paint(self,str(v["kind"]),Vector2(v["pos"]),float(v.get("radius",70.0))*2.0,clock,float(v.get("direction",1.0))*0.08,fade)
            continue
        if v.kind in ["impact","rasen_blast","smoke_blast","chakra_blast","futon_blast","melee_rasengan","sand_blast"]:
            var progress=1.0-float(v.life)/maxf(.01,float(v.max))
            var clean_art="hit" if v.kind=="impact" else "wind" if v.kind=="futon_blast" else "sand" if v.kind=="sand_blast" else "blast"
            CleanFX.paint(self,clean_art,v.pos+Vector2(0,-20),36 if v.kind=="impact" else float(v.get("radius",70))*1.8,progress*.35,0,1-progress)
            continue
        if v["kind"]=="rendan" and not barrage_frames.is_empty():
            var bmp:Texture2D=barrage_frames[int(hostile_orb_clock*19.0)%barrage_frames.size()]
            var hit_size=75.0+22.0*float(upgrades.get("naruto_rendan",0))
            var frame_pos:Vector2=v["pos"]+Vector2(0,-22)
            draw_texture_rect(bmp,Rect2(frame_pos-Vector2.ONE*hit_size*0.5,Vector2.ONE*hit_size),false,Color(1,1,1,float(v["life"])/float(v["max"])))
            continue
        if low_fx and v["kind"] not in ["pulse","rasen_blast","smoke_blast"]:continue
        if v["kind"] in ["rasen_blast","smoke_blast","chakra_blast","oiroke_puff","futon_blast","melee_rasengan","sand_blast"]:
            var progress:float=1.0-float(v["life"])/maxf(0.01,float(v["max"]))
            var images:Array=boss_vfx.get("slash",[]) if v["kind"]=="futon_blast" else source_rasengan_frames if v["kind"]=="melee_rasengan" else boss_vfx.get("sand",[]) if v["kind"]=="sand_blast" else boss_vfx.get("blast",[]) if v["kind"] in ["rasen_blast","chakra_blast"] else boss_vfx.get("smoke",[])
            if not images.is_empty():
                var index=clampi(int(progress*float(images.size())),0,images.size()-1)
                var img:Texture2D=images[index]
                var radius:float=float(v.get("radius",90.0))
                var scale:float=radius*(1.0+progress*0.35)*2.2
                var color:Color=Color(0.54,0.96,1.0,0.94) if v["kind"] in ["rasen_blast","futon_blast","melee_rasengan"] else Color(1.0,0.92,0.81,0.83) if v["kind"]=="chakra_blast" else Color(1,1,1,0.78)
                color.a*=1.0-progress*0.78
                draw_texture_rect(img,Rect2(v["pos"]-Vector2.ONE*scale/2.0,Vector2.ONE*scale),false,color)
            if v["kind"]=="rasen_blast" and not burst_frames.is_empty():
                var pulse:Texture2D=burst_frames[clampi(int(progress*float(burst_frames.size())),0,burst_frames.size()-1)]
                var diameter:float=float(v.get("radius",90.0))*2.0
                draw_texture_rect(pulse,Rect2(v["pos"]-Vector2.ONE*diameter/2.0,Vector2.ONE*diameter),false,Color(0.56,0.88,1.0,1.0-progress))
            continue
        var life=float(v["life"])/maxf(0.001,float(v["max"]))
        var tint=Color("ef91cd") if v["kind"]=="charm" else Color("e9a55c") if v["kind"]=="rendan" else Color("f6d56c") if v["kind"]=="critical" else Color("77efb8") if v["kind"]=="heal" else Color("f4c657") if v["kind"]=="pulse" and player_form==2 else Color("e58b57") if v["kind"]=="pulse" else Color("95eaff")
        tint.a=life*0.75
        var radius=float(v.get("radius",110.0))*(1.0-life) if v["kind"]!="pulse" else 110.0*(1.0-life)
        if v["kind"]=="aoe": radius=float(v.get("radius",120.0))*(1.0-life*0.9)
        draw_arc(v["pos"],maxf(1.0,radius),0,TAU,56,tint,5.0)
    if alpha.selected!="naruto" and player_form>0:
        # Character-class chakra silhouette behind real MUGEN frames, no fake sprite replacements.
        var aura_color:Color=Color(str(alpha.hero()["color"]))
        var aura_origin:Vector2=player_pos+Vector2(0,-43)
        var pulse:float=sin(hostile_orb_clock*5.0)*0.5+0.5
        var aura_radius:float=44.0+float(player_form)*9.0+pulse*6.0
        draw_circle(aura_origin,aura_radius,Color(aura_color,0.045+0.025*pulse))
        for band in range(2+player_form):
            var radius:float=aura_radius+float(band)*7.0
            var start:float=hostile_orb_clock*(0.8+float(band)*0.16)+float(band)
            draw_arc(aura_origin,radius,start,start+PI*0.65,23,Color(aura_color,0.55-float(band)*0.09),2.0,true)
        if build.form_branch=="sage":
            draw_arc(aura_origin,aura_radius+8.0,0.0,TAU,58,Color(aura_color,0.22),1.5,true)
    if alpha.selected=="naruto" and not aura_frames.is_empty() and build.form_branch=="kyubi" and player_form==1:
        var frame_a:Texture2D=aura_frames[int(hostile_orb_clock*15.0)%aura_frames.size()]
        var width_a=97.0 if player_form==1 else 131.0
        var strength=0.96 if transform_pause>0.0 else 0.53+sin(hostile_orb_clock*7.5)*0.07
        draw_texture_rect(frame_a,Rect2(player_pos+Vector2(-width_a/2.0,-131.0),Vector2(width_a,136.0)),false,Color(1,1,1,strength))
    if transform_pause > 0.0:
        var t := transform_pause / maxf(0.001, transform_total)
        draw_circle(player_pos+Vector2(0,-36), 145.0, Color(1,0.92,0.65,0.09))
        draw_arc(player_pos+Vector2(0,-36), 86.0 + (1.0-t)*42.0, 0, TAU, 64, Color(1,0.86,0.47,0.95), 4.0)
        if not burst_frames.is_empty():
            var idx := int((1.0 - t) * float(burst_frames.size()-1))
            idx = clampi(idx,0,burst_frames.size()-1)
            var frame := burst_frames[idx]
            draw_texture_rect(frame, Rect2(player_pos-Vector2(92,128), Vector2(184,184)), false, Color(1,1,1,0.92))


func _open_draft(kind:String) -> void:
    selected_cards.clear()
    for id in draft.offer(kind):selected_cards.append({"stat":id,"tier":JUTSU[id].tier})
    picking=not selected_cards.is_empty();_sfx("upgrade.wav")
func _choose_form(index:int) -> void:
    if not form_choice:return
    if Forms.choose(build,"kyubi" if index==0 else "sage"):form_choice=false;_transform(1)
func _begin_duel_transition() -> void:
    if transition_time>=0:return
    transition_time=0;build.elapsed=clock;build.godmode=godmode;build.muted=muted;build.kills=stat_kills;build.player_level=level
    var f=FileAccess.open("user://last_build.json",FileAccess.WRITE);f.store_string(JSON.stringify(build.snapshot(),"  "))
    var af=FileAccess.open("user://last_alpha.json",FileAccess.WRITE)
    if af!=null:af.store_string(JSON.stringify(alpha.snapshot(),"  "))
    _flash("SASORI / POJEDYNEK",2.1);_sfx("boss.wav")
func skill_origin() -> Vector2:return player_pos
func skill_facing() -> float:return player_facing
func skill_targets() -> Array:return enemies
func skill_pose(action:String,duration:float) -> void:player.play_pose(action,duration)
func skill_sound(name:String) -> void:
    if name=="oiroke_puff.wav":
        get_node("/root/AudioDirector").play_effect("res://assets/v9/oiroke_puff.wav",name,muted)
    else:_sfx(name)
func skill_dash(movement:Vector2,_limit:float) -> void:player_pos=_move_scenery(player_pos,movement,14)
func skill_hit(e:Dictionary,damage:float,_id:String,stagger:float,push:Vector2) -> void:
    if not enemies.has(e):return
    _damage_target(e,damage)
    if enemies.has(e):e.stagger=minf(0.8,maxf(float(e.stagger),stagger));e.pos=_move_scenery(e.pos,push,12)

func _exit_tree() -> void:
 for child in get_children():
  if child is AudioStreamPlayer:
   child.stop();child.stream=null
