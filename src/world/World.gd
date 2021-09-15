extends Node2D

const SCREEN_CHECK = 50
var screen_checker = SCREEN_CHECK

var PC = preload("res://src/world/PlayerCircle.tscn")
var PlayerCircle
const PC_WAIT = 1
var pc_accumulator = 0
var pc_linger = false # disables pc_accumulator right after despawn

var level_id
var hideLevelName = false
var won = false

# Level Loading

func _ready():
	level_id = 1
	move_to_level(level_id)

func reload_level():
	if level_id == null:
		level_id = 0
	move_to_level(level_id)

func switch_level(forward):
	if level_id == null:
		level_id = 0
	var change = 1
	if !forward:
		change = -1
	move_to_level(level_id+change)

func move_to_level(id):
	var base = "res://src/world/levels/Level_" # 001.tscn
	var idstr = String(id)
	match idstr.length():
		1:
			idstr = "00"+idstr
		2:
			idstr = "0"+idstr
	var path = base+idstr+".tscn"
	if ResourceLoader.exists(path):
		unload_level()
		level_id = id
		call_deferred("load_level", path)

func load_level(path):
	var Level = load(path).instance()
	if Level != null:
		add_child(Level)
		#reset_LevelName()
		won = false

func unload_level():
	pc_accumulator = 0
	pc_linger = false
	release_pc()
	if get_node_or_null("Level") != null:
		$Level.queue_free()
		remove_child($Level)
	#$GUI/LevelName.hide()
	#$GUI/LevelName/Timer.stop()
	hideLevelName = false
	#enable_continue(false)

# World Steps

func _input(event):
	# Player Circle
	if get_node_or_null("Level") != null:
		if InputMap.event_is_action(event, "ui_select"):
			if !has_node("PlayerCircle"):
				if !event.is_pressed():
					if pc_accumulator >= PC_WAIT:
						spawn_pc(get_viewport().get_mouse_position())
					pc_accumulator = 0
				pc_linger = false
			else:
				release_pc()
				pc_accumulator = 0
				pc_linger = true
	# Controls
	if event.is_pressed():
		if InputMap.event_is_action(event, "ui_left"):
			switch_level(false)
		elif InputMap.event_is_action(event, "ui_right"):
			switch_level(true)
		elif InputMap.event_is_action(event, "ui_reload"):
			reload_level()
		elif InputMap.event_is_action(event, "ui_fps"):
			#$GUI/FPS.visible = !$GUI/FPS.visible
			pass

func _physics_process(delta): 
	if get_node_or_null("Level") != null:
		# Player Circle
		if Input.is_action_pressed("ui_select") && !has_node("PlayerCircle") && !pc_linger:
			pc_accumulator += delta
		# Screen Edge
		screen_checker += 1
		if screen_checker >= SCREEN_CHECK:
			for c in $Level/Circles.get_children():
				c.check_edge_portal()
			screen_checker = 0
		update()

func _draw():
	# PlayerCircle
	if pc_accumulator > 0:
		var angle = deg2rad(360*(pc_accumulator / PC_WAIT))
		var color = Color.white
		#if !could_manifest_at(get_viewport().get_mouse_position(), pc_size):
		#	color = Color.red
		draw_arc(get_viewport().get_mouse_position(), Main.PC_RADIUS, 0, angle, 40, color, 2, true)
	# Rays
	if get_node_or_null("Level") != null:
		for c in $Level/Circles.get_children():
			draw_line(c.position, c.ray_point_a, Color.white, 2, false)
			if c.ray_point_b != null:
				draw_line(c.ray_point_a, c.ray_point_b, Color.white, 2, false)
			#draw_circle(c.position+c.get_node("RayCastA").position, 3, Color.red)
			#draw_circle(c.position+c.get_node("RayCastB").position, 3, Color.red)

# Player Circle

func spawn_pc(pos):
	PlayerCircle = PC.instance()
	PlayerCircle.position = pos
	add_child(PlayerCircle)

func release_pc():
	if get_node_or_null("PlayerCircle") != null:
		PlayerCircle.queue_free()
