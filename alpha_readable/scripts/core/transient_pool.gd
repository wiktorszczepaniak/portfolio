extends RefCounted
var available:Array[Dictionary]=[]
var limit:=128
var created:=0
var reused:=0
func acquire(values:Dictionary) -> Dictionary:
 var item:Dictionary
 if available.is_empty():item={};created+=1
 else:item=available.pop_back();reused+=1
 item.merge(values,true)
 return item
func release(item:Dictionary) -> void:
 item.clear()
 if available.size()<limit:available.append(item)
