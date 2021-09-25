extends Level

func _ready():
	for beam in $Statics/Beams.get_children():
		$Statics/Button.switchables.append(beam)
		beam.possible_colors.append(Circle.ColorType.WHITE)
		beam.possible_colors.append(Circle.ColorType.BLUE)
		beam.possible_colors.append(Circle.ColorType.GREEN)
