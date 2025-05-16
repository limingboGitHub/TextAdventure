extends Control

## 物品信息对话框

var item: DataBagItem


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_item(item: DataBagItem) -> void:
	self.item = item
	# 设置物品名称
	$Back/HBoxContainer/InfoContainer/Name.text = item.name
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
	$Back/HBoxContainer/InfoContainer/Name.text = item.name
	# 强化等级
	if item.upgrade_level > 0:
		$Back/HBoxContainer/InfoContainer/Name.text += "(+" + str(item.upgrade_level) + ")"
	

	# 展示装备能力值
	attribute_text += "[color=#7ac8ff]"
	if item.final_ability.power != 0:
		attribute_text += "力量：" + str(item.final_ability.power) + "\n"
	if item.final_ability.agility != 0:
		attribute_text += "敏捷：" + str(item.final_ability.agility) + "\n"
	if item.final_ability.intelligence != 0:
		attribute_text += "智力：" + str(item.final_ability.intelligence) + "\n"
	if item.final_ability.luck != 0:
		attribute_text += "幸运：" + str(item.final_ability.luck) + "\n"
	
	# 展示装备详情属性
	if item.final_details.attack != 0:
		attribute_text += "攻击：" + str(item.final_details.attack) + "\n"
	if item.final_details.magic != 0:
		attribute_text += "魔法攻击：" + str(item.final_details.magic) + "\n"
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
	attribute_text += "[/color]"

	#region 紫色属性
	attribute_text += _effect_text_color()

	if item.final_details.exp_gain > 0:
		attribute_text += "增加" + str(int(item.final_details.exp_gain * 100)) + "%经验值获取\n"
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
		if item.scroll.attribute_ability != null:
			# 卷轴增加力量
			if item.scroll.attribute_ability.power > 0:
				attribute_text += "增加力量：" + str(item.scroll.attribute_ability.power) + "\n"
			# 卷轴增加敏捷
			if item.scroll.attribute_ability.agility > 0:
				attribute_text += "增加敏捷：" + str(item.scroll.attribute_ability.agility) + "\n"
			# 卷轴增加智力
			if item.scroll.attribute_ability.intelligence > 0:
				attribute_text += "增加智力：" + str(item.scroll.attribute_ability.intelligence) + "\n"
			# 卷轴增加幸运
			if item.scroll.attribute_ability.luck > 0:
				attribute_text += "增加幸运：" + str(item.scroll.attribute_ability.luck) + "\n"
		if item.scroll.attribute_details != null:
			# 卷轴增加攻击力
			if item.scroll.attribute_details.attack > 0:
				attribute_text += "增加攻击力：" + str(item.scroll.attribute_details.attack) + "\n"
			# 卷轴增加魔法攻击力
			if item.scroll.attribute_details.magic > 0:
				attribute_text += "增加魔法攻击力：" + str(item.scroll.attribute_details.magic) + "\n"
			# 卷轴增加防御力
			if item.scroll.attribute_details.defense > 0:
				attribute_text += "增加防御力：" + str(item.scroll.attribute_details.defense) + "\n"
			# 卷轴增加魔法防御力
			if item.scroll.attribute_details.magic_def > 0:
				attribute_text += "增加魔法防御力：" + str(item.scroll.attribute_details.magic_def) + "\n"
			# 卷轴增加命中
			if item.scroll.attribute_details.accuracy > 0:
				attribute_text += "增加命中：" + str(item.scroll.attribute_details.accuracy) + "\n"
			# 卷轴增加闪避
			if item.scroll.attribute_details.evasion > 0:
				attribute_text += "增加闪避：" + str(item.scroll.attribute_details.evasion) + "\n"
			# 卷轴增加恢复生命值
			if item.scroll.attribute_details.recover_hp > 0:
				attribute_text += "增加恢复生命值：" + str(item.scroll.attribute_details.recover_hp) + "\n"
			# 卷轴增加恢复魔法值
			if item.scroll.attribute_details.recover_mp > 0:
				attribute_text += "增加恢复魔法值：" + str(item.scroll.attribute_details.recover_mp) + "\n"
			# 卷轴增加HP上限
			if item.scroll.attribute_details.max_hp > 0:
				attribute_text += "增加HP上限：" + str(item.scroll.attribute_details.max_hp) + "\n"
			# 卷轴增加MP上限
			if item.scroll.attribute_details.max_mp > 0:
				attribute_text += "增加MP上限：" + str(item.scroll.attribute_details.max_mp) + "\n"
			
			attribute_text += _effect_text_color()
			# 卷轴增加经验值获取
			if item.scroll.attribute_details.exp_gain > 0:
				attribute_text += "增加经验值获取：" + str(int(item.scroll.attribute_details.exp_gain * 100)) + "%\n"
			attribute_text += "[/color]"
		if item.scroll.data_effect != null:
			attribute_text += _effect_text_color()
			attribute_text += _show_effect_desc(item.scroll.data_effect)
			attribute_text += "[/color]"
		
	elif item.data_buff != null:
		# TODO 属性展示
		# 持续时间
		if item.data_buff.duration > 0:
			attribute_text += "持续时间：" + str(item.data_buff.duration) + "\n"
	
	$Back/HBoxContainer/InfoContainer/AttributeLabel.text = attribute_text


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
			var effect_value_str = _effect_value_color() + str(int(effect_value)) + "[/color]"
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
	
