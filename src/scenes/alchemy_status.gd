extends Control


var data_bag: DataBag


func _ready():
	# 清理按钮
	for child in $GridContainer.get_children():
		child.queue_free()


func init_data(_data_bag: DataBag):
	data_bag = _data_bag

	# 初始化buff按钮
	_update_buff_consume()

	# 监听物品的使用
	data_bag.item_used.connect(_on_item_used)
	# 监听物品的添加
	data_bag.item_added.connect(_on_item_added)
	# 监听物品的删除
	data_bag.item_removed.connect(_on_item_removed)
	# 监听物品的更新
	data_bag.item_updated.connect(_on_item_updated)


func _on_item_used(item: DataBagItem):
	if item is DataConsume and item.data_buff != null:
		# 找到对应按钮，更新数量
		for child in $GridContainer.get_children():
			if child.name == item.uuid:
				child.text = item.name + " " + str(item.count)
				break


func _on_item_added(item: DataBagItem, _index: int):
	if item is DataConsume and item.data_buff != null:
		_add_button(item)


func _on_item_removed(item: DataBagItem, _index: int):
	if item is DataConsume and item.data_buff != null:
		# 从按钮容器中移除按钮
		for child in $GridContainer.get_children():
			if child.name == item.uuid:
				child.pressed.disconnect(_on_button_pressed.bind(item))
				child.queue_free()
				break


func _on_item_updated(item: DataBagItem, _index: int):
	if item is DataConsume and item.data_buff != null:
		# 找到对应按钮，更新数量
		for child in $GridContainer.get_children():
			if child.name == item.uuid:
				child.text = item.name + " " + str(item.count)
				break


func _update_buff_consume():
	# 遍历所有背包标签页
	for tab_name in data_bag.items_dic.keys():
		# 遍历该标签页中的所有物品
		for item in data_bag.items_dic[tab_name]:
			if item is DataConsume and item.data_buff != null:
				_add_button(item)


func _add_button(item: DataConsume):
	var button = Button.new()
	button.name = item.uuid
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.x = 90
	button.add_theme_font_size_override("font_size", 12)
	button.text = item.name + " " + str(item.count)
	button.pressed.connect(_on_button_pressed.bind(item))
	$GridContainer.add_child(button)


func _on_button_pressed(item: DataConsume):
	data_bag.use_item(item)
