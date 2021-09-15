extends Control

func _process(delta):
	$FPS.text = String(Performance.get_monitor(Performance.TIME_FPS))
