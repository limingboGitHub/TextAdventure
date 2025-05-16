extends Control

## 角色装备栏的对话框

var role_equip : DataRoleEquip

var equip_type_containers = {}

signal item_showed(ui: BagItem)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 角色装备栏对应的场景容器
	equip_type_containers = {
		"weapon": [$EquipContainer/WeaponContainer],
		"upper_body": [$EquipContainer/LongcoatContainer],
		"lower_body": [$EquipContainer/LongcoatContainer2],
		"cap": [$EquipContainer/CapConainer],
		"shoes": [$EquipContainer/ShoesContainer],
		"glove": [$EquipContainer/GloveContainer],
		"shield": [$EquipContainer2/ShieldContainer],
		"cape": [$EquipContainer2/CapeContainer],
		"face": [$EquipContainer2/FaceContainer],
		"earring": [$EquipContainer2/EarringContainer],
		"eyes": [$EquipContainer2/EyesContainer],
		"necklace": [$EquipContainer2/NecklaceContainer],
		"ring": [
			$EquipContainer2/RingContainer,
			$EquipContainer2/RingContainer2,
		]
	}
	
	# 初始化清理装备栏
	for container in equip_type_containers.values():
		for c in container:
			var equip = c.get_child(1)
			if equip:
				equip.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_button_pressed() -> void:
	hide()


func set_data_role_equip(input: DataRoleEquip) -> void:
	role_equip = input
	# 根据装备栏数据加载对应场景
	for equip_type in role_equip.items.keys():
		var data_equip = role_equip.items[equip_type]
		_on_equip_on(data_equip)

	# 监听装备栏的数据变化
	role_equip.equip_on.connect(_on_equip_on)
	role_equip.equip_off.connect(_on_equip_off)


# 监听到卸下装备的点击事件
func _on_equip_off_clicked(ui_control: Control)-> void:
	print("_on_equip_off_clicked:", ui_control)
	if ui_control is BagItem:
		role_equip.remove(ui_control.data_bag_item)


func _on_equip_on(data_equip: DataEquip) -> void:
	print("equip on:", data_equip)
	var container = equip_type_containers[data_equip.equip_type]
	for c in container:
		var equip = SingletonGameScenePre.BagItemScene.instantiate()
		c.add_child(equip)
		equip.set_item(data_equip)
		equip.show_use_button()
		equip.item_use_bt_pressed.connect(_on_equip_off_clicked)
		equip.item_show_bt_pressed.connect(_on_item_show_pressed)


# 监听到装备栏装备卸下成功的事件，这里区别于点击事件，准备卸下不等同于卸下成功
func _on_equip_off(data_equip: DataEquip) -> void:
	print("equip off:", data_equip.equip_type)
	var container = equip_type_containers[data_equip.equip_type]
	for c in container:
		var equip = c.get_child(1)
		if equip and equip.data_bag_item == data_equip:
			# 断开连接
			equip.item_use_bt_pressed.disconnect(_on_equip_off_clicked)
			equip.item_show_bt_pressed.disconnect(_on_item_show_pressed)
			equip.queue_free()
			break


func _on_item_show_pressed(ui: BagItem) -> void:
	item_showed.emit(ui)
