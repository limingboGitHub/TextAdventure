extends Node2D

var start_time: int = 0


func _process(_delta):
	if visible:
		$Label.text = str(int(Time.get_ticks_msec() / 100.0) - start_time)


func start():
	show()
	start_time = int(Time.get_ticks_msec() / 100.0)
