class_name Attribute

## 属性类
##
## 最终属性由多个部分组成
## 1. 基础属性
## 2. 其他附加属性，如 装备、技能、活动等特殊效果
## 
## 其中能力值会经过一定的换算转换成最终属性，并附加上
## 比如力量，最终转换的攻击力值 = 力量 * 基础攻击属性

#region 属性有不同的来源，比如属性点分配、装备(已equip_type作为key)、技能、活动等，需要分别计算
const ATTRIBUTE_BASE = "base"

var ability_dic = {}
var all_ability = AttributeAbility.new()
#endregion

#region 详细属性
var details = {}
var all_details = AttributeDetails.new()
#endregion 

# 最终属性
var final_details = AttributeDetails.new()

#region 恢复属性
# 玩家休息状态时，恢复生命时间间隔n
const RECOVER_HP_INTERVAL = 2000
# 玩家休息状态时，每n秒回复的生命值
var recover_hp_rest = 5
# 玩家休息状态时，每n秒回复10点生命值的剩余时间
var recover_hp_rest_time = RECOVER_HP_INTERVAL

#endregion

# 防御常数。防御减伤率 = 防御 / (防御 + 防御常数)
const DEFENSE_CONSTANT = 200.0


signal updated(attribute: Attribute)


func add_ability(id: String, ability: AttributeAbility):
	ability_dic[id] = ability
	update()


func remove_ability(id: String):
	ability_dic.erase(id)
	update()


func get_ability(id: String) -> AttributeAbility:
	return ability_dic[id]


func add_details(id: String, _details: AttributeDetails):
	self.details[id] = _details
	update()


func get_details(id: String) -> AttributeDetails:
	return details[id]


func remove_details(id: String):
	self.details.erase(id)
	update()


func get_final_details() -> AttributeDetails:
	return final_details


func update():
	# 如果只有最终属性，没有base属性，则不更新（怪物没有base属性）
	if not details.has(ATTRIBUTE_BASE):
		return
	# 清空所有属性
	all_ability = AttributeAbility.new()
	all_details = AttributeDetails.new()
	# 汇总能力值
	for ability in ability_dic.values():
		all_ability.append(ability)

	# 汇总详细属性
	for one_details in details.values():
		all_details.append(one_details)

	# 计算最终属性
	# 重置
	final_details = AttributeDetails.new()
	# 复制all_details所有属性
	final_details.append(all_details)

	# 重新计算一些公式属性
	# 一点hp能力值 = 10hp，一点力量能力值 = 1hp，一点智力能力值 = 1mp
	final_details.max_hp = all_details.max_hp + all_ability.hp * 10 + all_ability.power * 1
	final_details.max_mp = all_details.max_mp + all_ability.mp * 10 + all_ability.intelligence * 1
	# 最终的攻击力，和能力值中的“力量”，“敏捷”有关，和属性详情中各种的“攻击力”加成有关
	final_details.attack = all_details.attack * (all_ability.power * 1 + all_ability.agility * 0.5 + all_ability.luck * 0.5) / 20
	final_details.defense = all_details.defense
	final_details.magic = all_details.magic * (all_ability.intelligence + all_ability.luck * 0.5) / 20
	final_details.magic_def = all_details.magic_def
	# 最终命中属性，和能力值中的“敏捷”和“幸运”有关
	final_details.accuracy = all_details.accuracy * 25 + (all_ability.agility * 5 + all_ability.luck * 5)
	# 最终的闪避属性，和能力值中“幸运”有关
	final_details.evasion = all_details.evasion + all_ability.luck * 1
	# 手技影响攻击的最小波动范围，敏捷影响手技
	final_details.hand_technology = all_details.hand_technology + all_ability.agility * 0.2
	
	updated.emit(self)


# 计算防御减伤率（当前不使用防御减伤率，使用防御减伤量）
func defense_reduction_rate() -> float:
	return 0


# 计算防御减伤量（减伤公式：减伤值 = 防御 * 0.5）
func defense_reduction_value() -> float:
	return final_details.defense * 0.5


# 计算魔法防御减伤率（当前不使用魔法防御减伤率，使用魔法防御减伤量）
func magic_defense_reduction_rate() -> float:
	return 0


# 计算魔法防御减伤量（减伤公式：减伤值 = 魔法防御 * 0.5）
func magic_defense_reduction_value() -> float:
	return final_details.magic_def * 0.5


func save() -> Dictionary:
	var ability_dic_to_save = {}
	for key in ability_dic.keys():
		ability_dic_to_save[key] = ability_dic[key].save()
	var details_dic_to_save = {}
	for key in details.keys():
		details_dic_to_save[key] = details[key].save()

	return {
		"ability_dic": ability_dic_to_save,
		"all_ability": all_ability.save(),
		"details": details_dic_to_save,
		"all_details": all_details.save(),
		"final_details": final_details.save() # Save final_details
	}


func load(dic: Dictionary):
	# Clear existing ability_list, details, and final_details
	ability_dic.clear()
	details.clear()

	# Load ability_list
	var ability_dic_loaded = dic["ability_dic"]
	for key in ability_dic_loaded.keys():
		var ability = AttributeAbility.new()
		ability.load(ability_dic_loaded[key])
		ability_dic[key] = ability

	# Load details
	var details_dic_loaded = dic["details"]
	for key in details_dic_loaded.keys():
		var detail = AttributeDetails.new()
		detail.load(details_dic_loaded[key])
		details[key] = detail

	# Load all_ability
	var all_ability_dic = dic["all_ability"]
	all_ability.load(all_ability_dic)

	# Load all_details
	var all_details_dic = dic["all_details"]
	all_details.load(all_details_dic)

	# Load final_details
	var final_details_dic = dic["final_details"]
	final_details.load(final_details_dic)
