extends SceneTree
var g
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        push_error("QA_FAIL: "+message)
        quit(1)
        assert(false,message)
    checks+=1
func run() -> void:
    g=load("res://scenes/main.tscn").instantiate()
    root.add_child(g)
    g.muted=true
    g.godmode=true
    g._start()
    g.set_process(false)
    g.rng.seed=7149
    for name in ["naruto_base","naruto_sage","naruto_kcm","sound_heavy","sound_pole","sound_scythe","sound_mirror","sasori"]:
        var base := "res://assets/mugen/%s/" % name
        var m=JSON.parse_string(FileAccess.get_file_as_string(base+"manifest.json"))
        for action in m.actions:
            for frame in m.actions[action]:
                check(m.sprites.has(frame.key),"Missing frame "+name+"/"+frame.key)
                var img:=Image.new()
                check(img.load_png_from_buffer(FileAccess.get_file_as_bytes(base+m.sprites[frame.key].file))==OK,"Invalid PNG")
                check(img.get_width()==m.sprites[frame.key].size[0],"Manifest size")
                check(not img.get_used_rect().has_area()==false,"Empty sprite")
    g.player.facing=-1
    g.player.tick(0.001)
    check(g.player.sprite.flip_h,"Immediate left flip")
    g.player.facing=1
    g.player.tick(0.001)
    check(not g.player.sprite.flip_h,"Immediate right flip")
    g._open_upgrade(false)
    var clock_before:float=g.clock
    g._process(0.05)
    check(g.clock==clock_before,"Upgrade must pause mission")
    var skill:String=g.selected_cards[0].stat
    g._choose_card(0)
    check(g.upgrades[skill]==1 and not g.picking,"Card applies once and closes")
    g._choose_card(0)
    check(g.upgrades[skill]==1,"No double application")
    g.paused=true
    g._process(0.05)
    check(g.clock==clock_before,"Pause clock")
    g.paused=false
    var reached_sage := false
    var reached_kcm := false
    var boss_ticks := 0
    for i in range(16000):
        if g.picking:g._choose_card(i%g.selected_cards.size())
        var t := float(i)/60.0
        g.player_pos=Vector2(sin(t*0.37)*260,cos(t*0.27)*190)
        if i%780==0:g._spawn_clones()
        g._process(1.0/60.0)
        if g.player_form==1:reached_sage=true
        if g.player_form==2:reached_kcm=true
        if g.boss_active and not g.finished:
            boss_ticks+=1
            # Exercise boss damage/phase transitions through the actual API.
            if boss_ticks%180==0:g._damage_target(g.boss,float(g.boss.max_hp)*0.12)
        if i%120==0:await process_frame
        if g.finished:break
    check(reached_sage and reached_kcm,"Both timed transformations")
    check(g.boss_phase_reached==3,"Three Sasori phases")
    check(g.finished and g.ui_view.victory,"Mission victory")
    check(g.boss_attack_history.size()>=3,"Boss attacks ran")
    print("QA_MISSION_PASS checks=%d time=%.2f kills=%d level=%d phases=%d" % [checks,g.clock,g.stat_kills,g.level,g.boss_phase_reached])
    g.queue_free()
    await process_frame
    quit(0)
