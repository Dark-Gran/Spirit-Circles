extends Node2D

const INTRO_SPEED = 0.4
const DELAY = 0.4

var fadeout = false

var delay_active = true
var delay_timer = 0
var finished = false

func _ready():
	$Sprite.modulate.a = 0

func _physics_process(delta):
	if Input.is_action_pressed("ui_accept"):
		end_intro()
	else:
		if delay_active:
			delay_timer += delta
			if delay_timer >= DELAY:
				delay_active = false
				delay_timer = 0
		else:
			if finished:
				end_intro()
			else:
				if fadeout:
					$Sprite.modulate.a -= INTRO_SPEED*delta
					if $Sprite.modulate.a <= 0:
						finished = true
						delay_active = true
				else:
					$Sprite.modulate.a += INTRO_SPEED*delta
					if $Sprite.modulate.a >= 1:
						fadeout = true
						#delay_active = true

func end_intro():
	Main.goto_scene("res://src/world/World.tscn")
