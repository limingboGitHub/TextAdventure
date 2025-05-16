class_name DataSkillBag

## 技能背包
##
## 承载玩家所拥有的技能

# 技能背包 key:技能所属阶段 value:技能列表
var data: Dictionary = {}
# 普攻
var normal_attack: DataAttackSkill
# 可分配技能点
var skill_point: int = 0

# 技能信息
var skill_dic: Dictionary = {}
# 技能特效信息
var effect_dic: Dictionary = {}

## 技能id枚举
##
## 普通攻击
const NORMAL_ATTACK = "skill_000000"

signal skill_point_updated(skill_point: int)

signal skill_added(phase: String, skill: DataBaseSkill)

signal skill_level_updated(skill: DataBaseSkill)


# 注入技能字典信息，并初始化普攻，如果背包中存在技能，则初始化
func init_dic(_skill_dic: Dictionary, _effect_dic: Dictionary) -> void:
	self.skill_dic = _skill_dic
	self.effect_dic = _effect_dic

	normal_attack = create_normal_attack()

	for phase in data.keys():
		for skill in data[phase]:
			assert(skill_dic.has(skill.id))
			_load_skill(skill, skill_dic[skill.id])
			# 监听技能等级变化
			skill.level_changed.connect(_on_skill_level_changed)


func add_skill(phase: String, skill: DataBaseSkill) -> void:
	if data.has(phase):
		data[phase].append(skill)
	else:
		data[phase] = [skill]
	skill_added.emit(phase, skill)
	# 监听技能等级变化
	skill.level_changed.connect(_on_skill_level_changed)


func _on_skill_level_changed(data_skill: DataBaseSkill):
	skill_level_updated.emit(data_skill)


## 根据id生产技能
## @return 技能实例或者null
func create(id: String):
	if id == NORMAL_ATTACK:
		return normal_attack
	elif skill_dic.has(id):
		var one_skill_dic = skill_dic[id]
		var skill = create_by_type(id, one_skill_dic["type"])
		_load_skill(skill, one_skill_dic)
		return skill
	else:
		return null


## 根据类型生产技能
## @return 技能实例或者null
func create_by_type(id: String, type: String):
	if type == "attack":
		return DataAttackSkill.new(id, type)
	elif type == "effect_buff":
		return DataEffectBuffSkill.new(id, type)
	elif type == "attribute_buff":
		return DataAttriBuffSkill.new(id, type)
	# TODO 其他类型技能
	else:
		return null


# 根据技能字典加载技能详情
func _load_skill(data_skill: DataBaseSkill, one_skill_dic: Dictionary):
	# 技能公共信息
	data_skill.name = one_skill_dic["name"]
	data_skill.description = one_skill_dic["desc"]
	# 技能基础信息
	if one_skill_dic.has("cd"):
		data_skill.cd = one_skill_dic["cd"]
	data_skill.max_level = one_skill_dic["max_level"]
	if one_skill_dic.has("distance"):
		data_skill.distance = one_skill_dic["distance"]
	if one_skill_dic.has("center_type"):
		data_skill.center_type = one_skill_dic["center_type"]
	if one_skill_dic.has("radius"):
		data_skill.radius = one_skill_dic["radius"]
	if one_skill_dic.has("time"):
		data_skill.time = one_skill_dic["time"]
	
	if data_skill is DataAttackSkill:
		# 技能攻击信息
		var attack_dic = one_skill_dic["attack"]
		data_skill.count = attack_dic["count"]
		data_skill.target_type = 1
		# 伤害加成类型
		if attack_dic.has("damage_source_type"):
			data_skill.damage_source_type = attack_dic["damage_source_type"]
		# 最终造成的伤害类型
		if attack_dic.has("damage_type"):
			data_skill.damage_type = attack_dic["damage_type"]
		# 多段伤害间隔
		if attack_dic.has("damage_interval"):
			data_skill.damage_interval = attack_dic["damage_interval"]
		# 技能弹道移动速度
		if attack_dic.has("skill_move_speed"):
			data_skill.skill_move_speed = attack_dic["skill_move_speed"]
		# 伤害计算
		if attack_dic.has("calculate_type"):
			if attack_dic["calculate_type"] == "formula":
				#region 公式计算
				# 伤害数组
				data_skill.damage_level = get_formula_array(
					attack_dic["start_damage"],
					attack_dic["step_damage"],
					data_skill.max_level)
				# 蓝耗数组
				data_skill.mp_cost_level = get_formula_array(
					attack_dic["start_mp"],
					attack_dic["step_mp"],
					data_skill.max_level)
				#endregion
			elif attack_dic["calculate_type"] == "enum":
				#region 枚举计算
				data_skill.damage_level = attack_dic["damage"]
				data_skill.mp_cost_level = attack_dic["mp"]
				#endregion
		# 伤害数值类型
		if attack_dic.has("value_type"):
			data_skill.damage_value_type = attack_dic["value_type"]
		
	elif data_skill is DataEffectBuffSkill:
		# 技能效果buff信息
		var buff_dic = one_skill_dic["buff"]
		# 技能值和蓝耗计算方式
		if buff_dic.has("calculate_type") and buff_dic.has("start_mp"):
			var calculate_type = buff_dic["calculate_type"]
			# 蓝耗计算
			if calculate_type == "formula":
				data_skill.mp_cost_level = get_formula_array(
					buff_dic["start_mp"],
					buff_dic["step_mp"],
					data_skill.max_level)
			elif calculate_type == "enum":
				data_skill.mp_cost_level = buff_dic["mp"]
		# 技能效果计算
		for skill_effect_dic in buff_dic["effect_list"]:
			# 技能特效ID
			var effect_id = skill_effect_dic["id"]
			# 数值计算方式
			var calculate_type = skill_effect_dic["calculate_type"]
			# 技能特效信息
			var effect_info = self.effect_dic[effect_id]
			var effect_type = effect_info["effect_type"]

			if effect_type == "skill_enhance":
				# 技能增强类特效
				_load_skill_enhance(data_skill, skill_effect_dic)
			else:
				# 其他特效
				var value_type = effect_info["value_type"]

				for i in range(data_skill.max_level):
					var value = 0
					if calculate_type == "formula":
						value = get_formula_value(
								skill_effect_dic["start_value"],
								skill_effect_dic["step_value"],
								i)
					elif calculate_type == "enum":
						value = skill_effect_dic["value"][i]
					var effect = DataEffect.new(effect_id, effect_type)
					effect.value = value
					effect.value_type = value_type
					if skill_effect_dic.has("radius"):
						effect.radius = skill_effect_dic["radius"]
					if skill_effect_dic.has("invoke_interval"):
						effect.invoke_interval = skill_effect_dic["invoke_interval"]
					data_skill.effect_list.append(effect)

		# 根据当前技能信息更新技能效果
		data_skill.update_mp_cost()
	elif data_skill is DataAttriBuffSkill:
		_load_attribute_buff_skill(data_skill, one_skill_dic)


# 添加技能增强类型的技能效果
func _load_skill_enhance(data_skill: DataEffectBuffSkill, skill_effect_dic: Dictionary):
	var effect_id = skill_effect_dic["id"]
	var effect_info = self.effect_dic[effect_id]
	if not effect_info.has("skill_enhance"):
		return
	# 技能增强信息
	var effect_enhance_info = effect_info["skill_enhance"]
	# 增加的技能id
	var skill_id = effect_enhance_info["skill_id"]
	# 增加的技能名称
	var skill_name = skill_dic[skill_id]["name"]
	# 数值计算方式
	var calculate_type = skill_effect_dic["calculate_type"]
	# 技能增强类型
	var effect_type = effect_info["effect_type"]

	for i in range(data_skill.max_level):
		var effect = DataEffect.new(effect_id, effect_type)

		var skill_enhance = DataSkillEnhance.new()
		skill_enhance.skill_id = skill_id
		skill_enhance.name = skill_name

		# 遍历技能增强了那些属性
		for field in skill_enhance.get_fields():
			# 计算技能增强的值
			var value = 0.0
			if calculate_type == "formula":
				if not skill_effect_dic.has("start_" + field):
					continue

				var start_value = skill_effect_dic["start_" + field]
				var step_value = skill_effect_dic["step_" + field]
				value = get_formula_value(
						start_value,
						step_value,
						i)
			elif calculate_type == "enum":
				if not skill_effect_dic.has("value"):
					continue

				value = skill_effect_dic["value"][i]

			# 设置技能增强的值
			skill_enhance.set_field(field, value)
		
		effect.skill_enhance = skill_enhance
		# 将技能增强添加到技能效果列表中
		data_skill.effect_list.append(effect)

		
# 加载属性buff技能
# 
# 由于存在多种属性值的属性值不同level的成长情况，所以在配置文件中每一种属性值以列表的形式描述。
# 例如：
# "attribute_list": [
# 	{
# 		"attribute_details": "attack",
# 		"start_value": 10,
# 		"step_value": 2
# 	}
# ]
# 
# 因此解析过程为：
# 1. 遍历属性列表，将所有的属性都归纳到同一个属性字典中，最后形成一个长度为max_level的数组
# 2. 同时填充好属性对应的不同等级的值
# 3. 将数组进行反序列化，得到两个长度为max_level的Attribute数组
func _load_attribute_buff_skill(data_skill: DataAttriBuffSkill, one_skill_dic: Dictionary):
	# 技能属性buff信息
	var buff_dic = one_skill_dic["buff"]

	# 能力值属性Dic的列表，用于表示长度为max_level的数组
	var ability_list = []
	# 详细属性Dic的列表，用于表示长度为max_level的数组
	var details_list = []
	# 遍历属性的配置清单，将所有的属性都归纳到同一个属性Dic中
	for attribute_dic in buff_dic["attribute_list"]:
		# 数值计算方式
		var calculate_type = attribute_dic["calculate_type"]
		# 计算每个等级的属性值
		for i in range(data_skill.max_level):
			var attribute_value = 0
			if calculate_type == "formula":
				attribute_value = get_formula_value(
					attribute_dic["start_value"],
					attribute_dic["step_value"],
					i)
			elif calculate_type == "enum":
				attribute_value = attribute_dic["value"][i]

			# 将对应等级的属性值添加到能力值属性列表中
			if attribute_dic.has("attribute_details"):
				# 属性名称
				var attribute_name = attribute_dic["attribute_details"]
				# 如果详细属性列表长度小于当前等级，则添加一个空字典
				if details_list.size() <= i:
					details_list.append({})
				# 将属性值添加到详细属性列表中
				details_list[i][attribute_name] = attribute_value
				
			elif attribute_dic.has("attribute_ability"):
				# 能力值名称
				var attribute_name = attribute_dic["attribute_ability"]
				# 如果能力值列表长度小于当前等级，则添加一个0
				if ability_list.size() <= i:
					ability_list.append({})
				# 将属性值添加到能力值列表中
				ability_list[i][attribute_name] = attribute_value

	# 将长度为max_level的dic数组进行反序列化
	for i in range(data_skill.max_level):
		if ability_list.size() > i:
			var ability = AttributeAbility.new()
			ability.load(ability_list[i])
			data_skill.ability_list.append(ability)
		if details_list.size() > i:
			var details = AttributeDetails.new()
			details.load(details_list[i])
			data_skill.details_list.append(details)


# 根据公式信息输出数组
# @param start_value: 初始值，可能是一个int数组或者int值，int数组表示多段伤害
# @param step_value: 每级增加值，可能是一个int数组或者int值，int数组表示多段增加值
# @param max_level: int 最大等级
# @return: Array 返回一个二维数组，每个子数组表示一个等级的多段伤害值
func get_formula_array(start_value, step_value, max_level: int) -> Array:
	var array = []
	for i in range(max_level):
		if start_value is Array:
			var damage_array = []
			for j in range(start_value.size()):
				damage_array.append(start_value[j] + step_value[j] * i)
			array.append(damage_array)
		else:
			array.append(start_value + step_value * i)
	return array


# 根据公式信息输出值
# @param start_value: 初始值，可能是一个int数组或者int值，int数组表示多段伤害
# @param step_value: 每级增加值，可能是一个int数组或者int值，int数组表示多段增加值
# @param max_level: int 最大等级
# @return: float 返回一个值
func get_formula_value(start_value, step_value, max_level: int) -> float:
	return start_value + step_value * max_level


func add_skill_point(value: int):
	skill_point += value
	skill_point_updated.emit(skill_point)


func remove_skill_point(value: int):
	skill_point -= value
	skill_point_updated.emit(skill_point)


func get_skill_by_phase(phase: String) -> Array:
	if data.has(phase):
		return data[phase]
	else:
		return []


func get_skill_by_id(id: String) -> DataBaseSkill:
	for phase in data.keys():
		for skill in data[phase]:
			if skill.id == id:
				return skill
	return null


static func create_normal_attack() -> DataAttackSkill:
	var data_skill = DataAttackSkill.new(NORMAL_ATTACK, "attack")
	data_skill.name = "普通攻击"
	data_skill.target_type = 1
	data_skill.count = 1
	data_skill.level = 1
	data_skill.cd = 1
	data_skill.damage_level = [[1.0]]
	return data_skill


func get_skill(skill_id: String)-> DataBaseSkill:
	if skill_id == NORMAL_ATTACK:
		return normal_attack
	for phase in data.keys():
		for skill in data[phase]:
			if skill.id == skill_id:
				return skill
	return null


func save() -> Dictionary:
	var save_data = {}
	
	# 保存技能点
	save_data["skill_point"] = skill_point
	
	# 保存各阶段技能
	var phases_data = {}
	for phase in data.keys():
		var skills_data = []
		for skill in data[phase]:
			skills_data.append(skill.save())
		phases_data[phase] = skills_data
	
	save_data["phases"] = phases_data
	
	return save_data


func load(dic: Dictionary):
	# 加载技能点
	if dic.has("skill_point"):
		skill_point = dic["skill_point"]
	
	# 加载各阶段技能
	if dic.has("phases"):
		var phases_data = dic["phases"]
		for phase in phases_data.keys():
			var skills_data = phases_data[phase]
			if not data.has(phase):
				data[phase] = []
				
			for skill_data in skills_data:
				if skill_data.has("id"):
					var skill = create_by_type(skill_data["id"], skill_data["type"])
					if skill:
						skill.level = skill_data["level"]
						data[phase].append(skill)
