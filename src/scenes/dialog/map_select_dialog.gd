extends Control

var maps: Array = []

var requires: Dictionary = {}

func _ready():
	# 测试代码
	var data_map = DataMap.new()
	data_map.id = "map_000001"
	data_map.name = "测试地图"
	maps.append(data_map)

	set_data(maps,{})
	

signal map_selected(map_id: String,requires: Dictionary)


func set_data(_maps: Array, _requires: Dictionary):
	maps = _maps
	requires = _requires
	# 清理之前的按钮
	for button in $Back/HBoxContainer/VBoxContainer/Selections.get_children():
		button.queue_free()

	# 创建新的按钮
	for map in maps:
		var button = Button.new()
		button.text = map.name
		# 查看是否有要求
		if requires.has(map.id):
			var type = requires[map.id].type
			if type == "money":
				var count = requires[map.id].count
				button.text += "(" + str(int(count)) + "金币)"
		button.add_theme_font_size_override("font_size", 25)
		button.pressed.connect(_on_map_button_pressed.bind(map))
		$Back/HBoxContainer/VBoxContainer/Selections.add_child(button)


func _on_map_button_pressed(map: DataMap):
	var require: Dictionary
	if requires.has(map.id):
		require = requires[map.id]
	map_selected.emit(map.id,require)
	hide()


func _on_close_button_pressed() -> void:
	hide()
