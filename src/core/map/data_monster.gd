class_name DataMonster extends DataRole

# 引用充能组件
const DataChargeComponentClass = preload("res://src/core/data_charge_component.gd")

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
var execute_cd = 2.0
var execute_cd_rest = 0.0

# 怪物被攻击的来源(玩家id)
var attack_sources: Array[String] = []

# 怪物特殊技能列表
var monster_skills: Array[DataMonsterSkill] = []
# 怪物当前执行的特殊技能
var monster_skill_current: DataMonsterSkill

# 自动锁定玩家
var auto_lock_player = false
# 此怪物是否会掉落物品（部分特殊怪物不掉落物品）
var is_drop_item = true
# 此怪物是否会无视玩家休息状态
var is_ignore_rest = false

# 怪物特殊效果（配置信息）,怪物创建时注入该信息
var effect_config: Dictionary = {}

# 越战越勇特殊效果触发时间
var time_add_damage_rest_time = 1.0
# 越战越勇累计效果
var time_add_damage_rest_value = 0
# 护甲撕裂效果
var armor_break_value = 0

# 怪物重置状态
var reset_status = false

signal skill_executed(data_monster: DataMonster, skill: DataBaseSkill)
signal charge_started
signal charge_completed(complete_charge_time: float)  # 0表示失败，大于0表示成功
signal monster_reseted(data_monster: DataMonster)

# 蓄力相关
var charge_component = DataChargeComponent.new()


func _init() -> void:
	# 初始化充能组件
	charge_component.charge_started.connect(_on_charge_started)
	charge_component.charge_completed.connect(_on_charge_completed)

	attribute.updated.connect(_on_attribute_updated)


func _on_attribute_updated(_attribute: Attribute):
	attribute.final_details = _attribute.get_details(Attribute.ATTRIBUTE_BASE).copy()
	attribute.final_details.attack += time_add_damage_rest_value
	attribute.final_details.defense -= armor_break_value
	attribute.final_details.magic_def -= armor_break_value


func set_attribute(base_attr: AttributeDetails):
	attribute.add_details(Attribute.ATTRIBUTE_BASE,base_attr)
	# 怪物的基础属性直接就是最终属性
	attribute.final_details = base_attr.copy()
	hp = attribute.final_details.max_hp
	mp = attribute.final_details.max_mp


func add_armor_break_value(value: int):
	armor_break_value += value
	attribute.final_details.defense -= armor_break_value
	attribute.final_details.magic_def -= armor_break_value


func _to_string() -> String:
	return monster_unique_id


func process(delta: float):
	if execute_cd_rest > 0:
		execute_cd_rest -= delta
	
	# 处理蓄力
	charge_component.process(delta)

	# 处理怪物特殊技能剩余CD（受伤后开始计算特殊技能CD）
	if is_hurted:
		for monster_skill in monster_skills:
			# -1表示永久技能，永久技能不计算CD
			if monster_skill.cd_rest == -1:
				continue
			if monster_skill.cd_rest > 0:
				monster_skill.cd_rest -= delta

	# 处理“越战越勇”特殊效果
	if has_effect("effect_000029"):
		if time_add_damage_rest_time > 0:
			time_add_damage_rest_time -= delta
		else:
			time_add_damage_rest_time = 1.0
			time_add_damage_rest_value += get_effect("effect_000029").value
			attribute.final_details.attack += time_add_damage_rest_value
			#print("越战越勇：", time_add_damage_rest_value)

	super.process(delta)


func upgrade(rate: float):
	var details = attribute.final_details
	details.max_hp *= rate
	details.attack *= rate
	details.defense *= rate
	#details.accuracy *= rate
	#details.evasion *= rate
	hp = attribute.final_details.max_hp
	is_ignore_rest = true


## 怪物的攻击没有冷却时间，只要玩家未处在无敌状态，就会一直攻击
func process_attack():
	# 如果正在蓄力，则不执行攻击
	if charge_component.get_charging_status():
		return

	if execute_cd_rest > 0:	
		return
	
	if is_dead:
		return
	
	# 优先尝试使用怪物特殊技能
	for monster_skill in monster_skills:
		
		if monster_skill.cd_rest == -1:
			# 永久技能
			continue
		elif monster_skill.cd_rest > 0:
			# 技能CD中
			continue
		else:
			# 技能CD结束
			# 处理怪物特殊技能
			process_monster_skill(monster_skill)
			return

	# 如果没有执行特殊技能，则执行普通攻击
	if skill is DataAttackSkill:
		# 技能执行
		execute_skill(skill)


func process_monster_skill(monster_skill: DataMonsterSkill):
	if monster_skill.type == "charge_attack":
		# 随机一个蓄力时长
		var charge_time = monster_skill.charge_time_min + \
			randf() * (monster_skill.charge_time_max - monster_skill.charge_time_min)
		# 进入蓄力状态
		charge_component.start_charge(charge_time)
		# 标记当前执行的怪物技能
		monster_skill_current = monster_skill
	elif monster_skill.type == "spawn_monster":
		# 召唤技能
		var _skill = DataSpawnSkill.new(monster_skill.id,"spawn")
		_skill.monster_id_list = monster_skill.monster_id_list
		_skill.monster_count = monster_skill.monster_count
		execute_skill(_skill)
		# 重置怪物特殊技能CD
		monster_skill.cd_rest = monster_skill.cd
	elif monster_skill.type == "buff_skill":
		# 特殊效果
		var effect_id = monster_skill.effect_id
		var effect_type = effect_config[effect_id]["effect_type"]
		var effect = DataEffect.new(effect_id,effect_type)
		effect.load(effect_config[effect_id])
		# buff技能
		var buff_skill: DataEffectBuffSkill
		if effect.type == "attack_attach_dizziness":
			buff_skill = DataSkillBag.create_buff_skill(
				monster_skill.id,
				monster_skill.name,
				effect.value)
			# 附加眩晕buff
			var dizziness_effect_id = "effect_000032"
			var dizziness_effect_name = effect_config[dizziness_effect_id]["name"]
			var dizziness_effect_type = effect_config[dizziness_effect_id]["effect_type"]
			var dizziness_effect = DataEffect.new(dizziness_effect_id,dizziness_effect_type)
			dizziness_effect.load(effect_config[dizziness_effect_id])
			buff_skill.effect_list.append(dizziness_effect)
			# buff名称调整为附加状态的名称，例如“眩晕”
			buff_skill.name = dizziness_effect_name
			# 附加对象为玩家
			buff_skill.target_type = 0
		else:
			buff_skill = DataSkillBag.create_buff_skill(
				monster_skill.id,
				monster_skill.name,
				monster_skill.buff_time)
			# 附加对象为怪物
			buff_skill.target_type = 1
			buff_skill.effect_list.append(effect)
		execute_skill(buff_skill)
		# 重置怪物特殊技能CD
		monster_skill.cd_rest = monster_skill.cd
		print("怪物特殊技能执行：", monster_skill.name)


func execute_skill(_skill: DataBaseSkill):
	print("怪物技能执行：", _skill.name)
	skill_executed.emit(self, _skill)
	# 重置冷却
	execute_cd_rest = execute_cd / float(SingletonGame.speed)


func add_monster_skill(monster_skill: DataMonsterSkill):
	monster_skills.append(monster_skill)


func add_attack_source(id: String):
	if not attack_sources.has(id):
		attack_sources.append(id)


func is_attacked_by(id: String) -> bool:
	return attack_sources.has(id)


func is_boss() -> bool:
	return type == "boss"


## 开始蓄力
func start_charge(time: float):
	charge_component.start_charge(time)


## 取消蓄力
func cancel_charge():
	charge_component.cancel_charge()


## 获取蓄力状态
func get_charging_status() -> bool:
	return charge_component.get_charging_status()


## 获取蓄力进度 (0.0 - 1.0)
func get_charge_progress() -> float:
	return charge_component.get_charge_progress()


func get_hurt(data_damage: DataDamage):
	super.get_hurt(data_damage)
	if not is_hurted:
		is_hurted = true


func _on_charge_completed(time: float):
	charge_completed.emit(time)
	if monster_skill_current != null and monster_skill_current is DataMonsterSkill.ChargeAttack:
		# 结算伤害比例
		var charge_num = time / monster_skill_current.charge_damage_step
		var damage_rate = 1 + charge_num * monster_skill_current.charge_damage_step_value
		# 执行技能
		var _skill = DataSkillBag.create_monster_attack(monster_skill_current.name,damage_rate)
		execute_skill(_skill)
		# 充值怪物特殊技能CD
		monster_skill_current.cd_rest = monster_skill_current.cd


func _on_charge_started():
	charge_started.emit()


## 怪物状态重置
func reset():
	# 重置技能剩余CD
	for monster_skill in monster_skills:
		monster_skill.cd_rest = monster_skill.start_cd
	# 清除所有buff
	for buff_id in buff_dic.keys():
		remove_buff(buff_id)
	# 清除所有特效
	for effect in effect_dic.values():
		remove_effect(effect)
	# 重置属性
	attribute.final_details = attribute.get_details(Attribute.ATTRIBUTE_BASE).copy()
	hp = attribute.final_details.max_hp
	mp = attribute.final_details.max_mp
	is_hurted = false
	# 重置“越战越勇”特殊效果
	time_add_damage_rest_time = 1.0
	time_add_damage_rest_value = 0
	# 重置信号
	monster_reseted.emit(self)
	
	
