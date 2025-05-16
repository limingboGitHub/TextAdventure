extends Control

## 背包的tab场景

signal shop_bt_pressed(DataBagItem)

signal item_show_pressed(ui:BagItem)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 测试代码
	# test()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func test():
	var items = []

	for i in range(10):
		var item = DataBagItem.new()
		item.id = "test"
		item.name = "测试物品"
		items.append(item)

	set_data(items)


func _clear_container() -> void:
	var container = $ScrollContainer/GridContainer
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## 设置物品
## 
## @param items 物品列表
## @param shop_button 商店按钮 默认为空表示不展示商店按钮，否则展示商店按钮，
## 按钮对应的名称为shop_button
func set_data(items: Array, shop_button: String = "") -> void:
	_clear_container()
	# 添加物品
	for item_index in items.size():
		var item = items[item_index]
		if not item.is_empty():
			# 实例化物品场景
			var item_scene = SingletonGameScenePre.BagItemScene.instantiate()
			item_scene.set_item(item)
			if shop_button != "":
				item_scene.set_shop_bt(shop_button)
				# 监听商店按钮点击事件
				item_scene.shop_bt_pressed.connect(_on_shop_bt_pressed)
				# 监听物品展示按钮点击事件
				item_scene.item_show_bt_pressed.connect(func(ui:BagItem):
					item_show_pressed.emit(ui)
				)

			$ScrollContainer/GridContainer.add_child(item_scene)
		else:
			var place_hold_scene = SingletonGameScenePre.BagPlaceholdScene.instantiate()
			$ScrollContainer/GridContainer.add_child(place_hold_scene)


func _on_shop_bt_pressed(data_bag_item: DataBagItem):
	shop_bt_pressed.emit(data_bag_item)


func remove_item(item: DataBagItem,index: int):
	var to_removed_item = $ScrollContainer/GridContainer.get_child(index)
	$ScrollContainer/GridContainer.remove_child(to_removed_item)
	to_removed_item.queue_free()


func update_item(item: DataBagItem,index: int):
	var item_scene = $ScrollContainer/GridContainer.get_child(index)
	item_scene.set_item(item)


func add_item(item: DataBagItem,shop_button: String = ""):
	# 实例化物品场景
	var item_scene = SingletonGameScenePre.BagItemScene.instantiate()
	item_scene.set_item(item)
	if shop_button!= "":
		item_scene.set_shop_bt(shop_button)
		# 监听商店按钮点击事件
		item_scene.shop_bt_pressed.connect(_on_shop_bt_pressed)
		# 监听物品展示按钮点击事件
		item_scene.item_show_bt_pressed.connect(func(ui:BagItem):
			item_show_pressed.emit(ui)
		)
		
	$ScrollContainer/GridContainer.add_child(item_scene)
