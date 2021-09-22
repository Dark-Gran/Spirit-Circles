extends Node2D

var world_speed = 120
var grow_speed_adjust = 0.1 # see get_grow_speed()

const SCREEN_CHECK = 50
var screen_checker = SCREEN_CHECK

var PC = preload("res://src/world/PlayerCircle.tscn")
var PlayerCircle
const PC_WAIT = 1
var pc_accumulator = 0
var pc_linger = false # disables pc_accumulator right after despawn

var level_id # World -> Level -> Circles -> Circle
var hideLevelName = false
var won = false
var level_time = 0

# Level Loading

func _ready():
	enable_continue(false)
	level_id = 6
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
		reset_LevelName()
		won = false
		level_time = 0
		$GUI/Stopwatch.visible = $Level.Stopwatch_enabled

func unload_level():
	pc_accumulator = 0
	pc_linger = false
	release_pc()
	if get_node_or_null("Level") != null:
		$Level.queue_free()
		remove_child($Level)
	$GUI/LevelName.hide()
	$GUI/LevelName/Timer.stop()
	hideLevelName = false
	enable_continue(false)

func reset_LevelName():
	if get_node_or_null("Level") != null:
		$GUI/LevelName.text = $Level.level_name
	$GUI/LevelName.modulate.a = 1
	$GUI/LevelName.show()
	$GUI/LevelName/Timer.start()

func _on_LevelNameTimer_timeout():
	hideLevelName = true
	
func enable_continue(enable): # on Level-End
	$GUI/Continue.disabled = !enable
	if (enable):
		$GUI/Continue.show()
	else:
		$GUI/Continue.hide()

func _on_Continue_button_up():
	enable_continue(false)
	switch_level(true)
	$GUI/Stopwatch.visible = false

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
			elif Geometry.is_point_in_circle(get_viewport().get_mouse_position(), $PlayerCircle.position, Main.PC_RADIUS):
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
			$DebugGUI/FPS.visible = !$DebugGUI/FPS.visible
		elif InputMap.event_is_action(event, "ui_accept"):
			if won:
				_on_Continue_button_up()
		elif InputMap.event_is_action(event, "toggle_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen

func _process(delta):
	# LevelName
	if hideLevelName:
		$GUI/LevelName.modulate.a -= 0.5 * delta
		if $GUI/LevelName.modulate.a <= 0:
			$GUI/LevelName.hide()
			hideLevelName = false
	if get_node_or_null("Level") != null:
		# LevelTime
		if $Level.Stopwatch_enabled:
			if !won:
				level_time += delta
			$GUI/Stopwatch.text = String(floor(level_time))
		# Check Level-End
		if !won && victory_check():
			won = true
			enable_continue(true)

func _physics_process(delta): 
	if get_node_or_null("Level") != null:
		if !won && Input.is_action_pressed("ui_select"):
			# Focus Power
			var hit
			var mouse = get_viewport().get_mouse_position()
			if $Level.FocusPower_enabled && pc_accumulator == 0:
				var r
				for c in $Level/Circles.get_children():
					r = c.radius
					if r < Circle.CIRCLE_BUTTON_MIN_RADIUS:
						r = Circle.CIRCLE_BUTTON_MIN_RADIUS
					if !c.merging_away && Geometry.is_point_in_circle(mouse, c.position, r):
						hit = c
						focus_power(c, delta)
						break
			# Player Circle
			if $Level.PlayerCircle_enabled && hit == null && !has_node("PlayerCircle") && !pc_linger:
				pc_accumulator += delta
			# Hypothetical Circle
			if pc_accumulator > 0:
				$HypoCircle.position = mouse
		# Screen Edge
		screen_checker += 1
		if screen_checker >= SCREEN_CHECK:
			for c in $Level/Circles.get_children():
				c.check_edge_portal()
			screen_checker = 0
		update()

func victory_check():
	var w: int = 0
	var b: int = 0
	var g: int = 0
	var r: int = 0
	for c in $Level/Circles.get_children():
		match c.color_type:
			Circle.ColorType.WHITE:
				w += 1
			Circle.ColorType.BLUE:
				b += 1
			Circle.ColorType.GREEN:
				g += 1
			Circle.ColorType.RED:
				r += 1
	return w <= 1 && b <= 1 && g <= 1 && r <= 1

func _draw():
	# Player Circle
	if get_rays_enabled():
		# "Partial Circle"
		if pc_accumulator > 0:
			var angle = deg2rad(360*(pc_accumulator / PC_WAIT))
			var color = Color.white
			if !could_spawn_pc_now():
				color = Color.red
			draw_arc(get_viewport().get_mouse_position(), Main.PC_RADIUS, 0, angle, 40, color, 2, true)
		# Rays
		if could_spawn_pc_now():
			for c in $Level/Circles.get_children():
				if c.ray_point_a != null && c.ray_point_b != null:
					draw_line(c.position, c.ray_point_a, Color.white, 2, false)
					draw_line(c.ray_point_a, c.ray_point_b, Color.white, 2, false)
					#draw_circle(c.position+c.get_node("RayCastA").position, 5, Color.red)
					#draw_circle(c.position+c.get_node("RayCastB").position, 5, Color.red)

# Player Circle

func get_rays_enabled():
	if get_node_or_null("Level") != null:
		return $Level.PlayerCircle_enabled && Input.is_action_pressed("ui_select") && !has_node("PlayerCircle") && !won && pc_accumulator > 0
	else:
		return false

func could_spawn_pc_now():
	return !won && $HypoCircle.get_overlapping_bodies().size() == 0

func spawn_pc(pos):
	if get_node_or_null("Level") != null && $Level.PlayerCircle_enabled && could_spawn_pc_now():
		PlayerCircle = PC.instance()
		PlayerCircle.position = pos
		add_child(PlayerCircle)

func release_pc():
	if get_node_or_null("PlayerCircle") != null:
		PlayerCircle.queue_free()

# Resizing Circles ("Focus Power")

func focus_power(circle, delta):
	if get_node_or_null("Level") != null:
		var valid = Array()
		var color_type = circle.color_type
		var min_size = circle.color_info.get("lowest_power")
		for c in $Level/Circles.get_children():
			if c != circle && c.color_type == color_type && !c.merging_away && c.size > min_size:
				valid.append(c)
		if valid.size() > 0:
			var max_grow = get_grow_speed()*delta
			var spare_fade = max_grow
			var fade = max_grow / valid.size()
			for c in valid:
				if c.size-fade > min_size:
					spare_fade -= fade
					c.set_size(c.size-fade)
				else:
					spare_fade -= c.size-min_size
					c.set_size(min_size)
			circle.set_size(circle.size+max_grow-spare_fade)

func get_grow_speed():
	return world_speed*grow_speed_adjust
