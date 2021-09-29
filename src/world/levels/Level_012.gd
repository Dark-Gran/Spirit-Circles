extends Level

func _ready():
	# Mid
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle3)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle4)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle9)
	$Statics/Button.switchables.append($Statics/Rotatables/RotatableTriangle10)
	# Bottom
	$Statics/Button2.switchables.append($Statics/Rotatables/RotatableTriangle8)
	$Statics/Button2.switchables.append($Statics/Rotatables/RotatableTriangle9)
	$Statics/Button2.switchables.append($Statics/Rotatables/RotatableTriangle10)
	$Statics/Button2.switchables.append($Statics/Rotatables/RotatableTriangle11)
	# Top
	$Statics/Button3.switchables.append($Statics/Rotatables/RotatableTriangle2)
	$Statics/Button3.switchables.append($Statics/Rotatables/RotatableTriangle3)
	$Statics/Button3.switchables.append($Statics/Rotatables/RotatableTriangle4)
	$Statics/Button3.switchables.append($Statics/Rotatables/RotatableTriangle5)
