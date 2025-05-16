extends ItemList

func _ready() -> void:
	var bar = get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(20,8)
