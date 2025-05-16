extends Control

## 背包对话框

var data_bag: DataBag

var item_control_dic: Dictionary

signal item_showed(ui: BagItem)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_control_dic = {
		DataBagItem.TYPE_EQUIP: $Equip/ScrollContainer/GridContainer,
		DataBagItem.TYPE_CONSUME: $Consume/ScrollContainer/GridContainer,
		DataBagItem.TYPE_ETC: $Etc/ScrollContainer/GridContainer,
	}
	# 测试背包
	data_bag = DataBag.new()
	# 遍历展示背包中的物品
	_update_bag()
	_set_bag_connect()
				
	#加入一个测试物品
	#var equip = DataEquip.new()
	#equip.id = "01302000"
	#equip.uuid = RandomTool.random_num()
	#equip.name = "剑"
	#data_bag.add_item(equip)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_button_pressed() -> void:
	hide()


func set_bag(input: DataBag) -> void:
	self.data_bag = input
	_update_bag()
	_set_bag_connect()


func _set_bag_connect():
	data_bag.item_added.connect(_on_item_added)
	data_bag.item_removed.connect(_on_item_removed)
	data_bag.item_updated.connect(_on_item_updated)
	data_bag.money_changed.connect(_on_money_changed)

func _update_bag():
	# 展示金币
	$Money/Value.text = str(data_bag.money)

	for tab_name in data_bag.items_dic.keys():
		# 这一层是物品分类
		var type_items = data_bag.items_dic[tab_name]
		var item_control = item_control_dic[tab_name]
		_clear_container(item_control)
		# 添加物品
		for item_index in type_items.size():
			var item = type_items[item_index]
			if not item.is_empty():
				# 实例化物品场景
				var item_scene = SingletonGameScenePre.BagItemScene.instantiate()
				item_scene.set_item(item)
				item_scene.show_use_button()
				item_control.add_child(item_scene)
				# 监听点击事件
				item_scene.item_show_bt_pressed.connect(_on_item_show_pressed)
				item_scene.item_use_bt_pressed.connect(_on_item_used)
			else:
				var place_hold_scene = SingletonGameScenePre.BagPlaceholdScene.instantiate()
				item_control.add_child(place_hold_scene)


func _clear_container(container: GridContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_item_added(item:DataBagItem,item_index: int) -> void:
	#print('item added:', item, tab_index," item_index:", item_index)
	# 将背包物品场景添加到对应位置
	var item_control = item_control_dic[item.type]

	if item_index < item_control.get_child_count():
		var bag_item_scene = item_control.get_child(item_index)
		if bag_item_scene is BagItem:
			bag_item_scene.set_item(item)
	else:
		var item_scene = SingletonGameScenePre.BagItemScene.instantiate()
		item_scene.set_item(item)
		item_scene.show_use_button()
		item_control.add_child(item_scene)
		# 监听点击事件
		item_scene.item_show_bt_pressed.connect(_on_item_show_pressed)
		item_scene.item_use_bt_pressed.connect(_on_item_used)
		


func _on_item_removed(item:DataBagItem,item_index: int) -> void:
	# print('item removed:', item," item_index:", item_index)

	var item_control = item_control_dic[item.type]
	var bag_item_scene = item_control.get_child(item_index)
	if bag_item_scene != null:
		item_control.remove_child(bag_item_scene)
		# 断开连接
		bag_item_scene.item_use_bt_pressed.disconnect(_on_item_used)
		bag_item_scene.item_show_bt_pressed.disconnect(_on_item_show_pressed)
		bag_item_scene.queue_free()


func _on_item_updated(item:DataBagItem,item_index: int) -> void:
	print('item updated:', item," item_index:", item_index)
	var item_control = item_control_dic[item.type]
	var bag_item_scene = item_control.get_child(item_index)
	if bag_item_scene != null:
		bag_item_scene.set_item(item)


## 测试
func _on_button_pressed() -> void:
	var equip = DataEquip.new()
	equip.id = "01302000"
	equip.uuid = RandomTool.random_num()
	equip.name = "剑"
	data_bag.add_item(equip)


func _on_add_consume_bt_pressed() -> void:
	var consume = DataConsume.new()
	consume.id = "02000000"
	consume.uuid = RandomTool.random_num()
	consume.name = "红色药水"
	consume.desc = "红色药草研磨作成的药水.\\n恢复HP约50."
	consume.slot_max = 10
	data_bag.add_item(consume)


func _on_delete_check_box_toggled(toggled_on: bool) -> void:
	# 开启删除模式
	for item_control in item_control_dic.values():
		for child in item_control.get_children():
			if child is BagItem:
				child.delete_mode(toggled_on)
	
	$DeleteControl/DeleteButton.visible = toggled_on


func _on_delete_button_pressed() -> void:
	data_bag.remove_selected_item()
	# 退出选择模式
	$DeleteControl/DeleteCheckBox.button_pressed = false
	

func _on_item_used(ui: BagItem) -> void:
	# print('_on_item_used:', ui.data_bag_item.name)
	var item = ui.data_bag_item
	data_bag.use_item(item)


func _on_item_show_pressed(ui: BagItem) -> void:
	# print('_on_item_show_pressed:', ui.data_bag_item.name)
	item_showed.emit(ui)


func _on_money_changed(money: int) -> void:
	$Money/Value.text = str(money)
