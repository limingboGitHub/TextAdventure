class_name DataMonsterSkill

## 怪物技能基类
## 唯一标识
var id: String
## 技能名称
var name: String
## 技能类型
var type: String


## 蓄力攻击
class ChargeAttack extends DataMonsterSkill:
	## 蓄力时间最小值
	var charge_time_min: float
	## 蓄力时间最大值
	var charge_time_max: float
	## 蓄力伤害步长
	var charge_damage_step: float
	## 每段步长增加的伤害
	var charge_damage_step_value: float
	## 技能开始CD
	var start_cd: float
	## 技能CD
	var cd: float
	
	## 将对象序列化为字典(私有方法)
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"type": type,
			"charge_time_min": charge_time_min,
			"charge_time_max": charge_time_max,
			"charge_damage_step": charge_damage_step,
			"charge_damage_step_value": charge_damage_step_value,
			"start_cd": start_cd,
			"cd": cd
		}
	
	## 从字典创建对象(私有静态方法)
	func from_dict(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		type = data.get("type", "")
		charge_time_min = data.get("charge_time_min", 0.0)
		charge_time_max = data.get("charge_time_max", 0.0)
		charge_damage_step = data.get("charge_damage_step", 0.0)
		charge_damage_step_value = data.get("charge_damage_step_value", 0.0)
		start_cd = data.get("start_cd", 0.0)
		cd = data.get("cd", 0.0)


static func create_monster_skill(monster_config) -> DataMonsterSkill:
	var _type = monster_config["type"]
	if _type == "charge_attack":
		var charge_attack = ChargeAttack.new()
		charge_attack.from_dict(monster_config)
		return charge_attack
	
	return null
