extends Control

'''
自定义TouchButton按钮
'''

var press_pos := Vector2.ZERO

signal pressed()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			press_pos = event.position
		else:
			if press_pos.distance_to(event.position) < 20:
				pressed.emit()
				print("pressed")
			
	
