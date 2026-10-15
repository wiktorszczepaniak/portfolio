extends SceneTree
var g
var out := ""
func _initialize() -> void:
    call_deferred("run")
func shot(name: String) -> void:
    for i in range(12): await process_frame
    await RenderingServer.frame_post_draw
    var error := root.get_texture().get_image().save_png(out+"/"+name+".png")
    assert(error==OK)
func run() -> void:
    out = OS.get_cmdline_user_args()[0]
    DirAccess.make_dir_recursive_absolute(out)
    root.size=Vector2i(1280,720)
    g=load("res://scenes/main.tscn").instantiate()
    root.add_child(g)
    g.muted=true
    await shot("title")
    g._start()
    g.godmode=true
    g.set_process(false)
    g.camera.position_smoothing_enabled=false
    g.rng.seed=3319
    for i in range(12):
        g._spawn_enemy(false)
        var e=g.enemies[-1]
        e.pos=Vector2.from_angle(i*TAU/12)*Vector2(300,170)+Vector2(0,70)
        e.actor.position=e.pos
        e.actor.moving=true
        e.actor.facing=-1 if e.pos.x>0 else 1
        e.actor.tick(0.16)
    g.clock=64.0
    g.stat_kills=29
    g.level=4
    g.exp_value=18.0
    g.player_hp=98.0
    for i in range(15):
        g.drops.append({"pos":Vector2.from_angle(i*0.45)*Vector2(160,110)+Vector2(30,50),"type":"xp","value":3.0})
    g._update_hud()
    g.queue_redraw()
    await shot("gameplay")
    g._open_upgrade(true)
    g.selected_cards.assign([{"stat":"rasengan","tier":1},{"stat":"naruto_rendan","tier":2},{"stat":"sage_focus","tier":3}])
    for i in range(45): await process_frame
    await shot("scrolls")
    g._choose_card(0)
    g.upgrades["naruto_rendan"]=2
    g.upgrades["clones"]=2
    g._spawn_clones()
    for c in g.clones:
        c.actor.pose_action="210"
        c.actor.pose_time=0.4
        c.actor.tick(0.16)
    g._update_hud()
    g.event_time=0.0
    await shot("clones")
    g._complete_transform(1)
    g.clock=130.0
    g._update_hud()
    g.queue_redraw()
    await shot("sage")
    g._complete_transform(2)
    g.clock=485.0
    g._spawn_boss()
    g.boss.pos=Vector2(215,35)
    g.boss.actor.position=g.boss.pos
    g.boss.actor.facing=-1
    g.boss.actor.tick(0.1)
    g._update_hud()
    g.queue_redraw()
    await shot("boss")
    g.paused=true
    await shot("pause")
    g._finish(true)
    await shot("result")
    g.queue_free()
    await process_frame
    print("QA_VISUAL_PASS")
    quit(0)
