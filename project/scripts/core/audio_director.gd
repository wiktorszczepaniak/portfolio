extends Node
## Shared across scenes: voice never restarts on a repeated clone/hit event.
var streams:Dictionary={}
var last_played:Dictionary={}
var voices:Array[AudioStreamPlayer]=[]
var hits:Array[AudioStreamPlayer]=[]
func _ready() -> void:
 for i in range(6):
  var output=AudioStreamPlayer.new();add_child(output)
  if i<2:voices.append(output)
  else:hits.append(output)
func play_effect(path:String,event:String,muted:bool=false) -> bool:
 if muted or not FileAccess.file_exists(path):return false
 var voice=event in ["clone.wav","transform.wav","transform.mp3","boss.wav"]
 var gap=6.0 if event=="clone.wav" else 0.25 if event=="impact.wav" else 0.08
 var now=Time.get_ticks_msec()*0.001
 if now-float(last_played.get(event,-100.0))<gap:return false
 var pool=voices if voice else hits
 var output:AudioStreamPlayer=null
 for candidate in pool:
  if not candidate.playing:output=candidate;break
 if output==null:return false
 if not streams.has(path):
  var bytes=FileAccess.get_file_as_bytes(path)
  streams[path]=AudioStreamMP3.load_from_buffer(bytes) if path.ends_with(".mp3") else AudioStreamWAV.load_from_buffer(bytes)
 if streams[path]==null:return false
 output.stream=streams[path];output.volume_db=-16 if voice else -13
 output.play();last_played[event]=now
 return true
func silence() -> void:
 for output in voices+hits:output.stop()

func _exit_tree() -> void:
 silence()
 for output in voices+hits:output.stream=null
 streams.clear()
