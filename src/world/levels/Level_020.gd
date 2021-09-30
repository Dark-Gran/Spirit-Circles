extends Level

func _ready():
	$Statics/Button.switchables.append($Statics/DiscoBall)
	for beam in $Statics/DiscoBall/Beams.get_children():
		$Statics/Button.switchables.append(beam)
		beam.possible_colors.append(Circle.ColorType.WHITE)
		beam.possible_colors.append(Circle.ColorType.BLUE)
		beam.possible_colors.append(Circle.ColorType.GREEN)
		beam.possible_colors.append(Circle.ColorType.RED)
		# Change starting color
		beam.color_type = Circle.ColorType.GREEN
		beam.current_state = Circle.ColorType.GREEN
		beam.upcoming_state = beam.current_state
		beam.refresh()
