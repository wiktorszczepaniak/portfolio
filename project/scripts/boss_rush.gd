extends Node2D
## SHINOBI: BOSS RUSH // ALPHA 01. Single complete vertical slice.
## Godot 4.5+, 1280x720. Battle logic and rendering use separate projectile recipes.

const PATTERNS = preload("res://scripts/bullet_patterns.gd")
const W: float = 1280.0
const H: float = 720.0
const ARENA := Rect2(70.0, 96.0, 1140.0, 506.0)
const BG := Color("080f19")
const INK := Color("101d2a")
const PALE := Color("e9ebdd")
const CYAN := Color("67e6e5")
const GOLD := Color("ffd18a")
const RED := Color("ed6d78")
const HERO_NAMES := ["NARUTO UZUMAKI", "KYUUBI NARUTO", "SAGE NARUTO", "KCM NARUTO"]
const FORM_IDS := ["base", "kyuubi", "sage", "kcm"]
const BOSS_NAMES := ["ZABUZA MOMOCHI", "KISAME HOSHIGAKI", "ITACHI UCHIHA", "PAIN"]

var ui_font: Font
var packed_sprite_frames: Dictionary = {}
var hero_frames: Dictionary = {}
var zabuza_frames: Array[Texture2D] = []
var audio_players: Dictionary = {}
var music_player: AudioStreamPlayer
var scene: String = "menu"
var selected_hero: int = 0
var wins: int = 0
var just_unlocked: String = ""
var paused: bool = false
var time_s: float = 0.0
var battle_time: float = 0.0
var player_p := Vector2(635.0, 530.0)
var player_hp: int = 8
var player_chakra: float = 0.0
var player_invuln: float = 0.0
var dash_cd: float = 0.0
var clone_cd: float = 0.0
var clone_time: float = 0.0
var clone_shot_cd: float = 0.0
var transform_stage: int = 0 # 0 base, 1 chakra awakening, 2 final cloak
var buff_time: float = 0.0
var shot_cd: float = 0.0
var special_cd: float = 0.0
var last_direction := Vector2.UP
var boss_p := Vector2(640.0, 217.0)
var boss_hp: float = 9000.0
var boss_max_hp: float = 9000.0
var boss_phase: int = 1
var boss_clock: float = 0.0
var boss_intro: float = 2.7
var phase_banner: float = 0.0
var phase_shock: float = 0.0
var attack_cd: float = 0.0
var volley: int = 0
var bullets: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var score: int = 0
var grazes: int = 0
var screen_shake: float = 0.0
var victory: bool = false
var demo_mode: bool = false

func _ready() -> void:
	ui_font = ThemeDB.fallback_font
	load_frames()
	load_audio()
	load_progress()
	if "--qa-logic" in OS.get_cmdline_user_args():
		run_logic_qa()
	elif "--qa-smoke" in OS.get_cmdline_user_args():
		start_battle()
		demo_mode = true
	set_process(true)
	queue_redraw()

func load_frames() -> void:
	# Native PNG files are used from the local ZIP; a text-packed PNG atlas supports
	# the isolated GitHub branch without committing third-party binary files.
	packed_sprite_frames = read_sprite_pack()
	for key in FORM_IDS:
		var arr: Array[Texture2D] = []
		for i in range(12):
			var path := "res://assets/characters/naruto/%s_%02d.png" % [key, i]
			if ResourceLoader.exists(path):
				var tex := load(path) as Texture2D
				if tex != null:
					arr.append(tex)
			elif packed_sprite_frames.has(path.trim_prefix("res://")):
				arr.append(packed_sprite_frames[path.trim_prefix("res://")])
		hero_frames[key] = arr
	for i in range(22):
		var path := "res://assets/characters/zabuza/z_%02d.png" % i
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				zabuza_frames.append(tex)
		elif packed_sprite_frames.has(path.trim_prefix("res://")):
			zabuza_frames.append(packed_sprite_frames[path.trim_prefix("res://")])

func read_sprite_pack() -> Dictionary:
	var result: Dictionary = {}
	var packed_text_path := "res://assets/packed_sprites.b64"
	if not FileAccess.file_exists(packed_text_path):
		return result
	var txt := FileAccess.get_file_as_string(packed_text_path).strip_edges()
	if txt.is_empty(): return result
	var raw: PackedByteArray = Marshalls.base64_to_raw(txt)
	var temp_path := "user://boss_rush_sprite_pack.zip"
	var writer := FileAccess.open(temp_path, FileAccess.WRITE)
	if writer == null: return result
	writer.store_buffer(raw)
	writer.close()
	var zipper := ZIPReader.new()
	if zipper.open(temp_path) != OK: return result
	for path in zipper.get_files():
		var img := Image.new()
		if img.load_png_from_buffer(zipper.read_file(path)) == OK:
			result[path] = ImageTexture.create_from_image(img)
	zipper.close()
	return result

func load_audio() -> void:
	var packed: Dictionary = read_audio_pack()
	for name in ["rasengan", "dash", "transform", "water_cast", "water_hit", "boss_tell", "impact", "parry", "clone_smoke", "swing", "chakra_charge", "boss", "pickup"]:
		var path := "res://assets/audio/%s.wav" % name
		var stream: AudioStream = null
		if ResourceLoader.exists(path):
			stream = load(path)
		elif packed.has(name):
			stream = packed[name]
		if stream != null:
			var p := AudioStreamPlayer.new()
			p.stream = stream
			p.volume_db = -10.0
			add_child(p)
			audio_players[name] = p

func read_audio_pack() -> Dictionary:
	var result: Dictionary = {}
	var archive := "res://assets/packed_audio.b64"
	if not FileAccess.file_exists(archive): return result
	var raw := Marshalls.base64_to_raw(FileAccess.get_file_as_string(archive).strip_edges())
	var path := "user://boss_rush_audio_pack.zip"
	var writer := FileAccess.open(path, FileAccess.WRITE)
	if writer == null: return result
	writer.store_buffer(raw)
	writer.close()
	var zipper := ZIPReader.new()
	if zipper.open(path) != OK: return result
	for entry in zipper.get_files():
		if entry.ends_with(".ogg"):
			var key := entry.get_file().get_basename()
			result[key] = AudioStreamOggVorbis.load_from_buffer(zipper.read_file(entry))
	zipper.close()
	return result

func sfx(name: String, pitch: float = 1.0) -> void:
	if audio_players.has(name):
		var a: AudioStreamPlayer = audio_players[name]
		a.pitch_scale = pitch
		a.stop()
		a.play()

func load_progress() -> void:
	var save := ConfigFile.new()
	if save.load("user://boss_rush_save.cfg") == OK:
		wins = maxi(0, int(save.get_value("player", "wins", 0)))

func save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("player", "wins", wins)
	save.save("user://boss_rush_save.cfg")

func is_hero_unlocked(i: int) -> bool:
	return wins >= i

func start_battle() -> void:
	scene = "battle"
	paused = false
	battle_time = 0.0
	player_p = Vector2(640.0, 522.0)
	player_hp = 8 if selected_hero == 0 else 7 + selected_hero
	player_chakra = 20.0
	player_invuln = 1.8
	dash_cd = 0.0
	clone_cd = 0.0
	clone_time = 0.0
	clone_shot_cd = 0.0
	transform_stage = 0
	buff_time = 0.0
	shot_cd = 0.0
	special_cd = 0.0
	boss_hp = boss_max_hp
	boss_p = Vector2(640.0, 212.0)
	boss_phase = 1
	boss_clock = 0.0
	boss_intro = 2.6
	phase_banner = 0.0
	phase_shock = 0.0
	attack_cd = 1.2
	volley = 0
	score = 0
	grazes = 0
	bullets.clear()
	shots.clear()
	effects.clear()
	particles.clear()
	just_unlocked = ""
	victory = false
	sfx("boss_tell", 0.85)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = event.keycode
		if scene == "menu":
			if k == KEY_RIGHT or k == KEY_D:
				selected_hero = (selected_hero + 1) % 4
				sfx("pickup", 1.05)
			elif k == KEY_LEFT or k == KEY_A:
				selected_hero = (selected_hero + 3) % 4
				sfx("pickup", 0.85)
			elif k == KEY_ENTER or k == KEY_SPACE:
				if is_hero_unlocked(selected_hero):
					start_battle()
		elif scene == "battle":
			if k == KEY_ESCAPE or k == KEY_P:
				paused = not paused
			elif not paused:
				if k == KEY_X:
					attempt_dash()
				elif k == KEY_C:
					attempt_clone()
				elif k == KEY_Q:
					attempt_transform()
				elif k == KEY_SPACE:
					attempt_special()
		elif scene == "result":
			if k == KEY_R or k == KEY_ENTER:
				start_battle()
			elif k == KEY_ESCAPE or k == KEY_M:
				scene = "menu"
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if scene == "menu" and Rect2(488.0, 583.0, 304.0, 62.0).has_point(event.position) and is_hero_unlocked(selected_hero):
			start_battle()
		elif scene == "result" and Rect2(490.0, 562.0, 302.0, 59.0).has_point(event.position):
			start_battle()

func _process(dt: float) -> void:
	var delta := minf(dt, 0.05)
	time_s += delta
	if scene == "battle" and not paused:
		tick_battle(delta)
	if screen_shake > 0.0:
		screen_shake = maxf(0.0, screen_shake - 26.0 * delta)
	queue_redraw()

func run_logic_qa() -> void:
	# Deterministic mechanics smoke, only activated by --qa-logic.
	start_battle()
	player_chakra = 100.0
	attempt_transform()
	assert(transform_stage == 1, "first transformation did not activate")
	buff_time = 0.0
	player_chakra = 100.0
	attempt_transform()
	assert(transform_stage == 2, "second transformation did not activate")
	assert(boss_max_hp >= 8000.0, "boss duration below design target")
	clone_cd = 0.0
	player_chakra = 100.0
	attempt_clone()
	boss_intro = 0.0
	tick_battle(0.016)
	var count_after_first_tick := shots.size()
	tick_battle(0.016)
	assert(shots.size() <= count_after_first_tick + 2, "clone projectile flood")
	print("QA_LOGIC_PASS: staged_transformations=2, clone_rate_limited=true")
	get_tree().quit(0)

func tick_battle(dt: float) -> void:
	battle_time += dt
	boss_clock += dt
	player_invuln = maxf(0.0, player_invuln - dt)
	dash_cd = maxf(0.0, dash_cd - dt)
	clone_cd = maxf(0.0, clone_cd - dt)
	clone_time = maxf(0.0, clone_time - dt)
	clone_shot_cd = maxf(0.0, clone_shot_cd - dt)
	buff_time = maxf(0.0, buff_time - dt)
	shot_cd -= dt
	special_cd = maxf(0.0, special_cd - dt)
	phase_banner = maxf(0.0, phase_banner - dt)
	phase_shock = maxf(0.0, phase_shock - dt)
	boss_intro = maxf(0.0, boss_intro - dt)
	boss_p.x = 640.0 + sin(boss_clock * (0.8 + boss_phase * 0.14)) * (185.0 + boss_phase * 19.0)
	boss_p.y = 215.0 + sin(boss_clock * 1.45) * 18.0
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1.0
	if dir.length_squared() > 0.0:
		last_direction = dir.normalized()
		var rate := 165.0 if Input.is_key_pressed(KEY_SHIFT) else 310.0
		rate *= 1.0 + 0.04 * float(transform_stage)
		if buff_time > 0.0: rate *= 1.16
		player_p += last_direction * rate * dt
	player_p.x = clampf(player_p.x, ARENA.position.x + 22.0, ARENA.end.x - 22.0)
	player_p.y = clampf(player_p.y, 310.0, ARENA.end.y - 21.0)
	if boss_intro <= 0.0 and (Input.is_key_pressed(KEY_Z) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and shot_cd <= 0.0:
		shoot_rasengan()
		shot_cd = (0.14 if buff_time > 0.0 else 0.185) * (1.0 - 0.11 * float(transform_stage))
	if clone_time > 0.0 and clone_shot_cd <= 0.0 and boss_intro <= 0.0:
		clone_shot_cd = 0.50 if transform_stage == 0 else 0.42
		for signum in [-1, 1]:
			var launch := player_p + Vector2(float(signum) * 55.0, 28.0)
			shots.append({"p": launch, "v": (boss_p - launch).normalized() * 610.0, "age": 0.0, "r": 9.0, "dmg": 9.0, "clone": true})
	if boss_intro <= 0.0 and phase_shock <= 0.0:
		attack_cd -= dt
		if attack_cd <= 0.0:
			boss_attack()
	var next_shots: Array[Dictionary] = []
	for s in shots:
		s["age"] += dt
		s["p"] += s["v"] * dt
		if s["p"].distance_to(boss_p) < float(s["r"]) + 46.0 and boss_intro <= 0.0:
			boss_hp -= float(s["dmg"])
			player_chakra = minf(100.0, player_chakra + 1.2)
			score += 40
			fx(s["p"], 0.24, "hit", 15.0)
			if randi() % 7 == 0: sfx("water_hit", 1.1)
		elif s["age"] < 2.8 and ARENA.grow(60.0).has_point(s["p"]):
			next_shots.append(s)
	shots = next_shots
	var next_bullets: Array[Dictionary] = []
	for b in bullets:
		b["age"] += dt
		if absf(float(b["curve"])) > 0.02:
			b["v"] = b["v"].rotated(float(b["curve"]) * dt)
		if b["wave"]:
			b["v"] = b["v"].rotated(sin(float(b["age"]) * 6.0) * dt * 0.65)
		b["p"] += b["v"] * dt
		var dist: float = b["p"].distance_to(player_p)
		if dist < float(b["r"]) + 10.0 and player_invuln <= 0.0:
			player_hp -= 1
			player_invuln = 1.15
			screen_shake = 10.0
			fx(player_p, 0.6, "hurt", 52.0)
			sfx("impact")
			if player_hp <= 0:
				end_fight(false)
				return
		elif dist < float(b["r"]) + 31.0 and not b["graze"]:
			b["graze"] = true
			grazes += 1
			score += 20
			player_chakra = minf(100.0, player_chakra + 1.7)
			fx(player_p, 0.23, "graze", 16.0)
		if b["age"] < 8.0 and ARENA.grow(85.0).has_point(b["p"]):
			next_bullets.append(b)
	bullets = next_bullets
	if boss_phase == 1 and boss_hp <= boss_max_hp * 0.64:
		phase_shift(2)
	elif boss_phase == 2 and boss_hp <= boss_max_hp * 0.26:
		phase_shift(3)
	if boss_hp <= 0.0:
		end_fight(true)
		return
	for i in range(effects.size() - 1, -1, -1):
		effects[i]["t"] += dt
		if effects[i]["t"] >= effects[i]["ttl"]:
			effects.remove_at(i)
	if demo_mode and battle_time > 6.0:
		print("QA_SMOKE_PASS: player scene, boss scene, bullets=", bullets.size(), " hero_frames=", hero_frames["base"].size(), " zabuza_frames=", zabuza_frames.size())
		get_tree().quit(0)

func boss_attack() -> void:
	volley += 1
	var base_speed := 165.0 + float(boss_phase) * 34.0
	var n := 0
	var c := CYAN if boss_phase < 3 else Color("b787fa")
	var origin := boss_p + Vector2(0.0, 42.0)
	match boss_phase:
		1:
			match volley % 4:
				0: spawn_bullets(PATTERNS.ring(origin, 16, base_speed, float(volley) * 0.17, CYAN, 9.0))
				1: spawn_bullets(PATTERNS.fan(origin, player_p, 9, 1.0, base_speed + 45.0, Color("82ddfa")))
				2: spawn_bullets(PATTERNS.ring(origin, 12, base_speed - 18.0, float(volley) * 0.31, GOLD, 8.0))
				3: spawn_bullets(PATTERNS.fan(origin, player_p, 5, 0.32, base_speed + 100.0, CYAN, 12.0))
			attack_cd = 0.92
		2:
			if volley % 3 == 0:
				spawn_bullets(PATTERNS.spiral(origin, 23, float(volley) * 0.31, base_speed, c))
			elif volley % 3 == 1:
				spawn_bullets(PATTERNS.fan(origin, player_p, 13, 1.35, base_speed + 55.0, GOLD, 10.0))
			else:
				for i in range(9):
					var offset := Vector2(-290.0 + 72.0 * float(i), -120.0)
					spawn_bullets([PATTERNS.wave(boss_p + offset, Vector2(0.0, 1.0), base_speed + 20.0, CYAN)])
			attack_cd = 0.72
		3:
			spawn_bullets(PATTERNS.spiral(origin, 17, float(volley) * 0.36, base_speed + 22.0, c, 9.0))
			if volley % 2 == 0:
				spawn_bullets(PATTERNS.fan(origin, player_p, 11, 1.1, base_speed + 98.0, RED, 9.0))
			if volley % 3 == 0:
				for i in range(3):
					spawn_bullets(PATTERNS.aimed(origin + Vector2((float(i)-1.0)*100.0, 4.0), player_p, base_speed + 120.0, GOLD, 12.0))
			attack_cd = 0.49
	if volley % 3 == 0:
		sfx("water_cast", 0.8 + randf() * 0.28)

func spawn_bullets(group: Array) -> void:
	for b in group:
		if bullets.size() >= 430: return
		bullets.append(b)

func shoot_rasengan() -> void:
	var fire_dir := (boss_p - player_p).normalized()
	var spread := 0.10 if buff_time <= 0.0 else 0.15
	var shots_count := 1 + transform_stage
	for i in range(shots_count):
		var angle := (float(i) - float(shots_count-1)*0.5) * spread
		shots.append({"p": player_p + Vector2(0.0, -37.0), "v": fire_dir.rotated(angle) * 695.0, "age": 0.0, "r": 11.0 if buff_time <= 0.0 else 13.0, "dmg": 17.0 if buff_time <= 0.0 else 14.0, "clone": false})
	if randi() % 6 == 0: sfx("rasengan", 1.15)

func attempt_dash() -> void:
	if dash_cd > 0.0: return
	dash_cd = 1.8
	player_invuln = maxf(player_invuln, 0.34)
	player_p += last_direction * 128.0
	player_p.x = clampf(player_p.x, ARENA.position.x + 22.0, ARENA.end.x - 22.0)
	player_p.y = clampf(player_p.y, 310.0, ARENA.end.y - 21.0)
	screen_shake = 3.5
	fx(player_p, 0.32, "dash", 48.0)
	sfx("dash")

func attempt_clone() -> void:
	if clone_cd > 0.0 or player_chakra < 22.0: return
	player_chakra -= 22.0
	clone_time = 8.0
	clone_shot_cd = 0.0
	clone_cd = 18.0
	fx(player_p, 0.6, "smoke", 80.0)
	sfx("clone_smoke")

func attempt_transform() -> void:
	if player_chakra < 90.0 or transform_stage >= 2 or buff_time > 0.0: return
	player_chakra = 0.0
	transform_stage += 1
	buff_time = 8.0
	player_invuln = maxf(player_invuln, 1.4)
	phase_shock = maxf(phase_shock, 0.7)
	bullets.clear()
	screen_shake = 15.0
	fx(player_p, 1.6, "transform", 100.0)
	sfx("transform")

func attempt_special() -> void:
	if special_cd > 0.0 or player_chakra < 35.0: return
	special_cd = 9.0
	player_chakra -= 35.0
	boss_hp -= 135.0 if buff_time <= 0.0 else 245.0
	bullets.clear()
	screen_shake = 15.0
	fx(boss_p, 0.9, "special", 110.0)
	sfx("rasengan", 0.64)

func phase_shift(next_phase: int) -> void:
	boss_phase = next_phase
	phase_banner = 2.2
	phase_shock = 1.5
	boss_clock = 0.0
	bullets.clear()
	attack_cd = 0.9
	screen_shake = 18.0
	fx(boss_p, 1.5, "boss_shift", 170.0)
	sfx("boss", 0.75 if next_phase == 3 else 1.0)

func end_fight(won: bool) -> void:
	scene = "result"
	victory = won
	if won:
		wins += 1
		save_progress()
		if wins <= 3:
			just_unlocked = HERO_NAMES[wins]
		sfx("boss")
	else:
		sfx("impact", 0.8)

func fx(at: Vector2, lifespan: float, kind: String, radius: float) -> void:
	effects.append({"p": at, "ttl": lifespan, "t": 0.0, "kind": kind, "r": radius})

func _draw() -> void:
	draw_background()
	if scene == "menu":
		draw_menu()
	elif scene == "battle":
		draw_battle()
	elif scene == "result":
		draw_battle()
		draw_result()

func draw_background() -> void:
	draw_rect(Rect2(0.0, 0.0, W, H), BG)
	for i in range(14):
		var x := float(i) * 106.0 + sin(time_s * 0.18 + float(i) * 3.0) * 14.0
		draw_line(Vector2(x, 100.0), Vector2(x - 95.0, 600.0), Color(0.24, 0.49, 0.52, 0.10), 1.0)
	for i in range(8):
		var yy := 142.0 + float(i) * float(i) * 9.0
		draw_line(Vector2(75.0, yy), Vector2(1205.0, yy), Color(0.38, 0.72, 0.73, 0.06), 1.0)
	for i in range(21):
		var x := float(i) * 66.0 - 45.0
		var base_y := 133.0 + sin(float(i) * 3.2) * 35.0
		var tall := 37.0 + float(i % 6) * 15.0
		draw_colored_polygon(PackedVector2Array([Vector2(x-16,base_y),Vector2(x+14,base_y),Vector2(x+3,base_y-tall)]),Color(0.13,0.23,0.26,0.45))
	for i in range(26):
		var nx := fposmod(float(i) * 173.0 + time_s * (7.0 + float(i%3)*4.0), W)
		var ny := 99.0 + fposmod(float(i * 53), 500.0)
		draw_circle(Vector2(nx, ny), 1.0 + float(i % 2), Color(0.51,0.89,0.89,0.15))
	draw_rect(ARENA, Color("0c1a25"), false, 2.0)
	draw_line(Vector2(80.0, 612.0), Vector2(1200.0, 612.0), CYAN.darkened(0.72), 2.0)
	for i in range(9):
		var v := float(i) * 74.0
		var p := Vector2(160.0 + v * 1.32, 580.0)
		draw_line(p, p + Vector2(-90.0, 14.0), Color(0.27,0.70,0.76,0.12),1.0)
	if boss_phase > 1 and (scene == "battle" or scene == "result"):
		for i in range(8):
			var mist_y := 170.0 + float(i) * 67.0
			var mx := sin(time_s * 0.7 + float(i) * 2.2) * 92.0
			draw_rect(Rect2(75.0 + mx, mist_y, 1110.0, 22.0), Color(0.72,0.88,0.94,0.048 if boss_phase == 2 else 0.07))

func label(text: String, p: Vector2, size: int = 20, color: Color = PALE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ui_font, p, text, align, -1.0, size, color)

func panel(rect: Rect2, fill: Color = INK, stroke: Color = CYAN) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, stroke.darkened(0.4), false, 1.5)

func draw_menu() -> void:
	draw_rect(Rect2(0.0,0.0,W,86.0),Color("080d16"))
	label("SHINOBI // BOSS RUSH",Vector2(76.0,45.0),29,GOLD)
	label("ALPHA 01  /  HIDDEN MIST INCIDENT",Vector2(79.0,68.0),13,CYAN)
	label("THE GAUNTLET",Vector2(78.0,140.0),46,PALE)
	label("Choose your shinobi. Defeat the boss. Unlock new forms.",Vector2(81.0,170.0),17,Color("9bb2bd"))
	for i in range(4):
		var x := 78.0 + float(i) * 286.0
		var rect := Rect2(x,205.0,270.0,290.0)
		var sel := i == selected_hero
		panel(rect,Color("1c2b36") if sel else Color("101b28"), GOLD if sel else Color("365361"))
		if sel: draw_rect(Rect2(x+4.0,209.0,262.0,4.0),GOLD)
		var unlocked := is_hero_unlocked(i)
		var show_form := FORM_IDS[i]
		var frames: Array = hero_frames.get(show_form,[])
		if frames.size() > 0:
			var idx := (int(time_s*5.0)% mini(frames.size(),3))
			draw_character(frames[idx],Vector2(x+135.0,364.0),166.0,Color.WHITE if unlocked else Color(0.23,0.31,0.35,0.58))
		label(HERO_NAMES[i],Vector2(x+14.0,448.0),18,GOLD if sel else PALE)
		label("READY" if unlocked else "LOCKED // %d CLEAR(S)" % i,Vector2(x+14.0,478.0),14,CYAN if unlocked else RED)
	label("A / D   SELECT CHARACTER",Vector2(82.0,548.0),16,CYAN)
	label("X DASH     C CLONES     Q TRANSFORM     SPACE SPECIAL",Vector2(82.0,573.0),14,Color("9bb2bd"))
	var can_start := is_hero_unlocked(selected_hero)
	panel(Rect2(488.0,583.0,304.0,62.0),Color("bc8c58") if can_start else Color("353842"),GOLD if can_start else RED)
	label("ENTER  //  START" if can_start else "DEFEAT BOSS TO UNLOCK",Vector2(517.0,624.0),23,Color("0b151c") if can_start else PALE)
	label("BOSS 01 / ZABUZA",Vector2(984.0,548.0),17,GOLD)
	label("NEXT: KISAME, ITACHI, PAIN",Vector2(953.0,578.0),13,CYAN)
	label("TOTAL CLEARS  %02d" % wins,Vector2(82.0,680.0),15,GOLD)
	label("BETA ROSTER: SASUKE / SAKURA / KAKASHI",Vector2(833.0,680.0),13,Color("7c9299"))

func draw_battle() -> void:
	var shift := Vector2(randf_range(-screen_shake,screen_shake),randf_range(-screen_shake,screen_shake)) if screen_shake > 1.0 else Vector2.ZERO
	if boss_phase >= 3:
		draw_circle(boss_p+shift,115.0 + sin(time_s*7.0)*11.0, Color(0.44,0.11,0.54,0.2))
	elif boss_phase == 2:
		draw_circle(boss_p+shift,95.0 + sin(time_s*5.0)*7.0,Color(0.3,0.78,0.81,0.12))
	for b in bullets:
		var p: Vector2 = b["p"]
		var radius: float = b["r"]
		var tint: Color = b["c"]
		draw_circle(p,radius+5.0,tint * Color(1.0,1.0,1.0,0.16))
		draw_circle(p,radius,tint)
		draw_circle(p,radius*0.47,PALE)
		if b["wave"]:
			draw_arc(p,radius+7.0,0.1,PI*1.8,16,CYAN,2.0,true)
	for s in shots:
		var pos: Vector2 = s["p"]
		var r: float = s["r"]
		var tint := GOLD if buff_time>0.0 else CYAN
		draw_circle(pos,r*1.5,tint * Color(1.0,1.0,1.0,0.22))
		draw_arc(pos,r,0.0,TAU,16,tint,3.0,true)
		draw_circle(pos,r*0.4,PALE)
	for effect in effects:
		draw_effect(effect)
	# Boss rendering: first human, then enraged mist and demon aura.
	var boss_idx := 0
	if boss_phase == 1: boss_idx = [0,4,5,6][int(time_s * 6.0) % 4]
	elif boss_phase == 2: boss_idx = [8,9,10,11,12][int(time_s * 8.0) % 5]
	else: boss_idx = [16,17,18,19,20][int(time_s * 9.0) % 5]
	if zabuza_frames.size() > boss_idx:
		draw_character(zabuza_frames[boss_idx],boss_p+shift,150.0,Color.WHITE)
	if boss_phase == 3:
		draw_arc(boss_p+shift,78.0+sin(time_s*3.2)*5.0,0.0,TAU,54,Color("b46de7"),3.5,true)
	if clone_time > 0.0:
		for side in [-1.0,1.0]:
			draw_hero(player_p+Vector2(side*55.0,28.0),Color(0.57,0.8,0.9,0.54),0.75)
	if transform_stage > 0:
		var aura_rad := 43.0 + float(transform_stage) * 12.0 + sin(time_s * 9.0) * 4.0
		draw_circle(player_p, aura_rad + 15.0, Color(1.0, 0.29, 0.10, 0.08 if transform_stage == 1 else 0.16))
		draw_arc(player_p, aura_rad, 0.0, TAU, 32, Color("fd7651") if transform_stage == 1 else Color("f34341"), 2.8 + float(transform_stage), true)
	if buff_time > 0.0:
		draw_arc(player_p, 72.0, -PI*0.4, PI*1.4, 35, GOLD, 3.0, true)
	if player_invuln <= 0.0 or int(player_invuln*12.0)%2 == 0:
		draw_hero(player_p,Color.WHITE,1.0)
	# The precise hitbox is visualized during focus.
	if Input.is_key_pressed(KEY_SHIFT):
		draw_circle(player_p,5.5,RED)
		draw_arc(player_p,12.0,0.0,TAU,24,GOLD,1.5,true)
	draw_battle_ui()
	if phase_banner > 0.0:
		draw_rect(Rect2(0.0,298.0,W,105.0),Color(0.05,0.1,0.16,0.91))
		label("HIDDEN MIST TECHNIQUE" if boss_phase == 2 else "DEMON OF THE HIDDEN MIST",Vector2(275.0,361.0),34,GOLD)
	if boss_intro > 0.0:
		draw_rect(Rect2(0.0,290.0,W,112.0),Color(0.03,0.07,0.12,0.84))
		label("ROUND 01    /    THE DEMON OF THE MIST",Vector2(236.0,354.0),34,PALE)
	if paused:
		draw_rect(Rect2(0.0,0.0,W,H),Color(0.02,0.04,0.08,0.76))
		label("PAUSED",Vector2(521.0,337.0),54,GOLD)
		label("ESC / P TO RESUME",Vector2(524.0,378.0),19,CYAN)

func draw_hero(pos: Vector2, mod: Color = Color.WHITE, mul: float = 1.0) -> void:
	var name: String = FORM_IDS[selected_hero]
	if selected_hero == 0 and transform_stage >= 2: name = "kyuubi"
	elif selected_hero == 2 and transform_stage >= 2: name = "kcm"
	var a: Array = hero_frames.get(name,[])
	if a.is_empty():return
	var idx := 0
	if name == "base": idx = [0,1,2][int(time_s * 5.0) % 3]
	else: idx = int(time_s * 6.0) % mini(a.size(),3)
	draw_character(a[idx],pos,100.0*mul,mod)

func draw_character(tex: Texture2D, middle: Vector2, max_height: float, mod: Color = Color.WHITE) -> void:
	if tex == null: return
	var raw := tex.get_size()
	if raw.y < 1.0: return
	var factor: float = minf(max_height/raw.y,130.0/raw.x)
	var rect := Rect2(middle - raw*factor*0.5,raw*factor)
	draw_texture_rect(tex,rect,false,mod)

func draw_effect(e: Dictionary) -> void:
	var f: float = clampf(float(e["t"]) / float(e["ttl"]),0.0,1.0)
	var pos: Vector2 = e["p"]
	var radius: float = float(e["r"]) * (0.15 + f * 1.2)
	match str(e["kind"]):
		"hit", "graze": draw_arc(pos,radius,0.0,TAU,18,CYAN * Color(1.0,1.0,1.0,1.0-f),2.0,true)
		"dash": draw_arc(pos,radius,0.0,TAU,30,PALE * Color(1.0,1.0,1.0,1.0-f),4.0,true)
		"hurt": draw_arc(pos,radius,0.0,TAU,28,RED * Color(1.0,1.0,1.0,1.0-f),6.0,true)
		"smoke": draw_circle(pos,radius,Color(0.7,0.88,0.92,(1.0-f)*0.24))
		"transform":
			draw_arc(pos,radius,0.0,TAU,54,Color(1.0,0.38,0.13,1.0-f),8.0,true)
			draw_line(pos+Vector2(0.0,-radius),pos+Vector2(0.0,radius),Color(1.0,0.65,0.28,1.0-f),4.0)
		"special":
			draw_circle(pos,radius,Color(0.34,0.79,0.96,0.24*(1.0-f)))
			draw_arc(pos,radius,0.0,TAU,46,CYAN * Color(1.0,1.0,1.0,1.0-f),7.0,true)
		"boss_shift":
			draw_arc(pos,radius,0.0,TAU,46,Color(0.7,0.3,0.94,1.0-f),8.0,true)

func draw_battle_ui() -> void:
	draw_rect(Rect2(0.0,0.0,W,89.0),Color("080e18"))
	label("BOSS 01",Vector2(75.0,31.0),13,GOLD)
	label("ZABUZA MOMOCHI",Vector2(75.0,59.0),27,PALE)
	label("PHASE %d / 3" % boss_phase,Vector2(994.0,30.0),14,GOLD)
	label("%02d:%02d" % [int(battle_time)/60,int(battle_time)%60],Vector2(1135.0,63.0),18,PALE)
	draw_rect(Rect2(405.0,39.0,551.0,18.0),Color("344554"))
	draw_rect(Rect2(407.0,41.0,547.0*clampf(boss_hp/boss_max_hp,0.0,1.0),14.0),RED if boss_phase==3 else CYAN)
	draw_line(Vector2(405.0+551.0*0.36,39.0),Vector2(405.0+551.0*0.36,57.0),PALE,1.0)
	draw_line(Vector2(405.0+551.0*0.74,39.0),Vector2(405.0+551.0*0.74,57.0),PALE,1.0)
	draw_rect(Rect2(0.0,620.0,W,100.0),Color("09131e"))
	label("NARUTO",Vector2(80.0,647.0),16,GOLD)
	for i in range(maxi(8, 7 + selected_hero)):
		var filled := i < player_hp
		draw_rect(Rect2(80.0+float(i)*27.0,659.0,21.0,19.0),RED if filled else Color("2c3948"))
	label("CHAKRA",Vector2(335.0,648.0),14,CYAN)
	draw_rect(Rect2(334.0,661.0,225.0,13.0),Color("2c3948"))
	draw_rect(Rect2(336.0,663.0,221.0*player_chakra/100.0,9.0),CYAN)
	var transform_label := "Q // MAX FORM" if transform_stage >= 2 else ("Q // AWAKEN %d" % (transform_stage + 1) if player_chakra >= 90.0 else "Q // 90 CHAKRA")
	label(transform_label,Vector2(335.0,690.0),14,GOLD if player_chakra>=90.0 and transform_stage < 2 else Color("8598a3"))
	label("Z  RASENGAN",Vector2(624.0,648.0),15,PALE)
	label("X  DASH  %s" % ("READY" if dash_cd<=0 else "%.1f"%dash_cd),Vector2(624.0,676.0),14,GOLD if dash_cd <= 0.0 else Color("8598a3"))
	label("C  CLONES  %s" % ("READY" if clone_cd<=0 else "%.1f"%clone_cd),Vector2(852.0,648.0),15,CYAN if clone_cd<=0 else Color("8598a3"))
	label("SPACE  ULTIMATE  %s" % ("READY" if special_cd<=0.0 else "%.1f"%special_cd),Vector2(852.0,676.0),14,GOLD if special_cd<=0 else Color("8598a3"))
	label("GRAZE %03d   SCORE %06d" % [grazes,score],Vector2(80.0,706.0),13,Color("9aaeb6"))
	label("SHIFT // FOCUS",Vector2(1066.0,703.0),13,CYAN)
	if transform_stage > 0:
		label("KYUUBI SIGN" if transform_stage == 1 else "ONE TAIL CLOAK",Vector2(465.0,116.0),20,GOLD)
	if buff_time>0:
		label("AWAKENING BURST %.0fs" % buff_time,Vector2(465.0,141.0),15,CYAN)

func draw_result() -> void:
	draw_rect(Rect2(0.0,0.0,W,H),Color(0.025,0.047,0.074,0.86))
	panel(Rect2(321.0,128.0,638.0,516.0),Color("101f2c"),GOLD if victory else RED)
	label("MISSION COMPLETE" if victory else "MISSION FAILED",Vector2(403.0,220.0),38,GOLD if victory else RED)
	label("THE DEMON OF THE MIST",Vector2(454.0,273.0),21,PALE)
	label("TIME     %02d:%02d" % [int(battle_time)/60,int(battle_time)%60],Vector2(459.0,331.0),19,CYAN)
	label("GRAZES   %03d" % grazes,Vector2(459.0,365.0),19,CYAN)
	label("SCORE    %07d" % score,Vector2(459.0,399.0),19,CYAN)
	if victory:
		label("UNLOCKED: " + just_unlocked if not just_unlocked.is_empty() else "BOSS DEFEATED  //  +1 CLEAR",Vector2(393.0,461.0),21,GOLD)
	else:
		label("READ THE PATTERNS. TRY AGAIN.",Vector2(432.0,461.0),18,RED)
	panel(Rect2(490.0,562.0,302.0,59.0),Color("aa8655"),GOLD)
	label("R / ENTER  //  RETRY",Vector2(506.0,599.0),22,Color("101821"))
	label("ESC // CHARACTER SELECT",Vector2(496.0,534.0),14,CYAN)
