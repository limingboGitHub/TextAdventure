class_name DataEquip extends DataBagItem

## 背包物品的装备类

## 装备类型 
##
# 武器
const TYPE_WEAPON = "weapon"
# 上衣
const TYPE_UPPER_BODY = "upper_body"
# 下衣
const TYPE_LOWER_BODY = "lower_body"
# 帽子
const TYPE_CAP = "cap"
# 鞋子
const TYPE_SHOES = "shoes"
# 当前装备类型
var equip_type: String = ""
# 攻击速度
var attack_speed: int = 0

## 装备强化等级
##
## 用于描述装备的强化程度。
## 强化卷轴有强弱之分，不同强度的卷轴强化成功后增加的强化经验值不同。
## 例如：80%成功率的卷轴增加2点力量，可能只增加50点强化经验值，而50%成功率的卷轴增加4点力量，可能增加100点强化经验值。
## 某种程度上说，强化等级越高，则表示装备越好。
## 视图层可根据强化等级来显示装备不同的特效
# 强化等级
var upgrade_level: int = 0
# 强化经验值
var upgrade_exp: int = 0
# 强化经验值上限
var upgrade_exp_max: int = 4


# 装备要求
var require_level: int = 0
var require_job: String = ""
var require_power: int = 0
var require_agility: int = 0
var require_intelligence: int = 0
var require_luck: int = 0

# 最大强化次数
var max_upgrade_times: int = 0
# 当前强化次数
var current_upgrade_times: int = 0
# 当前强化成功次数
var current_upgrade_success_times: int = 0

# 基础能力值
var ability: AttributeAbility = AttributeAbility.new()
# 基础详情属性
var details: AttributeDetails = AttributeDetails.new()

# 强化能力值属性
var upgrade_ability: AttributeAbility = AttributeAbility.new()
# 强化详情属性
var upgrade_details: AttributeDetails = AttributeDetails.new()

# 最终属性
var final_ability: AttributeAbility = AttributeAbility.new()
var final_details: AttributeDetails = AttributeDetails.new()

# 装备特殊效果，key为效果id，value为效果。使用id作为唯一标识，覆盖处理
var data_effects: Dictionary[String, DataEffect] = {}


signal updated(item: DataEquip)


static func is_equip(_id: String) -> bool:
	return _id.begins_with(TYPE_WEAPON) or _id.begins_with(TYPE_UPPER_BODY) \
		or _id.begins_with(TYPE_LOWER_BODY) or _id.begins_with(TYPE_CAP) \
		or _id.begins_with(TYPE_SHOES)


func _init() -> void:
	super._init()
	type = TYPE_EQUIP


func init_ability(ability_json):
	ability.load(ability_json)
	final_ability = get_all_ability()


func init_details(details_json):
	details.load(details_json)
	final_details = get_all_details()


func has_ability() -> bool:
	return not ability.is_empty() or not upgrade_ability.is_empty()


func has_details() -> bool:
	return not details.is_empty() or not upgrade_details.is_empty()


func clear() -> void:
	super.clear()


func can_upgrade() -> bool:
	return current_upgrade_times < max_upgrade_times


func can_upgrade_num() -> int:
	return max_upgrade_times - current_upgrade_times


func update_final_ability() -> void:
	final_ability = get_all_ability()
	final_details = get_all_details()
	updated.emit(self)


func upgrade_success(
	_ability: AttributeAbility, 
	_details: AttributeDetails,
	_effect: DataEffect
	) -> void:
	if _ability != null:
		upgrade_ability.append(_ability)
	if _details != null:
		upgrade_details.append(_details)
	if _effect != null:
		add_effect(_effect)
		
	final_ability = get_all_ability()
	final_details = get_all_details()

	# 增加强化次数
	current_upgrade_times += 1
	current_upgrade_success_times += 1

	# 增加强化经验值
	add_upgrade_exp(_get_upgrade_exp(_ability, _details,_effect))

	updated.emit(self)



func change_quality(_quality: String) -> void:
	quality = _quality
	updated.emit(self)


func upgrade_failed() -> void:
	current_upgrade_times += 1
	
	updated.emit(self)


func _get_upgrade_exp(
	_ability: AttributeAbility, 
	_details: AttributeDetails, 
	_effect: DataEffect
) -> int:
	var result_exp = 0
	if _ability != null:
		result_exp += _ability.power
		result_exp += _ability.agility
		result_exp += _ability.intelligence
		result_exp += _ability.luck
	if _details != null:
		result_exp += _details.max_hp * 0.1
		result_exp += _details.max_mp * 0.1
		result_exp += _details.attack
		result_exp += _details.defense
		result_exp += _details.magic
		result_exp += _details.magic_def
		result_exp += _details.accuracy
		result_exp += _details.evasion
		result_exp += _details.hand_technology
		result_exp += _details.recover_hp
		result_exp += _details.recover_mp
		result_exp += _details.exp_gain * 50
	if _effect != null:
		result_exp += 8
		
	return result_exp


func add_upgrade_exp(_exp: int) -> void:
	upgrade_exp += _exp
	if upgrade_exp >= upgrade_exp_max:
		upgrade_level_up()


func upgrade_level_up() -> void:
	upgrade_exp = upgrade_exp - upgrade_exp_max
	upgrade_level += 1
	# 提升强化经验值上限
	if upgrade_level == 3:
		upgrade_exp_max = -1
	else:
		upgrade_exp_max += upgrade_level * 10
	print("强化等级：", upgrade_level, " 强化经验值上限：", upgrade_exp_max)
	
	if upgrade_exp_max != -1 and upgrade_exp >= upgrade_exp_max:
		upgrade_level_up()
		
		
func get_all_ability() -> AttributeAbility:
	var all_ability = AttributeAbility.new()
	all_ability.append(ability)
	all_ability.append(upgrade_ability)
	return all_ability


func get_all_details() -> AttributeDetails:
	var all_details = AttributeDetails.new()
	all_details.append(details)
	all_details.append(upgrade_details)
	return all_details


func add_effect(effect: DataEffect) -> void:
	data_effects[effect.id] = effect


func get_all_effects() -> Array[DataEffect]:
	var effects: Array[DataEffect] = []
	for effect in data_effects.values():
		effects.append(effect)
	return effects


# save方法只保存需要额外存储的信息，其他信息可以在资源配置信息中获取
func save() -> Dictionary:
	var json = super.save()
	json["current_upgrade_times"] = current_upgrade_times
	json["current_upgrade_success_times"] = current_upgrade_success_times
	if not ability.is_empty():
		json["ability"] = ability.save()
	if not details.is_empty():
		json["details"] = details.save()
	if not upgrade_ability.is_empty():
		json["upgrade_ability"] = upgrade_ability.save()
	if not upgrade_details.is_empty():
		json["upgrade_details"] = upgrade_details.save()
	if not data_effects.is_empty():
		json["data_effects"] = {}
		for effect in data_effects.values():
			json["data_effects"][effect.id] = effect.save()
	json["upgrade_level"] = upgrade_level
	json["upgrade_exp"] = upgrade_exp
	json["upgrade_exp_max"] = upgrade_exp_max
	return json


func load(json: Dictionary) -> void:
	super.load(json)
	current_upgrade_times = json["current_upgrade_times"]
	current_upgrade_success_times = json["current_upgrade_success_times"]
	
	if json.has("ability"):
		ability.load(json["ability"])
	if json.has("details"):
		details.load(json["details"])
	if json.has("upgrade_ability"):
		upgrade_ability.load(json["upgrade_ability"])
	if json.has("upgrade_details"):
		upgrade_details.load(json["upgrade_details"])
	if json.has("data_effects"):
		for effect_id in json["data_effects"].keys():
			var effect_type = json["data_effects"][effect_id]["type"]
			var data_effect = DataEffect.new(effect_id,effect_type)
			data_effect.load(json["data_effects"][effect_id])
			data_effects[effect_id] = data_effect
	if json.has("upgrade_level"):
		upgrade_level = json["upgrade_level"]
	if json.has("upgrade_exp"):
		upgrade_exp = json["upgrade_exp"]
	if json.has("upgrade_exp_max"):
		upgrade_exp_max = json["upgrade_exp_max"]


func copy() -> DataEquip:
	var dic = save()
	var new_item = DataEquip.new()
	new_item.load(dic)
	# 物品的uuid需要重新生成
	new_item.uuid = RandomTool.random_num()
	# 拷贝其他非额外存储的信息
	copy_other_info(new_item)
	return new_item
