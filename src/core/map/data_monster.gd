class_name DataMonster extends DataRole

# 怪物的创建id
var monster_id: String
# 怪物的唯一标识，两只一样的怪物有不同的唯一标识
var monster_unique_id: String
# 怪物名称
var name: String
# 怪物类型：normal、boss
var type: String = "normal"
# 怪物是否为精英
var is_elite = false
# 怪物是否受伤
var is_hurted = false

var level: int
var exp: int

var current_map_id: String = ""

# 怪物默认技能（普攻也是技能）
var skill: DataBaseSkill = DataSkillBag.create_normal_attack()

# 执行CD
var execute_cd = 2000
var execute_cd_rest = 0

# 怪物被攻击的来源(玩家id)
var attack_sources: Array[String] = []

signal skill_executed(data_monster: DataMonster, skill: DataBaseSkill)


func set_attribute(base_attr: AttributeDetails):
	# 怪物的基础属性直接就是最终属性
	attribute.final_details = base_attr
	hp = attribute.final_details.max_hp
	mp = attribute.final_details.max_mp


func _to_string() -> String:
	return monster_unique_id


func process(delta: float):
	if execute_cd_rest > 0:
		execute_cd_rest -= int(delta * 1000)

	super.process(delta)


func upgrade(rate: float):
	var details = attribute.final_details
	details.max_hp *= rate
	details.attack *= rate
	details.defense *= rate
	details.accuracy *= rate
	details.evasion *= rate
	hp = attribute.final_details.max_hp


## 怪物的攻击没有冷却时间，只要玩家未处在无敌状态，就会一直攻击
func process_attack():
	if execute_cd_rest > 0:	
		return
	
	if is_dead:
		return

	# 在攻击生效之前，上层逻辑可能还会有一些判定
	if skill is DataAttackSkill:
		# 技能执行
		print("怪物技能执行：", skill.name)
		skill_executed.emit(self, skill)
		# 重置冷却
		execute_cd_rest = execute_cd / float(SingletonGame.speed)


func add_attack_source(id: String):
	if not attack_sources.has(id):
		attack_sources.append(id)


func is_attacked_by(id: String) -> bool:
	return attack_sources.has(id)


func is_boss() -> bool:
	return type == "boss"


func get_hurt(data_damage: DataDamage):
	super.get_hurt(data_damage)
	if not is_hurted:
		is_hurted = true
