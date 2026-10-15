extends Node2D
## Anchored frame animation. AIR offsets, mirroring and timing share one code path.
static var manifests: Dictionary = {}
static var textures: Dictionary = {}
var pack_name := ""
var pack_root := ""
var manifest: Dictionary = {}
var actions: Dictionary = {}
var images: Dictionary = {}
var atlas_frame := 0
var frame_time := 0.0
var action := "0"
var facing := 1.0
var moving := false
var dashing := false
var pose_action := "200"
var pose_time := 0.0
var pose_total := 0.0
var previous_pose := 0.0
var pose_restart := false
var attack := false
var form_tint := Color.WHITE
var fallback_color := Color("eb8429")
var sprite: Sprite2D
var absent := true
var sprite_scale := 1.3333333
var form_style := 0
var hit_flash := 0.0

func _ready() -> void:
    sprite = Sprite2D.new()
    sprite.centered = false
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(sprite)
    set_pack(pack_name)

func set_pack(next_pack: String) -> void:
    pack_name = next_pack
    pack_root = "res://assets/mugen/%s/" % pack_name
    form_style = 3 if pack_name == "naruto_sennin" else 1 if pack_name == "naruto_sage" else 2 if pack_name == "naruto_kcm" else 0
    if sprite == null: return
    if not manifests.has(pack_name):
        if FileAccess.file_exists(pack_root + "manifest.json"):
            var parsed = JSON.parse_string(FileAccess.get_file_as_string(pack_root + "manifest.json"))
            if parsed is Dictionary: manifests[pack_name] = parsed
    manifest = manifests.get(pack_name, {})
    actions = manifest.get("actions", {})
    images = manifest.get("sprites", {})
    sprite_scale = float(manifest.get("display_scale", 1.3333333))
    absent = actions.is_empty()
    sprite.texture = null
    pose_time = 0.0
    previous_pose = 0.0
    action = ""
    set_action("0")
    queue_redraw()

func set_action(requested: String) -> void:
    if actions.is_empty(): return
    var next := requested if actions.has(requested) else "20" if moving and actions.has("20") else "0"
    if next == action and sprite.texture != null: return
    action = next
    atlas_frame = 0
    frame_time = 0.0
    _paint_frame()

func play_pose(requested:String,duration:float) -> void:
    pose_action=requested;pose_time=duration;pose_restart=true

func tick(dt: float) -> void:
    if absent: return
    hit_flash = maxf(0.0, hit_flash - dt)
    var target := "100" if dashing and actions.has("100") else "20" if moving else "0"
    var one_shot := pose_time > 0.0
    if one_shot:
        target = pose_action if actions.has(pose_action) else "200"
        if pose_restart or pose_time > previous_pose + 0.065 or target != action:
            pose_total = pose_time
            action = ""
        pose_time = maxf(0.0, pose_time - dt)
    elif attack and actions.has("200"):
        target = "200"
    set_action(target)
    pose_restart=false
    previous_pose = pose_time
    var frames: Array = actions.get(action, [])
    if frames.is_empty(): return
    var duration := 0.0
    for entry in frames: duration += maxf(1.0, float(entry.get("ticks", 6)))
    frame_time += dt
    var loops := 0
    var minimum := minf(1.0/60.0, pose_total/maxi(1,frames.size())) if one_shot else 0.0
    var remaining := maxf(0.0,pose_total-minimum*frames.size())
    var frame_duration := minimum+remaining*maxf(1.0,float(frames[atlas_frame].get("ticks",6)))/duration if one_shot else maxf(1.0,float(frames[atlas_frame].get("ticks",6)))/60.0
    while frame_time >= frame_duration and loops < 30:
        frame_time -= frame_duration
        if one_shot and atlas_frame == frames.size() - 1:
            frame_time = 0.0
            break
        atlas_frame = (atlas_frame + 1) % frames.size()
        frame_duration = minimum+remaining*maxf(1.0,float(frames[atlas_frame].get("ticks",6)))/duration if one_shot else maxf(1.0,float(frames[atlas_frame].get("ticks",6)))/60.0
        loops += 1
    # Always recompute pivot on facing changes, even between animation frames.
    _paint_frame()

func _paint_frame() -> void:
    var frames: Array = actions.get(action, [])
    if frames.is_empty(): return
    var entry: Dictionary = frames[atlas_frame]
    var info: Dictionary = images.get(str(entry.get("key", "")), {})
    if info.is_empty(): return
    var path := pack_root + str(info.get("file", ""))
    if not textures.has(path):
        var img := Image.new()
        if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK: return
        textures[path] = ImageTexture.create_from_image(img)
    sprite.texture = textures[path]
    var axis: Array = info.get("axis", [0, 0])
    var size: Array = info.get("size", [0, 0])
    var mirrored := (facing < 0.0) != bool(entry.get("flip_h", false))
    var flipped := bool(entry.get("flip_v", false))
    var x := float(axis[0]) - float(size[0]) if mirrored else -float(axis[0])
    var y := float(axis[1]) - float(size[1]) if flipped else -float(axis[1])
    x += float(entry.get("x", 0)) * (-1.0 if facing < 0.0 else 1.0)
    y += float(entry.get("y", 0))
    sprite.position = (Vector2(x, y) * sprite_scale).round()
    sprite.scale = Vector2.ONE * sprite_scale
    sprite.flip_h = mirrored
    sprite.flip_v = flipped
    sprite.modulate = form_tint.lerp(Color(2.1,1.8,1.5,form_tint.a), minf(1.0,hit_flash*8.0))

func _draw() -> void:
    if absent: return
    draw_set_transform(Vector2(0,-1),0.0,Vector2(1.0,0.25))
    draw_circle(Vector2.ZERO,15.0,Color(0.12,0.08,0.05,0.23))
    draw_set_transform(Vector2.ZERO)
