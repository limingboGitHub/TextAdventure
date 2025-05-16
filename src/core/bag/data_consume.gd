class_name DataConsume extends DataBagItem

## 背包物品的消耗类

class Recovery:
	# 恢复生命值
	var spec_hp: int = 0
	# 恢复魔法值
	var spec_mp: int = 0
	# 恢复生命值百分比
	var spec_hp_r: float = 0
	# 恢复魔法值百分比
	var spec_mp_r: float = 0

	func save() -> Dictionary:
		return {
			"spec_hp": spec_hp,
			"spec_mp": spec_mp,
			"spec_hp_r": spec_hp_r,
			"spec_mp_r": spec_mp_r
		}
	
	func load(json: Dictionary) -> void:
		if json.has("spec_hp"):
			spec_hp = json["spec_hp"]
		if json.has("spec_mp"):
			spec_mp = json["spec_mp"]
		if json.has("spec_hp_r"):
			spec_hp_r = json["spec_hp_r"]
		if json.has("spec_mp_r"):
			spec_mp_r = json["spec_mp_r"]


class Scroll:
	# 使用类型
	var use_type: String = ""
	# 成功概率
	var success_rate: float = 0.0
	# 增加能力值属性
	var attribute_ability: AttributeAbility = AttributeAbility.new()
	# 增加属性值
	var attribute_details: AttributeDetails = AttributeDetails.new()
	# 增加特殊效果
	var data_effect: DataEffect

	func save() -> Dictionary:
		var json = {
			"success_rate": success_rate,
			"attribute_ability": attribute_ability.save(),
			"attribute_details": attribute_details.save(),
			"use_type": use_type
		}
		if data_effect != null:
			json["data_effect"] = data_effect.save()
		return json


	func load(json: Dictionary) -> void:
		if json.has("success_rate"):
			success_rate = json["success_rate"]
		if json.has("attribute_ability"):
			attribute_ability.load(json["attribute_ability"])
		if json.has("attribute_details"):
			attribute_details.load(json["attribute_details"])
		if json.has("use_type"):
			use_type = json["use_type"]
		if json.has("data_effect"):
			data_effect = DataEffect.new(json["data_effect"]["id"],json["data_effect"]["type"])
			data_effect.value = json["data_effect"]["value"]


# 恢复属性
var recovery: Recovery

# 增加buff属性
var data_buff: DataBuff

# 卷轴
var scroll: Scroll


static func is_consume(_id: String) -> bool:
	return _id.begins_with("consume")


func _init() -> void:
	super._init()
	type = TYPE_CONSUME


func save() -> Dictionary:
	var json = super.save()
	if recovery != null:
		json["recovery"] = recovery.save()
	if data_buff != null:
		json["data_buff"] = data_buff.save()
	if scroll != null:
		json["scroll"] = scroll.save()
	return json


func load(json: Dictionary) -> void:
	super.load(json)
	if json.has("recovery"):
		recovery = Recovery.new()
		recovery.load(json["recovery"])
	if json.has("data_buff"):
		data_buff = DataBuff.new()
		data_buff.load(json["data_buff"])
	if json.has("scroll"):
		scroll = Scroll.new()
		scroll.load(json["scroll"])


func copy() -> DataConsume:
	var dic = save()
	var new_item = DataConsume.new()
	new_item.load(dic)
	# 物品的uuid需要重新生成
	new_item.uuid = RandomTool.random_num()
	return new_item
