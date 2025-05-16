extends ColorRect

@export
var max_width = 190

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_value(max:int,value: int) -> void:
	if max > 0:
		var percent = value / float(max)
		if percent > 1:
			percent = 1
		size.x = max_width * percent
	else:
		size.x = 0
	
	if has_node("Label"):
		var label = get_node("Label")
		if max > 0:
			label.text = str(value) + "/" + str(max)
		else:
			label.text = str(value) + "/-"
	
