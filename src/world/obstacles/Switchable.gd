extends KinematicBody2D
class_name Switchable

var options
var current_state
var upcoming_state

func _ready():
	upcoming_state = current_state

func switch():
	if options != null:
		var new_state = get_next_after(upcoming_state, options)
		if new_state != null:
			upcoming_state = new_state
			return true
	return false

func get_next_after(current, list):
	if list.size() <= 1:
		return null
	if list[list.size()-1] == current:
		return list[0]
	if list[0] == current:
		return list[1]
	if list is Array:
		return get_next_after(current, list.slice(1, list.size()-1))
	else:
		var cut_list = list
		cut_list.remove(0)
		return get_next_after(current, cut_list)
