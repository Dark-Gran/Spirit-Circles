extends Node2D

var switchables = Array()

func _on_Button_pressed():
	for s in switchables:
		s.switch()
	$Particles2D.restart()
