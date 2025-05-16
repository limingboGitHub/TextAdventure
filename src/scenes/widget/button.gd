extends Control
class_name MyButton

signal my_pressed(ui:Control)
signal my_released(ui:Control)
signal double_clicked(ui:Control)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func _unhandled_input(event: InputEvent) -> void:

var is_press : bool = false
# 记录按下的坐标
var press_pos : Vector2 = Vector2()

var is_double_press : bool = false

func _gui_input(event: InputEvent) -> void:
	var click_condition1 = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
	#var click_condition2 = event is InputEventScreenTouch
	var click_condition = click_condition1# or click_condition2
	if click_condition and event.is_pressed():
		#print("press:",event)
		is_press = true
		press_pos = event.position
		if click_condition1:
			is_double_press = event.double_click
		#elif click_condition2:
			#is_double_press = event.double_tap
		
		my_pressed.emit(self)
	elif click_condition  and event.is_released() and is_press and press_pos.distance_to(event.position) < 10:
		#print("release:",event)
		is_press = false
		my_released.emit(self)
		if is_double_press:
			print("my_double_click:")
			double_clicked.emit(self)
			
	# 继续将点击事件传递

	
	
