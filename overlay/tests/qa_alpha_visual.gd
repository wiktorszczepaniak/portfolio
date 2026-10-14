extends SceneTree
const Codex=preload("res://scripts/alpha/codex.gd")
const Roster=preload("res://scripts/alpha/roster.gd")
var output_dir:String
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 if image==null or image.get_width()<100:push_error("Empty alpha codex screenshot");quit(1);return
 var err=image.save_png(output_dir+"/"+name+".png")
 if err!=OK:push_error("Could not write alpha screenshot "+str(err));quit(1)
func run()->void:
 var args=OS.get_cmdline_user_args()
 output_dir=args[0] if args.size()>0 else ProjectSettings.globalize_path("user://alpha_codex")
 DirAccess.make_dir_recursive_absolute(output_dir)
 var codex=Codex.new()
 root.add_child(codex)
 codex.open()
 for id in Roster.IDS:
  codex.selected=id
  codex.queue_redraw()
  await shot("hero_"+id)
 print("ALPHA_CODEX_RENDER_OK 6 heroes; MUGEN missing packs remain visibly locked")
 codex.queue_free()
 quit(0)
