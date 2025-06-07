class_name DataMonsterSkill

## 怪物特殊技能基类（该技能区别于DataAttackSkill，只携带一些信息，不做攻击事件处理）
## 唯一标识
var id: String
## 技能名称
var name: String
## 技能类型
var type: String
## 技能开始CD
var start_cd: float
## 技能CD
var cd: float
## 剩余cd
var cd_rest: float

# 基类的to_dict方法
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"start_cd": start_cd,
		"cd": cd
	}


# 基类的from_dict方法
func from_dict(data: Dictionary):
	id = data.get("id", "")
	name = data.get("name", "")
	type = data.get("type", "")
	start_cd = data.get("start_cd", 0.0)
	cd = data.get("cd", 0.0)


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
	
	
	## 将对象序列化为字典(私有方法)
	func to_dict() -> Dictionary:
		var dic = super.to_dict()
		dic.merge({
			"charge_time_min": charge_time_min,
			"charge_time_max": charge_time_max,
			"charge_damage_step": charge_damage_step,
			"charge_damage_step_value": charge_damage_step_value
		})
		return dic
	
	## 从字典创建对象(私有静态方法)
	func from_dict(data: Dictionary):
		super.from_dict(data)
		charge_time_min = data.get("charge_time_min", 0.0)
		charge_time_max = data.get("charge_time_max", 0.0)
		charge_damage_step = data.get("charge_damage_step", 0.0)
		charge_damage_step_value = data.get("charge_damage_step_value", 0.0)


## 召唤小怪
class SpawnMonster extends DataMonsterSkill:
	## 召唤怪物列表
	var monster_id_list: Array[String]
	## 召唤怪物数量
	var monster_count: int

	## 将对象序列化为字典(私有方法)
	func to_dict() -> Dictionary:
		var dic = super.to_dict()
		dic.merge({
			"monster_id_list": monster_id_list,
			"monster_count": monster_count
		})
		return dic

	## 从字典创建对象(私有静态方法)
	func from_dict(data: Dictionary):
		super.from_dict(data)
		if data.has("monster_id_list"):
			for monster_id in data.get("monster_id_list", []):
				monster_id_list.append(monster_id)
		monster_count = data.get("monster_count", 0)


static func create_monster_skill(monster_config) -> DataMonsterSkill:
	var _type = monster_config["type"]
	if _type == "charge_attack":
		var charge_attack = ChargeAttack.new()
		charge_attack.from_dict(monster_config)
		# 初始化剩余cd
		charge_attack.cd_rest = charge_attack.start_cd
		return charge_attack
	elif _type == "spawn_monster":
		var spawn_monster = SpawnMonster.new()
		spawn_monster.from_dict(monster_config)
		# 初始化剩余cd
		spawn_monster.cd_rest = spawn_monster.start_cd
		return spawn_monster
	
	return null
