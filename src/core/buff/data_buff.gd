class_name DataBuff

## Buff数据类
##
## 包含所增益的能力值、属性值、持续时间，剩余时间

# 增益的唯一标识、通过唯一标识处理覆盖和更新操作，可能是物品id，技能id
var id: String = ""
# 增益的名称
var name: String = ""
# buff类型 0: 增益 1: 减益
var buff_type: int = 0
# 增益的能力值
var attribute_ability: AttributeAbility
# 增益的属性值
var attribute_details: AttributeDetails
# 增益特殊效果 
var effects: Dictionary[String, DataEffect] = {}

# 持续时间 单位：秒
var duration: float = -1
# 剩余时间 单位：秒
var remaining_time: float = -1
# 上一次buff更新时剩余的时间 单位：秒 buff的显示更新不需要每帧更新
var last_update_time: int = 0


signal buff_updated(buff: DataBuff)

signal buff_removed(buff: DataBuff)


func is_permanent() -> bool:
	return duration == -1


# 减少剩余时间
# @param delta float 减少的时间
func reduce_buff_time(delta: float):
	remaining_time -= delta
	if remaining_time <= 0:
		buff_removed.emit(self)
	else:
		# 每秒更新一次buff显示
		if int(remaining_time) != last_update_time:
			last_update_time = int(remaining_time)
			buff_updated.emit(self)


func remove():
	buff_removed.emit(self)


func add_effect(effect: DataEffect) -> void:
	effects[effect.id] = effect


func get_all_effects() -> Array[DataEffect]:
	var result: Array[DataEffect] = []
	for effect in effects.values():
		result.append(effect)
	return result


func get_effect(effect_type: String) -> DataEffect:
	if effects.has(effect_type):
		return effects[effect_type]
	return null


func set_active(active: bool):
	for effect in effects.values():
		effect.set_active(active)


func save() -> Dictionary:
	var json = {}
	json["id"] = id
	json["name"] = name
	json["buff_type"] = buff_type
	if attribute_details != null:
		json["attribute_details"] = attribute_details.save()
	if attribute_ability != null:
		json["attribute_ability"] = attribute_ability.save()
	if effects.size() > 0:
		json["effects"] = {}
		for effect in effects.values():
			json["effects"][effect.type] = effect.save()
	json["duration"] = duration
	json["remaining_time"] = remaining_time
	json["last_update_time"] = last_update_time
	return json


func load(json: Dictionary) -> void:
	id = json["id"]
	name = json["name"]
	buff_type = json["buff_type"]
	if json.has("attribute_ability"):
		attribute_ability = AttributeAbility.new()
		attribute_ability.load(json["attribute_ability"])
	if json.has("attribute_details"):
		attribute_details = AttributeDetails.new()
		attribute_details.load(json["attribute_details"])
	if json.has("effects"):
		effects = {}
		for effect in json["effects"].values():
			var data_effect = DataEffect.new(effect["id"],effect["type"])
			data_effect.value = effect["value"]
			effects[effect["type"]] = data_effect
	duration = json["duration"]
	remaining_time = json["remaining_time"]
	last_update_time = json["last_update_time"]


func copy()-> DataBuff:
	var json = save()
	var new_buff = DataBuff.new()
	new_buff.load(json)
	return new_buff
