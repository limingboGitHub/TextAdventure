class_name DataSkillEnhance

# 技能增强效果

# 技能ID
var skill_id: String
# 技能名称
var name: String

# 伤害
var damage: float
# 释放距离
var distance: int
# 作用范围
var radius: int
# 作用目标数量
var count: int
# 冷却时间
var cd: float
# 技能追加次数
var add_count: int
# 技能追加概率
var add_probability: float
# mp消耗
var mp_cost: int


func is_empty() -> bool:
	return damage == 0 and distance == 0 and radius == 0 and count == 0 and cd == 0 \
	and add_count == 0 and add_probability == 0 and mp_cost == 0


func append(data_skill_enhance: DataSkillEnhance) -> void:
	distance += data_skill_enhance.distance
	radius += data_skill_enhance.radius
	count += data_skill_enhance.count
	cd += data_skill_enhance.cd
	add_count += data_skill_enhance.add_count
	add_probability += data_skill_enhance.add_probability
	mp_cost += data_skill_enhance.mp_cost
	damage += data_skill_enhance.damage


func remove(data_skill_enhance: DataSkillEnhance) -> void:
	distance -= data_skill_enhance.distance
	radius -= data_skill_enhance.radius
	count -= data_skill_enhance.count
	cd -= data_skill_enhance.cd
	add_count -= data_skill_enhance.add_count
	add_probability -= data_skill_enhance.add_probability
	mp_cost -= data_skill_enhance.mp_cost
	damage -= data_skill_enhance.damage


# 获取所有字段
func get_fields() -> Array:
	return [
		"distance",
		"radius",
		"count",
		"cd",
		"add_count",
		"add_probability",
		"mp_cost",
		"damage",
	]


func set_field(field: String, value: float) -> void:
	if field == "distance":
		distance = int(value)
	elif field == "radius":
		radius = int(value)
	elif field == "count":
		count = int(value)
	elif field == "cd":
		cd = float(value)
	elif field == "add_count":
		add_count = int(value)
	elif field == "add_probability":
		add_probability = float(value)
	elif field == "mp_cost":
		mp_cost = int(value)
	elif field == "damage":
		damage = float(value)


# 获取第一个不为0的字段
# 返回字典:
# {"field": "distance", "value": 100,"value_type":"number/percent"}
func get_not_zero_fields() -> Array:
	var data_list = []	
	if distance != 0:
		data_list.append({
			"field": "distance",
			"value": distance,
			"value_type": "number"
		})
	if radius != 0:
		data_list.append({
			"field": "radius",
			"value": radius,
			"value_type": "number"
		})
	if count != 0:
		data_list.append({
			"field": "count",
			"value": count,
			"value_type": "number"
		})
	if cd != 0:
		data_list.append({
			"field": "cd",
			"value": cd,
			"value_type": "number"
		})
	if add_count != 0:
		data_list.append({
			"field": "add_count",
			"value": add_count,
			"value_type": "number"
		})
	if add_probability != 0:
		data_list.append({
			"field": "add_probability",
			"value": add_probability,
			"value_type": "percent"
		})
	if mp_cost != 0:
		data_list.append({
			"field": "mp_cost",
			"value": mp_cost,
			"value_type": "number"
		})
	if damage != 0:
		data_list.append({
			"field": "damage",
			"value": damage,
			"value_type": "number"
		})
	return data_list


func copy() -> DataSkillEnhance:
	var data_skill_enhance = DataSkillEnhance.new()
	data_skill_enhance.skill_id = skill_id
	data_skill_enhance.name = name
	data_skill_enhance.distance = distance
	data_skill_enhance.radius = radius
	data_skill_enhance.count = count
	data_skill_enhance.cd = cd
	data_skill_enhance.add_count = add_count
	data_skill_enhance.add_probability = add_probability
	data_skill_enhance.mp_cost = mp_cost
	data_skill_enhance.damage = damage
	return data_skill_enhance


func save() -> Dictionary:
	var data = {
		"skill_id": skill_id,
		"name": name
	}
	if distance != 0:
		data["distance"] = distance
	if radius != 0:
		data["radius"] = radius
	if count != 0:
		data["count"] = count
	if cd != 0:
		data["cd"] = cd
	if add_count != 0:
		data["add_count"] = add_count
	if add_probability != 0:
		data["add_probability"] = add_probability
	if mp_cost != 0:
		data["mp_cost"] = mp_cost
	if damage != 0:
		data["damage"] = damage
	return data


func load(data: Dictionary) -> void:
	skill_id = data["skill_id"]
	name = data["name"]
	if data.has("distance"):
		distance = data["distance"]
	if data.has("radius"):
		radius = data["radius"]
	if data.has("count"):
		count = data["count"]
	if data.has("cd"):
		cd = data["cd"]
	if data.has("add_count"):
		add_count = data["add_count"]
	if data.has("add_probability"):
		add_probability = data["add_probability"]
	if data.has("mp_cost"):
		mp_cost = data["mp_cost"]
	if data.has("damage"):
		damage = data["damage"]

