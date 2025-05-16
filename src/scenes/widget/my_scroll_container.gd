extends ScrollContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var bar = get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(20,8)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
