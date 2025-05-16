class_name DragControl extends Control

## 可拖动控件
##
## 可使用鼠标拖动控件

var drag_start_pos: Vector2
var is_dragging: bool = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 鼠标按下时记录起始位置
				drag_start_pos = get_global_mouse_position() - get_parent().position
				is_dragging = true
			else:
				# 鼠标释放时停止拖动
				is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		# 鼠标移动时更新控件位置
		get_parent().position = get_global_mouse_position() - drag_start_pos
