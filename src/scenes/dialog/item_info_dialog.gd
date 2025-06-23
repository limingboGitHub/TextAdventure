extends Control

## 物品信息对话框

var item: DataBagItem

@onready var name_label: Label = $Back/HBoxContainer/InfoContainer/HBoxContainer/Name
@onready var lock_bt: Button = $Back/HBoxContainer/InfoContainer/HBoxContainer/LockBt


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_item(item: DataBagItem) -> void:
	self.item = item
	# 设置物品名称
	name_label.text = item.name
	# 设置物品锁定状态
	lock_bt.text = "解锁" if item.is_locked else "锁定"
	# 设置物品描述
	$Back/HBoxContainer/InfoContainer/Description.text = item.desc

	# 展示物品属性
	$Back/HBoxContainer/InfoContainer/AttributeLabel.text = ""
	if item is DataEquip:
		_show_equip_info(item)
		
		# 监听装备信息更新
		item.updated.connect(_show_equip_info)
	elif item is DataConsume:
		_show_consume_info(item)


func _on_close_button_pressed() -> void:
	hide()


func set_lock_bt_visible(_visible: bool) -> void:
	lock_bt.visible = _visible


func get_item() -> DataBagItem:
	return item


func _show_equip_info(item: DataEquip) -> void:
	var attribute_text = ""
	# 装备等级
	if item.require_level > 0:
		attribute_text += "等级要求：" + str(item.require_level) + "\n"
	# 装备职业
	if item.require_job != "":
		attribute_text += "职业要求：" + item.require_job + "\n"
	# 装备力量
	if item.require_power > 0:
		attribute_text += "力量要求：" + str(item.require_power) + "\n"
	# 装备敏捷	
	if item.require_agility > 0:
		attribute_text += "敏捷要求：" + str(item.require_agility) + "\n"
	# 装备智力
	if item.require_intelligence > 0:
		attribute_text += "智力要求：" + str(item.require_intelligence) + "\n"
	# 装备幸运
	if item.require_luck > 0:
		attribute_text += "幸运要求：" + str(item.require_luck) + "\n"
	
	# 装备名称
	name_label.text = item.name
	# 强化等级
	if item.upgrade_level > 0:
		name_label.text += "(+" + str(item.upgrade_level) + ")"
	

	# 展示装备属性
	attribute_text += _show_blue_color()

	if item.final_details.attack != 0:
		attribute_text += "攻击：" + str(item.final_details.attack) + "\n"
	if item.final_details.magic != 0:
		attribute_text += "魔法攻击：" + str(item.final_details.magic) + "\n"

	if item.final_ability.power != 0:
		attribute_text += "力量：" + str(item.final_ability.power) + "\n"
	if item.final_ability.agility != 0:
		attribute_text += "敏捷：" + str(item.final_ability.agility) + "\n"
	if item.final_ability.intelligence != 0:
		attribute_text += "智力：" + str(item.final_ability.intelligence) + "\n"
	if item.final_ability.luck != 0:
		attribute_text += "幸运：" + str(item.final_ability.luck) + "\n"
	
	if item.final_details.defense != 0:
		attribute_text += "防御：" + str(item.final_details.defense) + "\n"
	if item.final_details.magic_def != 0:
		attribute_text += "魔法防御：" + str(item.final_details.magic_def) + "\n"
	if item.final_details.accuracy != 0:
		attribute_text += "命中：" + str(item.final_details.accuracy) + "\n"
	if item.final_details.evasion != 0:
		attribute_text += "闪避：" + str(item.final_details.evasion) + "\n"
	if item.final_details.hand_technology != 0:
		attribute_text += "手技：" + str(item.final_details.hand_technology) + "\n"
	if item.final_details.max_hp != 0:
		attribute_text += "HP上限：" + str(item.final_details.max_hp) + "\n"
	if item.final_details.max_mp != 0:
		attribute_text += "MP上限：" + str(item.final_details.max_mp) + "\n"
	if item.final_details.recover_hp != 0:
		attribute_text += "恢复生命值：" + str(item.final_details.recover_hp) + "\n"
	if item.final_details.recover_mp != 0:
		attribute_text += "恢复魔法值：" + str(item.final_details.recover_mp) + "\n"
	if item.final_details.attack_min_rate != 0:
		attribute_text += "攻击力最小值：" + str(int(item.final_details.attack_min_rate * 100)) + "%\n"
	if item.final_details.attack_max_rate != 0:
		attribute_text += "攻击力最大值：" + str(int(item.final_details.attack_max_rate * 100)) + "%\n"
	if item.final_details.exp_gain > 0:
		attribute_text += "增加" + str(int(item.final_details.exp_gain * 100)) + "%经验值获取\n"
	
	# 展示随机属性列表
	if item.is_random_attribute_crate and item.random_attribute.size() > 0:
		for random_attribute_dic in item.random_attribute:
			var _name = _attribute_str_to_name(random_attribute_dic["name"])
			var _min = str(int(random_attribute_dic["min"]))
			var _max = str(int(random_attribute_dic["max"]))
			attribute_text += "(" + _name + "：" + str(_min) + "-" + str(_max) + ")\n"
	
	attribute_text += "[/color]"
	#region 紫色属性
	attribute_text += _effect_text_color()

	# 展示装备特殊效果
	for data_effect in item.get_all_effects():
		attribute_text += _show_effect_desc(data_effect)	
	
	attribute_text += "[/color]"
	#endregion

	# 可强化次数
	if item.max_upgrade_times > 0:
		attribute_text += "卷轴强化次数：" + str(item.can_upgrade_num()) + "\n"
	# 强化经验值展示
	var upgrade_exp_max_str = "-"
	if item.upgrade_exp_max > -1:
		upgrade_exp_max_str = str(item.upgrade_exp_max)
	attribute_text += "强化经验：" + str(item.upgrade_exp) + "/" + upgrade_exp_max_str
	
	$Back/HBoxContainer/InfoContainer/AttributeLabel.text = attribute_text


func _show_blue_color() -> String:
	return "[color=#7ac8ff]"


func _show_consume_info(item: DataConsume) -> void:
	var attribute_text = ""

	if item.recovery != null:
		# 恢复生命值
		if item.recovery.spec_hp > 0:
			attribute_text += "恢复生命值：" + str(item.recovery.spec_hp) + "\n"
		if item.recovery.spec_hp_r > 0:
			attribute_text += "恢复生命值：" + str(item.recovery.spec_hp_r) + "%\n"
		# 恢复魔法值
		if item.recovery.spec_mp > 0:
			attribute_text += "恢复魔法值：" + str(item.recovery.spec_mp) + "\n"
		if item.recovery.spec_mp_r > 0:
			attribute_text += "恢复魔法值：" + str(item.recovery.spec_mp_r) + "%\n"
	elif item.scroll != null:
		# 卷轴类型
		attribute_text += "类型：" + _equip_type_to_string(item.scroll.use_type) + "卷轴\n"
		# 卷轴成功率
		if item.scroll.success_rate > 0:
			attribute_text += "成功率：" + str(item.scroll.success_rate * 100) + "%\n"
		
		# 是否有能力值和属性值
		var is_have_ability = false
		if item.scroll.attribute_ability != null:
			# 卷轴增加力量
			if item.scroll.attribute_ability.power > 0:
				attribute_text += "增加力量：" + str(item.scroll.attribute_ability.power) + "\n"
				is_have_ability = true
			# 卷轴增加敏捷
			if item.scroll.attribute_ability.agility > 0:
				attribute_text += "增加敏捷：" + str(item.scroll.attribute_ability.agility) + "\n"
				is_have_ability = true
			# 卷轴增加智力
			if item.scroll.attribute_ability.intelligence > 0:
				attribute_text += "增加智力：" + str(item.scroll.attribute_ability.intelligence) + "\n"
				is_have_ability = true
			# 卷轴增加幸运
			if item.scroll.attribute_ability.luck > 0:
				attribute_text += "增加幸运：" + str(item.scroll.attribute_ability.luck) + "\n"
				is_have_ability = true
		if item.scroll.attribute_details != null:
			# 卷轴增加攻击力
			if item.scroll.attribute_details.attack > 0:
				attribute_text += "增加攻击力：" + str(item.scroll.attribute_details.attack) + "\n"
				is_have_ability = true
			# 卷轴增加魔法攻击力
			if item.scroll.attribute_details.magic > 0:
				attribute_text += "增加魔法攻击力：" + str(item.scroll.attribute_details.magic) + "\n"
				is_have_ability = true
			# 卷轴增加防御力
			if item.scroll.attribute_details.defense > 0:
				attribute_text += "增加防御力：" + str(item.scroll.attribute_details.defense) + "\n"
				is_have_ability = true
			# 卷轴增加魔法防御力
			if item.scroll.attribute_details.magic_def > 0:
				attribute_text += "增加魔法防御力：" + str(item.scroll.attribute_details.magic_def) + "\n"
				is_have_ability = true
			# 卷轴增加命中
			if item.scroll.attribute_details.accuracy > 0:
				attribute_text += "增加命中：" + str(item.scroll.attribute_details.accuracy) + "\n"
				is_have_ability = true
			# 卷轴增加闪避
			if item.scroll.attribute_details.evasion > 0:
				attribute_text += "增加闪避：" + str(item.scroll.attribute_details.evasion) + "\n"
				is_have_ability = true
			# 卷轴增加恢复生命值
			if item.scroll.attribute_details.recover_hp > 0:
				attribute_text += "增加恢复生命值：" + str(item.scroll.attribute_details.recover_hp) + "\n"
				is_have_ability = true
			# 卷轴增加恢复魔法值
			if item.scroll.attribute_details.recover_mp > 0:
				attribute_text += "增加恢复魔法值：" + str(item.scroll.attribute_details.recover_mp) + "\n"
				is_have_ability = true
			# 卷轴增加HP上限
			if item.scroll.attribute_details.max_hp > 0:
				attribute_text += "增加HP上限：" + str(item.scroll.attribute_details.max_hp) + "\n"
				is_have_ability = true
			# 卷轴增加MP上限
			if item.scroll.attribute_details.max_mp > 0:
				attribute_text += "增加MP上限：" + str(item.scroll.attribute_details.max_mp) + "\n"
				is_have_ability = true
			attribute_text += _effect_text_color()
			# 卷轴增加经验值获取
			if item.scroll.attribute_details.exp_gain > 0:
				attribute_text += "增加经验值获取：" + str(int(item.scroll.attribute_details.exp_gain * 100)) + "%\n"
				is_have_ability = true
			attribute_text += "[/color]"
			if is_have_ability:
				attribute_text += _attribute_append_str(true)
		if item.scroll.data_effect != null:
			attribute_text += _effect_text_color()
			attribute_text += _show_effect_desc(item.scroll.data_effect)
			attribute_text += "[/color]"
			attribute_text += _attribute_append_str(false)
		
	elif item.data_buff != null:
		# TODO 属性展示
		# 持续时间
		if item.data_buff.duration > 0:
			attribute_text += "持续时间：" + str(int(item.data_buff.duration)) + "秒\n"
	
	$Back/HBoxContainer/InfoContainer/AttributeLabel.text = attribute_text


func _attribute_str_to_name(attribute_str: String) -> String:
	if attribute_str == "power":
		return "力量"
	elif attribute_str == "agility":
		return "敏捷"
	elif attribute_str == "intelligence":
		return "智力"
	elif attribute_str == "luck":
		return "幸运"
	elif attribute_str == "attack":
		return "攻击力"
	elif attribute_str == "magic":
		return "魔法攻击"
	elif attribute_str == "defense":
		return "防御力"
	elif attribute_str == "magic_def":
		return "魔法防御"
	elif attribute_str == "accuracy":
		return "命中"
	elif attribute_str == "evasion":
		return "闪避"
	elif attribute_str == "recover_hp":
		return "恢复生命值"
	elif attribute_str == "recover_mp":
		return "恢复魔法值"
	elif attribute_str == "max_hp":
		return "HP上限"
	elif attribute_str == "max_mp":
		return "MP上限"
	else:
		return ""


# 属性是否可以叠加的提示
func _attribute_append_str(is_append: bool) -> String:
	if is_append:
		return "[color=#00ff00](单件装备可叠加)[/color]\n"
	else:
		return "[color=#ff0000](单件装备不可叠加)[/color]\n"


func _show_effect_desc(data_effect: DataEffect)-> String:
	var attribute_text = ""
	var skill_enhance = data_effect.skill_enhance
	if skill_enhance != null:
		# 技能增强
		attribute_text += skill_enhance.name + " "
		if skill_enhance.distance != 0:
			attribute_text += "距离：" + str(skill_enhance.distance) + " "
		if skill_enhance.radius != 0:
			attribute_text += "范围：" + str(skill_enhance.radius) + " "
		if skill_enhance.count != 0:
			attribute_text += "数量：" + str(skill_enhance.count) + " "
		if skill_enhance.cd != 0:
			attribute_text += "释放：" + str(skill_enhance.cd)
		if skill_enhance.add_probability != 0:
			attribute_text += "追加概率：" + str(int(skill_enhance.add_probability * 100)) + "%"
		if skill_enhance.add_count != 0:
			attribute_text += "追加数量：" + str(skill_enhance.add_count)
		if skill_enhance.mp_cost != 0:
			attribute_text += "mp消耗：" + str(skill_enhance.mp_cost)
		if skill_enhance.damage != 0:
			attribute_text += "伤害：" + str(int(skill_enhance.damage * 100)) + "%"
		attribute_text += "\n"
	else:
		# 效果数值
		if data_effect.value_type == Constants.VALUE_TYPE_PERCENT:
			var effect_value = data_effect.value * 100
			
			# 判断是否有小数位并格式化显示
			var formatted_value = str(effect_value) if fmod(effect_value, 1.0) != 0 else str(int(effect_value))
			var effect_value_str = _effect_value_color() + formatted_value + "%[/color]"
			var desc = data_effect.desc.replace("{d}", effect_value_str)
			attribute_text += desc + "\n"
		else:
			var effect_value = data_effect.value
			# 优化小数和整数的展示
			var effect_value_tmp = ""
			if (effect_value - int(effect_value)) > 0:
				effect_value_tmp = str(effect_value)
			else:
				effect_value_tmp = str(int(effect_value))

			var effect_value_str = _effect_value_color() + effect_value_tmp + "[/color]"
			var desc = data_effect.desc.replace("{d}", effect_value_str)
			attribute_text += desc + "\n"
	return attribute_text


func _effect_value_color() -> String:
	return "[color=#7373ff]"


func _effect_text_color() -> String:
	return "[color=#9973ff]"


func _equip_type_to_string(equip_type: String) -> String:
	match equip_type:
		DataEquip.TYPE_WEAPON:
			return "武器"
		DataEquip.TYPE_UPPER_BODY:
			return "上衣"
		DataEquip.TYPE_LOWER_BODY:
			return "下装"
		DataEquip.TYPE_CAP:
			return "帽子"
		DataEquip.TYPE_SHOES:
			return "鞋子"
		_:
			return ""
	


func _on_lock_bt_pressed() -> void:
	if item:
		item.set_locked(!item.is_locked)
		lock_bt.text = "解锁" if item.is_locked else "锁定"
