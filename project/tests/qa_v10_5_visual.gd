extends SceneTree
var out:String
func _initialize():call_deferred("run")
func snap(name:String):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 var state=root.get_node("RunBuild");state.muted=true
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 await snap("01_menu_desert_selected");g.select_map("forest");await snap("02_menu_forest_selected");g.select_map("desert");g._start();g.muted=true;g.godmode=true
 await snap("03_desert_play");g._open_draft("utility");await snap("03_four_utilities");g._choose_card(0)
 g._open_draft("new");await snap("04_three_jutsu");g._choose_card(0)
 g.picking=false;g.form_choice=true;await snap("05_forms");g._choose_form(1);g._complete_transform(1)
 for i in range(3):g._grant_upgrade("naruto_rendan")
 g._grant_upgrade("gama_teppo");g._grant_upgrade("naruto_rendan:nisen")
 g._open_chest();g.gacha_revealed=true;g.gacha_elapsed=3;await snap("06_chest");g._choose_chest_reward(0)
 for i in range(180):g._process(1.0/60)
 g.picking=false;await snap("07_combat");g.queue_free();await process_frame
 var duel=load("res://scenes/boss_duel.tscn").instantiate();root.add_child(duel);duel.set_process(false)
 await snap("08_duel_build");duel.start_fight();duel.player_pos.x=710;duel.skills.cast_slot(0)
 for i in range(20):duel.step(1.0/60)
 await snap("09_hiruko")
 state.grant("gama_teppo");state.grant("gama_teppo");state.grant("gama_teppo");state.grant("gama_teppo:suiton_wave")
 duel.skills.reset();duel.skills.cast("gama_teppo")
 for i in range(34):duel.skills.tick(1.0/60)
 await snap("09b_suiton_dragon")
 duel.ai.phase_two();duel.boss.actor.set_pack("sasori_puppet");duel.ai.phase_pause=0
 for i in range(120):duel.step(1.0/60)
 await snap("10_sasori");duel.finish(false);await snap("11_retry")
 print("VISUAL_DONE");quit()
