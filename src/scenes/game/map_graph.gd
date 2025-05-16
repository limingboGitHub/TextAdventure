extends Panel

## 这是一个地图关系图，用于显示地图之间的关系
##
## 根据地图之间的连通关系，绘制出地图之间的关系图

var region_dic: Dictionary
var region_connects: Dictionary
var map_region_dic: Dictionary
var region_name_dic: Dictionary
var current_map_id = ""
var node_positions = [] # 存储所有节点位置
var map_buttons = {} # 存储所有地图按钮引用

#var text_theme: Theme

signal map_selected(map_id: String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# 清理旧的UI元素
func _clear_ui() -> void:
	# 移除所有按钮
	for child in $MapZone.get_children():
		child.queue_free()
	

# 创建一个地区的地图
func _create_map_region(region_id: String) -> void:
	var region_name = region_name_dic[region_id]
	var region_maps = region_dic[region_id]
	var map_connects = region_connects[region_id]

	if region_maps and not map_connects.is_empty():
		var map_zone = Control.new()
		map_zone.name = region_name
		map_zone.size = Vector2(524, 671)
		$TabContainer.add_child(map_zone)
		
		# 地图区域的宽高
		var map_zone_size = map_zone.size
		
		var node_num = region_maps.size()
		
		# 计算节点位置
		node_positions = []
		for i in range(node_num):
			var map = region_maps.values()[i]
			# 如果地图位置为-1，则不显示
			if map.position.x == -1:
				node_num -= 1
				continue

			var pos = Vector2(map_zone_size.x * map.position.x, map_zone_size.y * map.position.y)
			node_positions.append(pos)
		
		# 先绘制连线
		for edge in map_connects:
			var start_index = region_maps.keys().find(edge[0])
			var end_index = region_maps.keys().find(edge[1])
			var start_position = node_positions[start_index]
			var end_position = node_positions[end_index]
			
			var line = Line2D.new()
			line.add_point(start_position)
			line.add_point(end_position)
			line.width = 2
			line.default_color = Color.GRAY
			map_zone.add_child(line)
		
		# 创建按钮
		for i in range(node_num):
			var map_id = region_maps.keys()[i]
			var map_data = region_maps.values()[i]
			var map_name = map_data.name
			
			var button = Button.new()
			button.text = map_name
			button.add_theme_font_size_override("font_size", 20)
			
			# 根据地图状态设置按钮样式
			if map_id == current_map_id:
				button.add_theme_color_override("font_color", Color.GREEN_YELLOW)
				button.add_theme_color_override("font_outline_color", Color.GREEN_YELLOW)
			
			# 设置按钮位置和大小
			var text_width = max(map_name.length() * 20, 40) # 最小宽度40
			var rect_size = Vector2(text_width + 20, 30)
			button.size = rect_size
			button.position = node_positions[i] - rect_size / 2

			# 设置完大小后，先将地图信息隐藏，待探索后显示
			if not map_data.is_explored:
				button.text = "???"
			
			# 连接点击信号
			button.pressed.connect(_on_map_button_pressed.bind(map_id))
			
			map_zone.add_child(button)
			map_buttons[map_id] = button


# 处理按钮点击事件
func _on_map_button_pressed(map_id) -> void:
	# 发出信号或执行操作
	print("地图被点击：", map_id)
	# 这里可以添加信号或其他处理逻辑
	map_selected.emit(map_id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func init_maps(
	region_dic: Dictionary,
	region_connects: Dictionary,
	map_region_dic: Dictionary,
	region_name_dic: Dictionary
):
	self.region_dic = region_dic
	self.region_connects = region_connects
	self.map_region_dic = map_region_dic
	self.region_name_dic = region_name_dic

	for region_id in region_name_dic.keys():
		_create_map_region(region_id)


func update_current_map(_current_map_id: String):
	# 将上一次高亮的地图按钮状态重置
	if current_map_id != "":
		update_map_button_state(current_map_id, false)

	# 更新当前地图
	self.current_map_id = _current_map_id
	# 更新地图按钮状态
	update_map_button_state(current_map_id, true)
	# 显示探索过的地图名称
	if get_map(current_map_id).is_explored:
		if map_buttons.has(current_map_id):
			map_buttons[current_map_id].text = get_map(current_map_id).name

	# 更新当前地图tab
	var region_id = map_region_dic[_current_map_id]
	var index = region_name_dic.keys().find(region_id)
	if index != $TabContainer.current_tab:
		$TabContainer.current_tab = index
	

func update_map_button_state(_map_id: String, is_highlight: bool):
	if not map_buttons.has(_map_id):
		return

	var button = map_buttons[_map_id]
	var color = Color.WHITE
	if is_highlight:
		color = Color.GREEN_YELLOW
	
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_outline_color", color)
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_hover_color", color)


func get_map(map_id: String) -> DataMap:
	return region_dic[map_region_dic[map_id]][map_id]
