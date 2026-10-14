extends SceneTree
var out:String
func _initialize() -> void:call_deferred("run")
func capture(name:String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run() -> void:
 out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out+"/film")
 var build=root.get_node("RunBuild");build.muted=true
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
 await capture("01_v11_menu");game._start(714);game.godmode=true;game.muted=true
 for id in ["rasengan","naruto_rendan","gama_teppo"]:
  for i in range(3):game._grant_upgrade(id)
 game._grant_upgrade("kage_bunshin")
 for i in range(240):game._process(1.0/60)
 await capture("02_desert");game.queue_free();await process_frame
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.select_map("forest");game._start(714);game.godmode=true;game.muted=true
 for id in ["rasengan","shuriken_barrage","gama_teppo"]:game._grant_upgrade(id)
 for i in range(240):game._process(1.0/60)
 await capture("03_forest");game.queue_free();await process_frame
 build.reset(714);build.godmode=true;build.muted=true;build.form_branch="kyubi";build.form_stage=2
 for id in ["rasengan","naruto_rendan","gama_teppo"]:
  for i in range(3):build.grant(id)
 build.grant("gama_teppo:suiton_wave");build.grant("kage_bunshin")
 var duel=load("res://scenes/boss_duel.tscn").instantiate();root.add_child(duel);duel.set_process(false)
 await capture("04_loadout");duel.start_fight();duel.player_pos.x=750
 for frame in range(900):
  for substep in range(4):
   var distance=duel.boss.pos.x-duel.player_pos.x
   var commands={"move":signf(distance) if absf(distance)>85 else 0.0,"combo":true}
   if frame%15==0 and substep==0:commands.slot=(frame/15)%3;commands.utility=frame%90==0
   if frame%120==90 and substep==0:commands.jump=true
   duel.step(1.0/60,commands)
  await capture("film/%04d"%frame)
  if frame in [30,150,350,600]:await capture("05_contact_%03d"%frame)
  if frame==450:
   duel.ai.phase_two();duel.boss.hp=6300;duel.boss.max_hp=6300;duel.boss.actor.set_pack("sasori_puppet");duel.ai.phase_pause=0
 await capture("06_phase_two");duel.queue_free();await process_frame
 root.get_node("AudioDirector").silence();await create_timer(0.15).timeout
 print("V11_VISUAL_DONE scripted 60 seconds at 60 Hz, captured 15 FPS; audio muted")
 quit()
