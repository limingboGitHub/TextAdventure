class_name DataEffect

const Combo = "combo"
const Counter = "counter"
const Recover = "recover"
const ManaDefense = "mana_defense"
const FirstAttackEnhance = "first_attack_enhance"
const MaxHpAttachDamage = "max_hp_attach_damage"
# 每损失100点血量，增加n点伤害
const LostHpAttachDamage = "lost_hp_attach_damage"
# 防御反伤
const DefenseCounterDamage = "defense_counter_damage"
# 吸引怪物
const DragMonster = "drag_monster"
# 怪物击杀增加血量
const MonsterKillAddHp = "monster_kill_add_hp"
# 每次攻击损失5点血量，增加5点伤害
const AttackLostHpAttachDamage = "attack_lost_hp_attach_damage"
# 攻击时有几率附带爆炸伤害
const AttackExplodeDamage = "attack_explode_damage"
# 血量恢复时，恢复法力
const RecoverMpWhenHpRecover = "recover_mp_when_hp_recover"
# 血量越多，体型和攻击范围越大
const HpAttachScopeIncrease = "hp_attach_scope_increase"
# 法力涌动
const MpCostEnhanceSkill = "mp_cost_enhance_skill"
# 技能增强
const SkillEnhance = "skill_enhance"

var id: String
var type: String
var value: float
# 描述
var desc: String = ""
# 范围 -1 表示无限大
var radius: float = -1
# 触发时间间隔
var invoke_interval: float = 0
# 上一次触发时间
var last_invoke_time: float = 0

var value_type: String = Constants.VALUE_TYPE_PERCENT

var is_active: bool = true

# 特殊效果附带的技能
var special_skill: DataBaseSkill = null

# 技能增强效果
var skill_enhance: DataSkillEnhance = null

func _init(_id: String,_type: String) -> void:
	self.type = _type
	self.id = _id


func set_active(active: bool) -> void:
	is_active = active
	#print("设置effect状态", type, is_active)


func get_special_skill() -> DataBaseSkill:
	if special_skill == null and id == "effect_000005":
		var skill = DataAttackSkill.new(type,"attack")
		skill.radius = 70
		skill.count = 99999
		skill.target_type = 1
		skill.level = 1
		skill.name = "赤焰"
		skill.damage_source_type = 2
		skill.damage_type = 1
		skill.is_effect_after_skill_executed = false
		skill.damage_value_type = value_type
		skill.damage_level = [[value]]
		special_skill = skill
	return special_skill


func append(data_effect: DataEffect) -> void:
	value += data_effect.value

	# 存在特效技能，则用追加后的值替换特效技能的值
	if special_skill != null:
		special_skill.damage_level = [[value]]
	
	# 存在技能增强效果，则用追加后的值替换技能增强效果的值
	if skill_enhance != null:
		skill_enhance.append(data_effect.skill_enhance)


func remove(data_effect: DataEffect) -> void:
	value -= data_effect.value

	# 存在特效技能，则用减少后的值替换特效技能的值
	if special_skill != null:
		special_skill.damage_level = [[value]]

	# 存在技能增强效果，则用减少后的值替换技能增强效果的值
	if skill_enhance != null:
		skill_enhance.remove(data_effect.skill_enhance)


func save() -> Dictionary:
	var data = {
		"id": id,
		"type": type,
		"value": value,
		"desc": desc,
		"value_type": value_type,
	}
	if skill_enhance != null:
		data["skill_enhance"] = skill_enhance.save()
	return data


func load(data: Dictionary) -> void:
	if data.has("value"):
		value = data["value"]
	if data.has("desc"):
		desc = data["desc"]
	if data.has("value_type"):
		value_type = data["value_type"]
	if data.has("skill_enhance"):
		skill_enhance = DataSkillEnhance.new()
		skill_enhance.load(data["skill_enhance"])


func copy() -> DataEffect:
	var data_effect = DataEffect.new(id,type)
	data_effect.value = value
	data_effect.desc = desc
	data_effect.radius = radius
	data_effect.invoke_interval = invoke_interval
	data_effect.last_invoke_time = last_invoke_time
	data_effect.value_type = value_type
	data_effect.is_active = is_active
	data_effect.special_skill = special_skill
	data_effect.skill_enhance = skill_enhance
	return data_effect
