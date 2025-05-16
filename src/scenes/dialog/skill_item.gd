extends Control

## 技能栏目Item场景

var data_skill: DataBaseSkill


signal skill_add_pressed(data_skill: DataBaseSkill)

signal skill_used(data_skill: DataBaseSkill)

signal skill_active_toggled(data_skill: DataEffectBuffSkill, active: bool)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_data(data_skill: DataBaseSkill) -> void:
	self.data_skill = data_skill
	$Name.text = data_skill.name
	$MaxLevel/Label.text = str(data_skill.max_level)
	$Level/Label.text = str(data_skill.level)
	_show_description(data_skill)

	# 显示使用按钮
	_update_use_bt()

	# 监听技能等级变化
	data_skill.level_changed.connect(_on_level_changed)


func _update_use_bt() -> void:
	if data_skill.level > 0:
		if data_skill is DataBuffSkill and data_skill.time != -1:
			# 非永久buff，通过按钮使用
			$UseBt.visible = true
		elif data_skill is DataEffectBuffSkill and data_skill.time == -1:
			# 永久EffectBuff，通过按钮控制开关(暂时不支持)
			$ActiveButton.visible = false
			#$ActiveButton.toggled.connect(_on_active_button_toggled)


func _on_level_changed(data_skill: DataBaseSkill) -> void:
	$Level/Label.text = str(data_skill.level)
	_show_description(data_skill)
	_update_use_bt()


func _on_add_bt_pressed() -> void:
	skill_add_pressed.emit(data_skill)


func _show_description(data_skill: DataBaseSkill):
	if data_skill.level == 0:
		# 通过正则表达式替换所有{xxx}为x
		var regex = RegEx.new()
		regex.compile("\\{[^}]*\\}")
		$Description.text = regex.sub(data_skill.description, "x", true)
		return

	if data_skill is DataAttackSkill:
		var damage_list = data_skill.damage_level[data_skill.level - 1]
		var mp = int(data_skill.get_mp_cost())

		var damage_str = "[color=#7ac8ff]"
		for damage in damage_list:
			damage_str += str(int(damage * 100)) + "%,"
		damage_str = damage_str.left(damage_str.length() - 1)
		damage_str += "[/color]"

		var mp_str = "[color=#7ac8ff]" + str(mp) + "[/color]"
		$Description.text = data_skill.description.replace("{d}", damage_str).replace("{m}", mp_str)
	elif data_skill is DataEffectBuffSkill:
		var effect = data_skill.effect_list[data_skill.level - 1]
		if effect.type  == DataEffect.SkillEnhance:
			var data_list = effect.skill_enhance.get_not_zero_fields()
			var description = data_skill.description
			for data in data_list:
				var effect_value = ""
				if data["value_type"] == "percent":
					effect_value = str(data["value"] * 100) + "%"
				elif data["value_type"] == "number":
					effect_value = str(int(data["value"]))
				var effect_str = "[color=#7ac8ff]" + effect_value + "[/color]"
				description = description.replace("{" + data["field"] + "}", effect_str)
			$Description.text = description
		else:
			var effect_value = ""
			if effect.value_type == Constants.VALUE_TYPE_PERCENT:
				var value = effect.value * 100
				if value == int(value):
					effect_value = str(int(effect.value * 100)) + "%"
				else:
					effect_value = str(effect.value * 100) + "%"
			else:
				effect_value = str(int(effect.value))
		
			var effect_str = "[color=#7ac8ff]" + effect_value + "[/color]"
			var mp_str = "[color=#7ac8ff]" + str(int(data_skill.get_mp_cost())) + "[/color]"
			$Description.text = data_skill.description.replace("{d}", effect_str).replace("{m}", mp_str)
	elif data_skill is DataAttriBuffSkill:
		_show_attribute_str(data_skill)


func _show_attribute_str(data_skill: DataAttriBuffSkill):
	var attribute_str = ""

	if data_skill.ability_list.size() > 0:
		var ability = data_skill.ability_list[data_skill.level - 1]
		if ability.power != 0:
			attribute_str += "，" + "力量" + str(ability.power)
		if ability.agility != 0:
			attribute_str += "，" + "敏捷" + str(ability.agility)
		if ability.intelligence != 0:
			attribute_str += "，" + "智力" + str(ability.intelligence)
		if ability.luck != 0:
			attribute_str += "，" + "运气" + str(ability.luck)
	
	if data_skill.details_list.size() > 0:
		var details = data_skill.details_list[data_skill.level - 1]
		if details.attack != 0:
			attribute_str += "，" + "攻击" + str(details.attack)
		if details.defense != 0:
			attribute_str += "，" + "防御" + str(details.defense)
		if details.magic != 0:
			attribute_str += "，" + "魔法" + str(details.magic)
		if details.magic_def != 0:
			attribute_str += "，" + "魔防" + str(details.magic_def)
		if details.accuracy != 0:
			attribute_str += "，" + "命中" + str(details.accuracy)
		if details.evasion != 0:
			attribute_str += "，" + "闪避" + str(details.evasion)
		if details.hand_technology != 0:
			attribute_str += "，" + "手技" + str(details.hand_technology)
		if details.recover_hp != 0:
			attribute_str += "，" + "生命恢复" + str(details.recover_hp)
		if details.max_hp != 0:
			attribute_str += "，" + "最大生命" + str(details.max_hp)
		if details.max_mp != 0:
			attribute_str += "，" + "最大蓝量" + str(details.max_mp)

	$Description.text = data_skill.description + attribute_str


func _on_use_bt_pressed() -> void:
	skill_used.emit(data_skill)


func _on_active_button_toggled(toggled_on: bool) -> void:
	skill_active_toggled.emit(data_skill, toggled_on)
