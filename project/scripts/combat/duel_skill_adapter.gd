extends "res://scripts/combat/skill_runtime.gd"
var input_slot:=-1
var buffer_time:=0.0
func configure(owner_node,state) -> void:setup(owner_node,state,"duel")
func request_slot(slot:int) -> void:input_slot=slot;buffer_time=0.16
func tick(dt:float) -> void:
 super.tick(dt)
 if buffer_time>0:
  buffer_time-=dt
  if cast_slot(input_slot):buffer_time=0;input_slot=-1
