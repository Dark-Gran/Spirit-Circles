extends Node2D
class_name Level

# Level Parameters

export (String) var level_name = "..."
export (bool) var FocusPower_enabled = true
export (bool) var PlayerCircle_enabled = true
export (bool) var Stopwatch_enabled = true

# Circle Factory

const CircleScene = preload("res://src/world/Circle.tscn")
const ParticlesWhite = preload("res://src/world/circle_effects/ParticlesWhite.tscn")
const ParticlesBlue = preload("res://src/world/circle_effects/ParticlesBlue.tscn")
const ParticlesGreen = preload("res://src/world/circle_effects/ParticlesGreen.tscn")
const ParticlesRed = preload("res://src/world/circle_effects/ParticlesRed.tscn")
const GlowBlue = preload("res://src/world/circle_effects/GlowBlue.tscn")
const GlowGreen = preload("res://src/world/circle_effects/GlowGreen.tscn")
const SplitParticles = preload("res://src/world/circle_effects/Split.tscn")

func create_circle(pos, color_type, angle, size, buffer):
	var c = CircleScene.instance()
	c.position = pos
	c.color_type = color_type
	c.angle = angle
	c.size = size
	c.grow_buffer = buffer
	c.get_node("CollisionShape2D").disabled = true
	$Circles.add_child(c)
	create_effects(c)
	c.refresh()
	#if get_node_or_null("Statics/Beams") != null:
	#	for beam in $Statics/Beams.get_children():
	#		if Main.bodies_collide_with_motion(c, beam, Vector2.ZERO, Vector2.ZERO):
	#			beam.circles_inside.append(c)
	return c

func create_effects(circle):
	var particles
	var glow
	match (circle.color_type):
		Circle.ColorType.WHITE:
			particles = ParticlesWhite.instance()
		Circle.ColorType.BLUE:
			particles = ParticlesBlue.instance()
			glow = GlowBlue.instance()
		Circle.ColorType.GREEN:
			particles = ParticlesGreen.instance()
			glow = GlowGreen.instance()
		Circle.ColorType.RED:
			particles = ParticlesRed.instance()
			var split_particles = SplitParticles.instance()
			circle.add_child(split_particles)
	if particles != null:
		circle.add_child(particles)
	if glow != null:
		circle.add_child(glow)
