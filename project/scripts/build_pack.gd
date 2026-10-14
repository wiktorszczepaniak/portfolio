extends SceneTree
var pack := PCKPacker.new()
var count := 0
func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size()!=2:
        push_error("Expected source directory and output PCK")
        quit(1)
        return
    var err := pack.pck_start(args[1],32)
    assert(err==OK)
    add_folder(args[0],"")
    var binary := "user://v7-project.binary"
    assert(ProjectSettings.save_custom(binary)==OK)
    assert(pack.add_file("res://project.binary",binary)==OK)
    # Release templates expect this file even without named global classes.
    var cache_path := "user://v7-global-script-class-cache.cfg"
    var cache := FileAccess.open(cache_path,FileAccess.WRITE)
    cache.store_line("list=[]")
    cache.close()
    assert(pack.add_file("res://.godot/global_script_class_cache.cfg",cache_path)==OK)
    assert(pack.flush()==OK)
    print("BUILD_PACK_PASS files=",count)
    quit(0)
func add_folder(base: String, relative: String) -> void:
    var dir := DirAccess.open(base+"/"+relative)
    assert(dir!=null)
    dir.list_dir_begin()
    var name := dir.get_next()
    while not name.is_empty():
        var rel := relative+"/"+name if not relative.is_empty() else name
        if not name.begins_with(".") and not name.ends_with(".import") and not name.ends_with(".uid"):
            if dir.current_is_dir():add_folder(base,rel)
            elif name!="project.binary":
                assert(pack.add_file("res://"+rel,base+"/"+rel)==OK)
                count+=1
        name=dir.get_next()
