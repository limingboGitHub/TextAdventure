class_name DataPlayer extends DataRole

## 该类只包含玩家的数据信息，不涉及到UI层代码

var player_id: String = ""
var player_name: String = "无影"
var job_id: String = "job_000000"
# 职业名称 需要从外部注入
var job_name: String = "新手"
var level: int = 1
var popularity: int = 0

var max_exp: int = 100
var exp: int = 0


# 玩家攻击力的初始波动区间
const MIN_ATTACK_RATE: float = 0.5
const MAX_ATTACK_RATE: float = 1.2

# 玩家最终的攻击力波动范围(需要根据手技属性加成)
var final_min_attack_rate: float = MIN_ATTACK_RATE
var final_max_attack_rate: float = MAX_ATTACK_RATE

# 玩家最终的魔法力波动范围(需要根据手技属性加成)
var final_min_magic_rate: float = MIN_ATTACK_RATE
var final_max_magic_rate: float = MAX_ATTACK_RATE

# 可分配能力值
var allot_point: int = 0

var attack_speed: int = 12500 # 每1000秒攻击多少次

# 玩家所处地图位置、默认 map_000001
var map_id: String = "map_000001"

## 普通攻击技能
var normal_attack: DataAttackSkill
## 玩家默认技能
var skill: DataBaseSkill

# 玩家的执行CD剩余时间
var execute_cd_rest: float = 0

# 玩家的拾取CD
var pick_up_cd = 0.1
var pick_up_cd_rest: float = 0

# 玩家升级经验表
var exp_dic = {}

# 角色无敌状态
var can_not_be_hurt = false
# 无敌剩余时间
var can_not_be_hurt_rest: float = 0
# 无敌总时长
var CAN_NOT_BE_HURT_DURATION = 2

# 能力值来源为“加点分配”
const ATTRIBUTE_ALLOC = "allocate"


# 玩家休息状态
var is_resting = false
# 玩家休息状态时，恢复生命时间间隔n
const RECOVER_HP_INTERVAL = 2
# 玩家休息状态时，每n秒回复10点生命值
var recover_hp_rest = 10
# 玩家休息状态时，每n秒回复10点生命值的剩余时间
var recover_hp_rest_time: float = RECOVER_HP_INTERVAL

# 恢复魔法值时间间隔n
const RECOVER_MP_INTERVAL = 2
# 每n秒回复魔法值
var recover_mp_rest = 5
# 每n秒回复魔法值的剩余时间
var recover_mp_rest_time: float = RECOVER_MP_INTERVAL

# 玩家装备，外部注入
var role_equip: DataRoleEquip

# 玩家的攻击范围增幅 百分比
var attack_range_increase: float = 0

#region “法力涌动”特殊效果
# “法力涌动”特殊效果期间消耗的mp
var mp_cost_enhance: int = 0
# “法力涌动”mp消耗临界值
const MP_COST_ENHANCE_CRITICAL_VALUE = 1000
#endregion

#region “血气爆发”特殊效果
# “血气爆发”消耗的hp
var hp_cost_enhance: int = 0
# “血气爆发”hp消耗临界值
const HP_COST_ENHANCE_CRITICAL_VALUE = 1000
#endregion


signal before_skill_executed(player: DataPlayer, skill: DataBaseSkill)

signal skill_executed(player: DataPlayer, skill: DataBaseSkill,skill_add_count: int)

signal exp_updated(player: DataPlayer, value: int,increase_value: int)

signal level_updated(player: DataPlayer)

signal pick_up_executed(player: DataPlayer)

signal hp_updated(player: DataPlayer)

signal mp_updated(player: DataPlayer)

signal hp_value_changed(player: DataPlayer, change_value: int)

signal mp_value_changed(player: DataPlayer, change_value: int)

signal attribute_updated(player: DataPlayer)

signal hp_recovered(player: DataPlayer, value: int)

signal can_not_be_hurt_changed(player: DataPlayer)

signal job_changed(player: DataPlayer)

signal rest_started(player: DataPlayer)

signal mp_cost_enhance_status_changed(player: DataPlayer,is_match: bool)

signal hp_cost_enhance_status_changed(player: DataPlayer,is_match: bool)

signal damage_caused(player: DataPlayer, damage: DataDamage)

func _init() -> void:
	attribute.ability_dic[ATTRIBUTE_ALLOC] = AttributeAbility.new()
	# 监听属性的变化
	attribute.updated.connect(_on_attribute_updated)


func init_base_ability(power: int, agility: int, intelligence: int, luck: int) -> void:
	var ability = AttributeAbility.new()
	ability.power = power
	ability.agility = agility
	ability.intelligence = intelligence
	ability.luck = luck
	
	attribute.ability_dic[Attribute.ATTRIBUTE_BASE] = ability


func init_base_details() -> void:
	var details = AttributeDetails.new()
	details.max_hp = 100
	details.max_mp = 50
	details.attack = 10
	details.magic = 10
	details.accuracy = 0
	details.move_speed = 50

	attribute.details[Attribute.ATTRIBUTE_BASE] = details


func init_role_equip(_role_equip: DataRoleEquip) -> void:
	self.role_equip = _role_equip


func init_exp_dic(_exp_dic: Dictionary) -> void:
	self.exp_dic = _exp_dic

	if not _exp_dic.has(str(level + 1)):
		# 当前等级是最高等级
		max_exp = -1
	else:
		max_exp = _exp_dic[str(level)]


func _on_attribute_updated(_attribute: Attribute):
	_on_update_attribute()


func update_attribute() -> void:
	attribute.update()


func _on_update_attribute() -> void:
	# 根据手技属性加成，计算最终的攻击力波动范围
	var sub = MAX_ATTACK_RATE - MIN_ATTACK_RATE
	final_min_attack_rate = MIN_ATTACK_RATE + attribute.final_details.attack_min_rate + \
							sub * attribute.final_details.hand_technology / 50
	final_max_attack_rate = MAX_ATTACK_RATE + attribute.final_details.attack_max_rate
	# 根据手技属性加成，计算最终的魔法力波动范围
	final_min_magic_rate = MIN_ATTACK_RATE + attribute.final_details.magic_min_rate + \
							sub * attribute.final_details.hand_technology / 50
	final_max_magic_rate = MAX_ATTACK_RATE + attribute.final_details.magic_max_rate
	# 特殊效果增幅
	if has_effect("effect_000024"):
		var effect = get_effect("effect_000024")
		if effect.value_type == Constants.VALUE_TYPE_PERCENT:
			var luck_add_rate = effect.value * attribute.all_ability.luck
			final_max_attack_rate += luck_add_rate
			final_max_magic_rate += luck_add_rate
			#print("【运气至上】攻击力增幅：",luck_add_rate)
		else:
			## 不支持
			pass

	# 计算攻击范围增幅
	attack_range_increase = _get_attack_range_increase()

	attribute_updated.emit(self)
	_hp_update()
	_mp_update()


func _get_attack_range_increase() -> float:
	var _attack_range_increase = 0
	if has_effect("effect_000007"):
		var effect = get_effect("effect_000007")
		# 每100点最大生命值，增加1点半径
		_attack_range_increase = effect.value * attribute.final_details.max_hp / 10000.0
		print("【泰坦之魂】攻击距离增幅：",_attack_range_increase)
	return _attack_range_increase


## 增加经验值
##
## 击杀怪物时享受经验加成，任务奖励时不享受经验加成
## @param value 经验值
## @param enable_exp_gain 是否启用经验加成，如果为false，则只增加基础经验值
func add_exp(value: int,enable_exp_gain: bool = true):
	# 基础经验值（会受到全局经验加成）
	var base_value = int(value * SingletonGame.exp_multiplier)
	# 增加经验值的特殊效果
	var effect_exp_value = 0
	if enable_exp_gain:
		effect_exp_value = base_value * attribute.final_details.exp_gain
	# 最终经验值提升
	exp += base_value + effect_exp_value
	exp_updated.emit(self, base_value,effect_exp_value)
	# 升级
	while not is_max_level() and exp >= max_exp:
		_level_up()


func is_max_level() -> bool:
	return not exp_dic.has(str(level + 1))


func _level_up() -> int:
	exp = exp - max_exp
	level += 1
	max_exp = exp_dic[str(level)]
	allot_point += 5
	# 基础血量和魔法值增加
	var base_details = attribute.get_details(Attribute.ATTRIBUTE_BASE)
	base_details.max_hp += 10
	base_details.max_mp += 10
	if job_id == "job_000001":
		base_details.max_hp += 10
	if job_id == "job_000101":
		base_details.max_mp += 10

	attribute.add_details(Attribute.ATTRIBUTE_BASE, base_details)
	# 生命和魔法值回满
	hp = attribute.final_details.max_hp
	mp = attribute.final_details.max_mp
	_hp_update()
	_mp_update()
	# 判断是否满级
	if is_max_level():
		max_exp = -1
		
	level_updated.emit(self)
	return level


## 分配能力值
## type 0 hp 1 mp 2 力量 3 敏捷 4 智力 5 运气
func alloc_ability(type: int,count: int):
	if allot_point < count:
		return
	allot_point -= count
	if type == 0:
		attribute.ability_dic[ATTRIBUTE_ALLOC].hp += count
	elif type == 1:
		attribute.ability_dic[ATTRIBUTE_ALLOC].mp += count
	elif type == 2:
		attribute.ability_dic[ATTRIBUTE_ALLOC].power += count
	elif type == 3:
		attribute.ability_dic[ATTRIBUTE_ALLOC].agility += count
	elif type == 4:
		attribute.ability_dic[ATTRIBUTE_ALLOC].intelligence += count
	elif type == 5:
		attribute.ability_dic[ATTRIBUTE_ALLOC].luck += count
	attribute.update()


func reset_ability_alloc() -> void:
	allot_point += attribute.ability_dic[ATTRIBUTE_ALLOC].hp
	allot_point += attribute.ability_dic[ATTRIBUTE_ALLOC].mp
	allot_point += attribute.ability_dic[ATTRIBUTE_ALLOC].power
	allot_point += attribute.ability_dic[ATTRIBUTE_ALLOC].agility
	allot_point += attribute.ability_dic[ATTRIBUTE_ALLOC].intelligence
	allot_point += attribute.ability_dic[ATTRIBUTE_ALLOC].luck
	attribute.ability_dic[ATTRIBUTE_ALLOC].hp = 0
	attribute.ability_dic[ATTRIBUTE_ALLOC].mp = 0
	attribute.ability_dic[ATTRIBUTE_ALLOC].power = 0
	attribute.ability_dic[ATTRIBUTE_ALLOC].agility = 0
	attribute.ability_dic[ATTRIBUTE_ALLOC].intelligence = 0
	attribute.ability_dic[ATTRIBUTE_ALLOC].luck = 0
	attribute.update()


func process(delta: float):
	if execute_cd_rest > 0:
		execute_cd_rest -= delta

	if pick_up_cd_rest > 0:
		pick_up_cd_rest -= delta

	if can_not_be_hurt:
		can_not_be_hurt_rest -= delta
		if can_not_be_hurt_rest <= 0:
			can_not_be_hurt = false
			can_not_be_hurt_rest = 0

	# 玩家生命恢复
	# 残血状态
	if hp < attribute.final_details.max_hp:
		# 休息状态
		if is_resting:
			_process_recover_hp(delta, recover_hp_rest + attribute.final_details.recover_hp)
		elif attribute.final_details.recover_hp > 0:
			_process_recover_hp(delta, attribute.final_details.recover_hp)

	# 法力恢复
	if mp < attribute.final_details.max_mp:
		# 休息状态
		if is_resting:
			_process_recover_mp(delta, recover_mp_rest + attribute.final_details.recover_mp)
		elif attribute.final_details.recover_mp > 0:
			_process_recover_mp(delta, attribute.final_details.recover_mp)

	super.process(delta)


func _process_recover_hp(delta: float,recover_hp_value: int):
	if is_dead:
		return

	recover_hp_rest_time -= delta
	if recover_hp_rest_time <= 0:
		recover_hp(recover_hp_value)
		recover_hp_rest_time = RECOVER_HP_INTERVAL / float(SingletonGame.speed)
		# 发出恢复生命值事件，展示恢复生命值的动画
		hp_recovered.emit(self, recover_hp_value)


func reset_execute_cd():
	execute_cd_rest = 0


func _process_recover_mp(delta: float,recover_mp_value: int):
	if is_dead:
		return

	recover_mp_rest_time -= delta
	if recover_mp_rest_time <= 0:
		recover_mp(recover_mp_value)
		recover_mp_rest_time = RECOVER_MP_INTERVAL / float(SingletonGame.speed)


func process_attack():
	if is_dead:
		return
	# 判断普攻的是否还有冷却
	if execute_cd_rest > 0:
		# print("攻击还在冷却")
		return
	else:
		if skill:
			before_skill_executed.emit(self, skill)
			# 获取技能蓝耗
			var mp_cost = skill.get_mp_cost()
			# 判断是否有技能增强影响蓝耗
			var skill_add_count = 0
			if has_skill_enhance(skill.id):
				var skill_enhance = get_skill_enhance(skill.id)
				if skill_enhance.add_probability > 0:
					# 随机概率
					if randf() <= skill_enhance.add_probability:
						# 追加释放次数
						skill_add_count = skill_enhance.add_count
						# 蓝耗增加
						mp_cost += skill_enhance.mp_cost
						#print("技能追加判定：",skill.name,skill_enhance.add_probability)

			# 判断是否存在特效影响蓝耗
			var hp_cost_replace_mp = 0
			if has_effect("effect_000016"):
				var effect = get_effect("effect_000016")
				if effect.value_type == Constants.VALUE_TYPE_PERCENT:
					hp_cost_replace_mp = int(mp_cost * effect.value)
					mp_cost -= hp_cost_replace_mp
				else:
					hp_cost_replace_mp = effect.value
					mp_cost -= hp_cost_replace_mp
				#print("【血偿】蓝耗：",mp_cost,"血量：",hp_cost_replace_mp)

			if mp < mp_cost:
				# 蓝耗不足时释放普攻
				execute_skill(normal_attack,skill_add_count)
				# 重置冷却
				execute_cd_rest = normal_attack.cd / float(SingletonGame.speed)
			else:
				# 扣除蓝耗
				recover_mp(-mp_cost)
				# 扣除血量
				if hp_cost_replace_mp > 0:
					_reduce_hp(hp_cost_replace_mp)
					# 角色死亡判定
					_judge_dead()
					# 通知血量变化
					_hp_update()
				
				execute_skill(skill,skill_add_count)
				# 重置冷却
				if has_skill_enhance(skill.id):
					execute_cd_rest = (skill.cd + get_skill_enhance(skill.id).cd) / float(SingletonGame.speed)
				else:
					execute_cd_rest = skill.cd / float(SingletonGame.speed)
				print("技能释放后，冷却时间：",execute_cd_rest)
			# 退出休息状态
			is_resting = false


func execute_skill(_skill: DataBaseSkill,skill_add_count: int = 0):
	skill_executed.emit(self, _skill,skill_add_count)


func execute_normal_attack():
	execute_skill(normal_attack)


func process_pick():
	if pick_up_cd_rest > 0:
		return
	else:
		pick_up_executed.emit(self)
		pick_up_cd_rest = pick_up_cd / float(SingletonGame.speed)


## 恢复生命值，并发出信号
func recover_hp_with_signal(value: int):
	recover_hp(value)
	hp_recovered.emit(self, value)


func recover_hp(value: int):
	if value == 0:
		return

	hp += value
	if hp > attribute.final_details.max_hp:
		hp = attribute.final_details.max_hp
	_hp_update()

	#【特殊效果】血量恢复时，恢复法力
	if has_effect(DataEffect.RecoverMpWhenHpRecover):
		var effect = get_effect(DataEffect.RecoverMpWhenHpRecover)
		if effect.value_type == Constants.VALUE_TYPE_PERCENT:
			var recover_mp_value = min(int(value * effect.value), 1)
			print("【特殊效果】血量恢复时，恢复法力：", recover_mp_value)
			recover_mp(recover_mp_value)
		else:
			recover_mp(effect.value)


## 按照百分比恢复生命值
func recover_hp_rate(rate: float):
	hp += int(attribute.final_details.max_hp * rate)
	if hp > attribute.final_details.max_hp:
		hp = attribute.final_details.max_hp
	_hp_update()


## 恢复魔法值(value为负数时，表示减少魔法值)
func recover_mp(value: int):
	if value == 0:
		return

	mp += value
	mp_value_changed.emit(self,value)
	if mp > attribute.final_details.max_mp:
		mp = attribute.final_details.max_mp
	# “法力涌动”期间消耗的mp
	if value < 0 and has_mp_cost_enhance() and mp_cost_enhance < MP_COST_ENHANCE_CRITICAL_VALUE:
		mp_cost_enhance += abs(value)
		if mp_cost_enhance >= MP_COST_ENHANCE_CRITICAL_VALUE:
			mp_cost_enhance_status_changed.emit(self,true)
	_mp_update()


## 按照百分比恢复魔法值
func recover_mp_rate(rate: float):
	mp += int(attribute.final_details.max_mp * rate)
	if mp > attribute.final_details.max_mp:
		mp = attribute.final_details.max_mp
	_mp_update()


func get_hurt(data_damage: DataDamage):
	# 魔法屏障技能判定
	if has_effect("effect_000001"):
		var effect = get_effect("effect_000001")
		var effect_value: int = effect.value
		if effect.value_type == Constants.VALUE_TYPE_PERCENT:
			effect_value = int(data_damage.value * effect.value)
		# 效果值最小为1
		effect_value = max(1,effect_value)
		# 计算可以转换的MP量（不能超过玩家当前MP）
		var can_convert_mp = min(effect_value, mp)
		# 计算剩余伤害
		var rest_damage = data_damage.value - can_convert_mp
		if rest_damage > 0:
			_reduce_hp(rest_damage)
			if can_convert_mp > 0:
				recover_mp(-can_convert_mp)
		else:
			recover_mp(-data_damage.value)
	else:
		# 减少hp
		_reduce_hp(data_damage.value)
	# 发送角色受伤信号
	role_hurted.emit(self,data_damage)

	# 角色死亡判定
	_judge_dead()
	# 如果目标处在休息状态受伤，则退出休息状态
	if is_resting:
		stop_rest()
	# 通知血量变化（注意相关信号的生命周期，血量变化在受伤事件之后）
	_hp_update()


## 直接扣除血量，不触发受伤事件
func _reduce_hp(value: int):
	if value == 0:
		return
	hp -= value
	hp = max(hp,0)
	hp_value_changed.emit(self,-value)

	if has_hp_cost_enhance() and hp_cost_enhance < HP_COST_ENHANCE_CRITICAL_VALUE:
		hp_cost_enhance += value
		if hp_cost_enhance >= HP_COST_ENHANCE_CRITICAL_VALUE:
			hp_cost_enhance_status_changed.emit(self,true)


func _judge_dead():
	if hp <= 0:
		hp = 0
		kill_role()


func _hp_update():
	if hp > attribute.final_details.max_hp:
		hp = attribute.final_details.max_hp
	# 如果HPMP都恢复满了，则停止休息
	if hp >= attribute.final_details.max_hp and mp >= attribute.final_details.max_mp:
		stop_rest()
	hp_updated.emit(self)


func _mp_update():
	if mp > attribute.final_details.max_mp:
		mp = attribute.final_details.max_mp
	# 如果HPMP都恢复满了，则停止休息
	if hp >= attribute.final_details.max_hp and mp >= attribute.final_details.max_mp:
		stop_rest()
	mp_updated.emit(self)


## 玩家复活
func revive():
	hp = 50
	is_dead = false
	_hp_update()


## 经验惩罚，扣减最大经验值的5%
func punish_exp():
	var value = -int(max_exp * 0.05)
	exp += value
	if exp < 0:
		exp = 0
	exp_updated.emit(self,value,0)


func rest():
	is_resting = true
	# 重置恢复生命值的剩余时间
	recover_hp_rest_time = RECOVER_HP_INTERVAL / float(SingletonGame.speed)
	# 重置恢复魔法值的剩余时间
	recover_mp_rest_time = RECOVER_MP_INTERVAL / float(SingletonGame.speed)
	rest_started.emit(self)


func stop_rest():
	is_resting = false


func change_job(_job_id: String,_job_name: String):
	job_id = _job_id	
	job_name = _job_name
	job_changed.emit(self)


func get_final_min_attack() -> int:
	return int(attribute.final_details.attack * final_min_attack_rate)


func get_final_max_attack() -> int:
	return int(attribute.final_details.attack * final_max_attack_rate)


func get_final_min_magic() -> int:
	return int(attribute.final_details.magic * final_min_magic_rate)

func get_final_max_magic() -> int:
	return int(attribute.final_details.magic * final_max_magic_rate)


# 获取最终的攻击力，根据攻击力波动范围计算
# @param rate 波动范围的比率，0-1之间
func get_final_attack(rate: float) -> int:
	var attack_rate = (final_max_attack_rate - final_min_attack_rate) * rate + final_min_attack_rate
	return int(attribute.final_details.attack * attack_rate)


# 获取最终的魔法攻击力，根据魔法攻击力波动范围计算
# @param rate 波动范围的比率，0-1之间
func get_final_magic_attack(rate: float) -> int:
	var magic_attack_rate = (final_max_attack_rate - final_min_attack_rate) * rate + final_min_attack_rate
	return int(attribute.final_details.magic * magic_attack_rate)


# 获取波动范围比率在初始范围区间内的比率
# 用于展示该伤害比率最终的视觉效果，例如初始波动范围是0.5-1.2，最终波动范围是1.0-1.2，那么1.1的比率最终的视觉效果是0.87而不是0.5
# @param rate 波动范围的比率，0-1之间
func get_show_rate(rate: float) -> float:
	var attack_rate = (final_max_attack_rate - final_min_attack_rate) * rate + final_min_attack_rate
	return (attack_rate - MIN_ATTACK_RATE) / (MAX_ATTACK_RATE - MIN_ATTACK_RATE)


func get_final_details() -> AttributeDetails:
	return attribute.final_details


# 判断是否达到了“法力涌动”临界值
func is_match_mp_cost_enhance()-> bool:
	return has_mp_cost_enhance() and mp_cost_enhance >= MP_COST_ENHANCE_CRITICAL_VALUE


# 重置“法力涌动”累计值
func reset_mp_cost_enhance():
	mp_cost_enhance = 0
	mp_cost_enhance_status_changed.emit(self,false)


# 判断是否存在“法力涌动”特殊效果
func has_mp_cost_enhance()-> bool:
	return has_effect("effect_000015")


# 获取“法力涌动”特殊效果
func get_mp_cost_enhance()-> DataEffect:
	return get_effect("effect_000015")


# 判断是否达到了“血气爆发”临界值
func is_match_hp_cost_enhance()-> bool:
	return has_hp_cost_enhance() and hp_cost_enhance >= HP_COST_ENHANCE_CRITICAL_VALUE


# 重置“血气爆发”累计值
func reset_hp_cost_enhance():
	hp_cost_enhance = 0
	hp_cost_enhance_status_changed.emit(self,false)


# 判断是否存在“血气爆发”特殊效果
func has_hp_cost_enhance()-> bool:
	return has_effect("effect_000017")


# 获取“血气爆发”特殊效果
func get_hp_cost_enhance()-> DataEffect:
	return get_effect("effect_000017")


# 玩家对其他对象造成了伤害，发出信号
func cause_damage(damage: DataDamage):
	damage_caused.emit(self,damage)


func save() -> Dictionary:
	var json = {
		"player_id": player_id,
		"player_name": player_name,
		"job_id": job_id,
		"job_name": job_name,
		"level": level,

		"hp": hp,
		"mp": mp,
		"max_exp": max_exp,
		"exp": exp,

		"attribute": attribute.save(),
		"allot_point": allot_point,
		"attack_speed": attack_speed,
		
		"map_id": map_id,
	}
	if skill:
		json["skill"] = skill.save()
	return json


func load(dic: Dictionary):
	player_id = dic["player_id"]
	player_name = dic["player_name"]
	job_id = dic["job_id"]
	job_name = dic["job_name"]
	level = dic["level"]
	hp = dic["hp"]
	mp = dic["mp"]
	max_exp = dic["max_exp"]
	exp = dic["exp"]
	attribute.load(dic["attribute"])
	allot_point = dic["allot_point"]
	attack_speed = dic["attack_speed"]
	map_id = dic["map_id"]
	
	# 这里只是还原了技能的id信息，需要外层进一步根据id还原技能详情
	if dic.has("skill"):
		skill = DataBaseSkill.new(dic["skill"]["id"], dic["skill"]["type"])
