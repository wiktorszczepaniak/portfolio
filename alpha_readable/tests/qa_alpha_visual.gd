extends SceneTree
## Native Windows render previews for all six MUGEN selections and the talent tree.
var output:String=""
func _initialize()->void:call_deferred("run")
func snap(name:String)->void:
 await process_frame
 await RenderingServer.frame_post_draw
 var err:Error=root.get_texture().get_image().save_png(output+"/"+name+".png")
 if err!=OK:printerr("ALPHA_VISUAL_SAVE_FAIL: ",name," code=",err)
func run()->void:
 var args:PackedStringArray=OS.get_cmdline_user_args()
 output=str(args[0]) if not args.is_empty() else "user://"
 DirAccess.make_dir_recursive_absolute(output)
 var build=root.get_node("RunBuild")
 build.reset(47821);build.muted=true
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await snap("01_menu_naruto")
 for id in ["sasuke","kakashi","rock_lee","neji","gaara"]:
  game.choose_character(id)
  await process_frame
  await snap("02_hero_"+id)
 game.choose_character("sasuke")
 game._start(47821)
 game.muted=true;game.godmode=true
 await process_frame
 game.alpha.points=30;game.alpha.tree_tab=0;game.alpha.tree_open=true
 await process_frame
 await snap("08_talents_sasuke")
 game.alpha.tree_open=false
 await process_frame
 await snap("09_game_sasuke")
 game.queue_free()
 await process_frame
 root.get_node("AudioDirector").silence()
 print("ALPHA_VISUAL_DONE: 9 screenshots")
 quit(0)
