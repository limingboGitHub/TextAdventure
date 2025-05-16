extends Control

var item: DataConsume

signal item_show_bt_pressed(ui: BagItem)

signal item_use_bt_pressed(ui: BagItem,scroll: DataConsume)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 清除所有子节点
	_clear_grid_container()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_data(_item: DataConsume, equips: Array[DataEquip]) -> void:
	item = _item

	# 清除所有子节点
	_clear_grid_container()
	# 创建一个装备列表
	for equip in equips:
		var bag_item = SingletonGameScenePre.BagItemScene.instantiate()
		bag_item.set_item(equip)
		bag_item.show_use_button()
		# 装备的信息展示事件和使用事件
		bag_item.item_show_bt_pressed.connect(func(_item: BagItem):
			item_show_bt_pressed.emit(_item)
		)
		bag_item.item_use_bt_pressed.connect(func(_item: BagItem):
			item_use_bt_pressed.emit(_item, item)
		)
		$ScrollContainer/GridContainer.add_child(bag_item)


func clear() -> void:
	item = null
	# 清除所有子节点
	_clear_grid_container()
	# 隐藏对话框
	hide()


func _clear_grid_container() -> void:
	for child in $ScrollContainer/GridContainer.get_children():
		child.queue_free()


func _on_close_button_pressed() -> void:
	hide()
