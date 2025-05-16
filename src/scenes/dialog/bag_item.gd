class_name BagItem extends Control

## 背包物品的场景类

var data_bag_item: DataBagItem

signal shop_bt_pressed(data_bag_item: DataBagItem)

signal item_show_bt_pressed(ui: BagItem)

signal item_use_bt_pressed(ui: BagItem)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 测试代码
	#var data_equip = DataEquip.new()
	#data_equip.name = "木锤"
	#data_equip.desc = "一把木头做的锤子，看起来很结实。"
	#data_equip.quality = "史诗"
	#data_equip.max_upgrade_times = 5
	#data_equip.details.attack = 4
	#set_item(data_equip)
	pass


func set_item(item: DataBagItem):
	self.data_bag_item = item
	name = item.uuid
	
	# 显示物品信息
	_show_item_info(item)

	if data_bag_item is DataEquip:
		# 监听装备信息更新
		data_bag_item.updated.connect(_on_item_updated)


func _show_item_info(item: DataBagItem) -> void:
	$Label.text = item.name

	# 品质
	_show_quality(item.quality)

	if item is DataEquip:
		# 描述
		$Label2.text = _equip_desc(item)
		
		if item.upgrade_level > 0:
			# 强化等级
			$Label.text += "(" + str(item.upgrade_level) + ")"
			# 强化特效
			_show_upgrade_effect(item.upgrade_level)
	elif item is DataConsume:
		$Label2.text = _consume_desc(item)
	elif item is DataEtc:
		$Label2.text = item.desc
	else:
		$Label2.text = ""
		
	#数量
	if item.count > 1:
		$Count.text = str(item.count)
	else:
		$Count.text = ""


func _on_item_updated(item: DataBagItem) -> void:
	_show_item_info(item)


func _show_quality(quality: String) -> void:
	var quality_suffix = "common"
	if quality == DataBagItem.QUALITY_GOOD:
		quality_suffix = "good"
	elif quality == DataBagItem.QUALITY_RARE:
		quality_suffix = "rare"
	elif quality == DataBagItem.QUALITY_EPIC:
		quality_suffix = "epic"
	var stylebox = load("res://theme/quality/quality_" + quality_suffix + ".tres")
	$Back.add_theme_stylebox_override("panel", stylebox)


func _show_upgrade_effect(upgrade_level: int) -> void:
	if upgrade_level == 0:
		return
	if not $EffectControl.has_node("UpgradeEffect"):
		var effect = SingletonGameScenePre.EquipUpgradeEffectScene.instantiate()
		effect.name = "UpgradeEffect"
		effect.set_upgrade_level(upgrade_level)
		$EffectControl.add_child(effect)
	else:
		var effect = $EffectControl.get_node("UpgradeEffect")
		effect.set_upgrade_level(upgrade_level)


func show_use_button() -> void:
	$ItemUseBt.show()


func hide_use_button() -> void:
	$ItemUseBt.hide()


func delete_mode(enable: bool):
	$DeleteBt.visible = enable


func set_shop_bt(text: String):
	$ShopBt.visible = true
	$PriceLabel.visible = true
	$ShopBt.text = text
	$PriceLabel.text = str(data_bag_item.price)


func _on_delete_bt_toggled(toggled_on: bool) -> void:
	data_bag_item.is_selected = toggled_on


func _consume_desc(item: DataConsume) -> String:
	var desc = ""
	if item.recovery != null:
		if item.recovery.spec_hp > 0:
			desc += "[color=#ff5555]HP:" + str(item.recovery.spec_hp) + "[/color] "
		if item.recovery.spec_hp_r > 0:
			desc += "[color=#ff5555]HP:" + str(int(item.recovery.spec_hp_r * 100)) + "%[/color] "
		if item.recovery.spec_mp > 0:
			desc += "[color=#5555ff]MP:" + str(item.recovery.spec_mp) + "[/color] "
		if item.recovery.spec_mp_r > 0:
			desc += "[color=#5555ff]MP:" + str(int(item.recovery.spec_mp_r * 100)) + "%[/color] "
	
	if item.data_buff != null and item.data_buff.attribute_ability != null:
		var ability = item.data_buff.attribute_ability
		desc += _get_attribute_ability_desc(ability)

	if item.data_buff != null and item.data_buff.attribute_details != null:
		var details = item.data_buff.attribute_details
		desc += _get_attribute_details_desc(details)

	# 卷轴
	if item.scroll != null:
		desc += _get_attribute_ability_desc(item.scroll.attribute_ability)
		desc += _get_attribute_details_desc(item.scroll.attribute_details)
	

	return desc

func _get_attribute_ability_desc(
	attribute_ability: AttributeAbility
) -> String:
	var desc = ""
	if attribute_ability.power > 0:
		desc += "[color=#a2f05c]力:" + str(attribute_ability.power) + "[/color] "
	if attribute_ability.agility > 0:
		desc += "[color=#a2f05c]敏:" + str(attribute_ability.agility) + "[/color] "
	if attribute_ability.intelligence > 0:
		desc += "[color=#a2f05c]智:" + str(attribute_ability.intelligence) + "[/color] "
	if attribute_ability.luck > 0:
		desc += "[color=#a2f05c]运:" + str(attribute_ability.luck) + "[/color] "
	return desc


func _get_attribute_details_desc(
	details: AttributeDetails
) -> String:
	var desc = ""
	if details.max_hp > 0:
		desc += "[color=#a2f05c]血:" + str(details.max_hp) + "[/color] "
	if details.max_mp > 0:
		desc += "[color=#a2f05c]蓝:" + str(details.max_mp) + "[/color] "
	if details.attack > 0:
		desc += "[color=#a2f05c]攻:" + str(details.attack) + "[/color] "
	if details.defense > 0:
		desc += "[color=#a2f05c]防:" + str(details.defense) + "[/color] "

	if details.magic > 0:
		desc += "[color=#a2f05c]魔:" + str(details.magic) + "[/color] "
	if details.magic_def > 0:
		desc += "[color=#a2f05c]防:" + str(details.magic_def) + "[/color] "
	if details.accuracy > 0:
		desc += "[color=#a2f05c]命:" + str(details.accuracy) + "[/color] "
	if details.evasion > 0:
		desc += "[color=#a2f05c]闪:" + str(details.evasion) + "[/color] "
	if details.hand_technology > 0:
		desc += "[color=#a2f05c]技:" + str(details.hand_technology) + "[/color] "
	if details.move_speed > 0:
		desc += "[color=#a2f05c]移:" + str(details.move_speed) + "[/color] "
	if details.recover_hp > 0:
		desc += "[color=#a2f05c]愈:" + str(details.recover_hp) + "[/color] "
	if details.recover_mp > 0:
		desc += "[color=#a2f05c]慧:" + str(details.recover_mp) + "[/color] "
	if details.attack_speed > 0:
		desc += "[color=#a2f05c]速:" + str(details.attack_speed) + "[/color] "
	if details.exp_gain > 0:
		desc += "[color=#a2f05c]悟:" + str(int(details.exp_gain * 100)) + "%[/color] "
	return desc



func _equip_desc(item: DataEquip) -> String:
	var desc = ""
	if item.details.attack != 0:
		desc += "攻:" + str(item.details.attack)
	if item.details.magic != 0:
		desc += "魔:" + str(item.details.magic)
		

	return desc


func _on_shop_bt_pressed() -> void:
	emit_signal("shop_bt_pressed", data_bag_item)


func _on_item_show_bt_pressed() -> void:
	item_show_bt_pressed.emit(self)


func _on_item_use_bt_pressed() -> void:
	item_use_bt_pressed.emit(self)
