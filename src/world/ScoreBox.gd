extends Control

func switch_visibility(level_times):
	visible = !visible
	refresh(level_times)

func set_visibility(visibility, level_times):
	visible = visibility
	refresh(level_times)

func refresh(level_times):
	if visible:
		var txt = ""
		var tim
		var incomplete = false
		for i in level_times.size():
			if level_times[i] != 0:
				tim = str(floor(level_times[i]))
			else:
				incomplete = true
				tim = "N/A"
			txt += str(i+1)+": "+tim+"\n"
		$Times.text = txt
		$Congratulations.visible = !incomplete
