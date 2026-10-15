extends SceneTree
## Native render previews for all new class choices and the interactive tree.
var out:String
func _initialize()->void:
 call_deferred("run")
func snap(name:String)->void:
 await process_frame
 await RenderingServer.frame_post_draw
 var err:Error=root.get_texture().get_image().save_png(out+"/"+name+".png")
 if err!=OK:printerr("ALPHA_VISUAL_SAVE_FAIL: ",name, " code=",err)
func run()->void:
 var args=OS.get_cmdline_user_args()
 out=str(args[0]) if not args.is_empty() else "user://"
 DirAccess.make_dir_recursive_absolute(out)
 var build=root.get_node("RunBuild")
 build.reset(47821)
 build.muted=true
 var g=load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 await snap("09_alpha_menu_naruto")
 for id in ["sasuke","kakashi","rock_lee","neji","gaara"]:
  g.choose_character(id)
  await process_frame
  await snap("10_hero_"+id)
 g.choose_character("sasuke")
 g._start(47821)
 g.muted=true
 g.godmode=true
 await process_frame
 g.alpha.points=30
 g.alpha.tree_tab=0
 g.alpha.tree_open=true
 await process_frame
 await snap("20_talent_tree_sasuke")
 g.alpha.tree_open=false
 await process_frame
 await snap("21_gameplay_sasuke")
 g.queue_free()
 await process_frame
 root.get_node("AudioDirector").silence()
 print("ALPHA_VISUAL_DONE: 8 screenshots")
 quit(0)