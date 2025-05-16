extends Control

var maps: Array = []


func _ready():
	# 测试代码
	var data_map = DataMap.new()
	data_map.id = "map_000001"
	data_map.name = "测试地图"
	maps.append(data_map)

	set_data(maps)
	

signal map_selected(map_id: String)


func set_data(_maps: Array):
	maps = _maps

	# 清理之前的按钮
	for button in $Back/HBoxContainer/VBoxContainer/Selections.get_children():
		button.queue_free()

	# 创建新的按钮
	for map in maps:
		var button = Button.new()
		button.text = map.name
		button.add_theme_font_size_override("font_size", 25)
		button.pressed.connect(_on_map_button_pressed.bind(map))
		$Back/HBoxContainer/VBoxContainer/Selections.add_child(button)


func _on_map_button_pressed(map: DataMap):
	map_selected.emit(map.id)
	hide()


func _on_close_button_pressed() -> void:
	hide()
