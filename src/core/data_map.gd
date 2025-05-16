class_name DataMap

## 承载地形、传送点、玩家、怪物、npc、掉落物等对象的容器

# 基本信息
var id: String
var name: String
# 地区id（同时也是地区名称）
var region_id: String
# 是否为主城
var main_town: bool = false
# 地图位置，归一化坐标（0-1）
var position: Vector2

#region 怪物刷新
# 当前地图怪物刷新点
var map_monster_refresh_pos: Array[MonsterRefreshPos] = []
# 怪物刷新信息 key:monster_id value:config
var monster_config_dic = {}
# 怪物刷新时间信息 key:monster_id value:刷新间隔开始时间
var monster_refresh_time_dic = {}
#endregion

# 数据
var data_player: DataPlayer
var data_npcs = {}
var data_monsters = {}
var data_drop_things = {}
var data_portals = {}
var data_floors = {}

var monster_manager = MonsterManager.new()
var drop_thing_manager: DropThingManager


## 已经击杀当前地图的怪物个数,key:怪物id value:击杀数量，用于解锁某些传送点限制
var kill_monster_count_dic = {}

# 是否进入过地图进行过探索
var is_explored: bool = false

#region 无尽之塔相关属性
var is_endless: bool = false
# 层数
var endless_layer: int = 0
# 层数max
const ENDLESS_LAYER_MAX: int = 9
# 怪物强化倍数
var monster_upgrade: float = 0
# 怪物数量
var monster_count: int = 0
#endregion

## 首个玩家进入
signal first_player_entered

signal monster_added(data_monster: DataMonster,position: Vector2)

signal drop_thing_dropped(drop_thing: DataBagItem, target: DataRole, offset_index: int)

signal drop_thing_picked(data_map: DataMap, drop_thing: DataBagItem)

signal npc_added(data_npc: DataNPC)

signal player_killed_monster(data_player: DataPlayer, target: DataMonster)

signal player_added(data_map: DataMap, data_player: DataPlayer)

signal player_removed(data_map: DataMap, data_player: DataPlayer)

signal map_explored(data_map: DataMap)

signal endless_ended(data_map: DataMap)

signal boss_first_hurted(data_map: DataMap, data_monster: DataMonster)

signal boss_killed(data_map: DataMap, data_monster: DataMonster)
## 对外接口：玩家加入地图
func add_player(_data_player: DataPlayer):
	data_player = _data_player

	first_player_entered.emit()
	data_player.map_id = id
	# 设置地图探索状态
	if not is_explored:
		is_explored = true
		map_explored.emit(self)
	# 玩家停止休息
	data_player.stop_rest()
	# 监听玩家拾取
	data_player.pick_up_executed.connect(_on_player_pick_execute)
	# 监听玩家受伤
	data_player.role_hurted.connect(_on_player_hurted)
	# 发出玩家加入地图信号
	player_added.emit(self, data_player)


func remove_player(_player_id: String):
	# 取消玩家监听
	data_player.pick_up_executed.disconnect(_on_player_pick_execute)
	# 取消玩家受伤监听
	data_player.role_hurted.disconnect(_on_player_hurted)
	# 发出玩家离开地图信号
	player_removed.emit(self, data_player)
	data_player = null

	# 无尽之塔退出，则清空怪物
	if is_endless:
		_reset()


func _reset():
	# 清空怪物
	for data_monster in data_monsters.values():
		remove_monster(data_monster)
		data_monster.kill_role()
	
	endless_layer = 0


func remove_monster(data_monster: DataMonster):
	# 解除怪物死亡监听
	data_monster.role_dead.disconnect(_on_monster_dead)
	# 删除数据
	data_monsters.erase(data_monster.monster_unique_id)


## 对外接口：添加传送点
func add_portal(data_portal: DataPortal):
	data_portals[data_portal.portal_id] = data_portal


## 获取所有传送点
func get_portals():
	return data_portals


func add_npc(data_npc: DataNPC):
	data_npcs[data_npc.id] = data_npc
	npc_added.emit(data_npc)


## 对外接口：刷新怪物
func refresh_monsters():
	for refresh_pos in map_monster_refresh_pos:
		# 如果怪物已经死亡，则清空刷新点的怪物
		if refresh_pos.data_monster and refresh_pos.data_monster.is_dead:
			# 记录怪物刷新间隔开始时间
			monster_refresh_time_dic[refresh_pos.data_monster.monster_id] = Time.get_unix_time_from_system()
			# 清空刷新点怪物
			refresh_pos.data_monster = null

		if not refresh_pos.data_monster:
			var monster_id = refresh_pos.random_monster_id(monster_refresh_time_dic)
			if monster_id:
				var monster_config = monster_config_dic[monster_id]
				# 精英怪的概率
				var is_elite = randf() < 0.01
				# 创建怪物对象
				var monster = monster_manager.create_monster(monster_id, is_elite, monster_config)
				refresh_pos.data_monster = monster
				# 添加怪物
				_add_monster(monster,refresh_pos.pos)


func _on_monster_hurted(data_role:DataRole,data_damage:DataDamage):
	if data_role is DataMonster:
		if data_player:
			data_player.cause_damage(data_damage)
		# 如果boss首次受伤，则开始计算击杀时间
		if data_role.is_boss() and not data_role.is_hurted:
			boss_first_hurted.emit(self, data_role)		


func _on_monster_dead(data_role:DataRole):
	# 删除数据
	remove_monster(data_role)
	# 无尽之塔判断怪物是否全部死亡
	if is_endless:
		# 判断是否还有怪物
		if data_monsters.is_empty():
			# 所有怪物死亡，结束无尽之塔
			end_endless()
	# 如果怪物是boss，则发送boss死亡信号
	if data_role.is_boss():
		boss_killed.emit(self, data_role)


func _add_monster(_monster: DataMonster,_position: Vector2):
	data_monsters[_monster.monster_unique_id] = _monster
	_monster.current_map_id = id
	# 发出怪物添加信号
	monster_added.emit(_monster,_position)
	# 监听怪物受伤
	_monster.role_hurted.connect(_on_monster_hurted)
	# 监听怪物死亡
	_monster.role_dead.connect(_on_monster_dead)


func has_monster_refresh_pos():
	return not map_monster_refresh_pos.is_empty()

	
## 攻击技能作用到目标
func player_attack_skill_effect(
	_data_player: DataPlayer,
	target: DataMonster,
	skill: DataBaseSkill,
	direction: Vector2 = Vector2.RIGHT
):
	if target.is_dead:
		return
	# 查看技能类型
	if skill is DataElementAttackSkill:
		pass
	elif skill is DataEffectAttackSkill:
		pass
	elif skill is DataAttackSkill:
		# 计算伤害
		var damage_value = skill.get_damage_value()
		if _is_attack_hit(_data_player, target):
			var damage : DataDamage
			if skill.damage_value_type == Constants.VALUE_TYPE_PERCENT:
				damage = _create_percent_damage(skill, damage_value, _data_player, target)
			else:
				damage = _create_number_damage(skill, damage_value, _data_player, target)
			damage.direction = direction

			# 造成伤害
			target.get_hurt(damage)
			# 标记攻击来源
			target.add_attack_source(_data_player.player_id)


			# 造成伤害后的特效处理
			_after_damage_effect(_data_player,target, skill, damage)
		else:
			var damage = DataDamage.new(skill.damage_type, DataDamage.SOURCE_TYPE.PLAYER, 0)
			damage.direction = direction
			target.get_hurt(damage)


		# 判断目标是否死亡，给玩家增加经验
		if target.is_dead:
			# 发出玩家击杀怪物信号
			player_killed_monster.emit(_data_player, target)
			# 增加击杀怪物数量
			kill_monster_count_dic[target.monster_id] = kill_monster_count_dic.get(target.monster_id, 0) + 1
			# 判断击杀类的特殊效果
			_check_kill_monster_effect(_data_player, target)

			# 给玩家增加经验
			if not is_endless:
				_data_player.add_exp(target.exp)
			
			# 生成掉落物
			_create_drop_thing(target)


func _after_damage_effect(_data_player: DataPlayer, _target: DataMonster,_skill: DataBaseSkill, damage: DataDamage):
	if _data_player.has_effect("effect_000018"):
		var effect = _data_player.get_effect("effect_000018")
		if effect.value_type == Constants.VALUE_TYPE_PERCENT:
			var recover_mp = damage.value * effect.value
			_data_player.recover_mp(recover_mp)
	if _data_player.has_effect("effect_000019"):
		var attack_attach_poison_effect = _data_player.get_effect("effect_000019")
		if attack_attach_poison_effect.value_type == Constants.VALUE_TYPE_PERCENT:
			# 百分之10的概率中毒
			if randf() < 0.1:
				var damage_value = _data_player.get_final_attack(1) * attack_attach_poison_effect.value
				damage_value = max(damage_value, 1)
				var buff = _create_poison_buff(damage_value)
				_target.add_buff(buff)
	if _data_player.has_effect("effect_000022"):
		var effect = _data_player.get_effect("effect_000022")
		if randf() < effect.value:
			# 伤口撕裂
			var deep_damage_effect = _create_deep_damage_effect()
			_target.add_effect(deep_damage_effect)
	if _data_player.has_effect("effect_000025"):
		var effect = _data_player.get_effect("effect_000025")
		if randf() < effect.value:
			# 护甲撕裂
			var details = _target.get_final_details()
			details.defense -= 1
			details.magic_def -= 1


func _create_deep_damage_effect() -> DataEffect:
	# “撕裂”效果
	var deep_damage_effect = DataEffect.new("effect_000023", "deep_damage")
	deep_damage_effect.value = 1
	deep_damage_effect.value_type = Constants.VALUE_TYPE_NUMBER

	return deep_damage_effect


func _create_poison_buff(value: int) -> DataBuff:
	# “中毒”效果，用时间戳作为id，方便叠加
	var buff_id = str(Time.get_ticks_usec())
	var poison_effect = DataEffect.new(buff_id, "poison")
	poison_effect.value = value
	# “中毒”buff持续5秒
	var buff = DataBuff.new()
	buff.id = buff_id
	buff.name = "中毒"
	buff.duration = 5 / SingletonGame.speed
	buff.remaining_time = buff.duration
	buff.add_effect(poison_effect)
	return buff


func _create_drop_thing(target: DataMonster):
	# 无尽之塔不会掉落
	if is_endless:
		return
	# 掉落物的偏移值，方便展示
	var offset_index = 0
	var drop_things = drop_thing_manager.get_drop_things(target.monster_id,target.is_elite)
	for drop_thing in drop_things:
		# 放入地图数据中
		data_drop_things[drop_thing.uuid] = drop_thing
		# 确定掉落物的归属，当前掉落物归属是击杀者
		drop_thing.picker = data_player

		drop_thing_dropped.emit(drop_thing, target, offset_index)
		offset_index += 1


## 判断击杀类的特殊效果
func _check_kill_monster_effect(_data_player: DataPlayer, _target: DataMonster):
	if _data_player.has_effect("effect_000003"):
		var data_effect = _data_player.get_effect("effect_000003")
		_data_player.recover_hp_with_signal(data_effect.value)


func _create_percent_damage(
	skill: DataBaseSkill,
	_damage_rate: float,
	_data_player: DataPlayer,
	target: DataMonster
) -> DataDamage:
	# 计算伤害值
	var damage_value = 0				
	# 攻击力波动的比率 0-1之间
	var attack_value_rate = randf()	

	#region 技能伤害加成
	var skill_damage_rate = 0
	# 技能增幅加成
	if _data_player.has_skill_enhance(skill.id):
		var skill_enhance = _data_player.get_skill_enhance(skill.id)
		skill_damage_rate += skill_enhance.damage
	# 技能伤害加成
	if _data_player.is_match_mp_cost_enhance():
		var data_effect = _data_player.get_mp_cost_enhance()
		skill_damage_rate += data_effect.value
		# 重置“法力涌动”累计值
		_data_player.reset_mp_cost_enhance()
	# “血气爆发”特殊效果
	if _data_player.is_match_hp_cost_enhance():
		var data_effect = _data_player.get_hp_cost_enhance()
		skill_damage_rate += data_effect.value
		# 重置“血气爆发”累计值
		_data_player.reset_hp_cost_enhance()
	_damage_rate *= 1 + skill_damage_rate
	print("技能伤害加成：",skill_damage_rate)
	#endregion

	# 根据不同加成类型计算最终技能加成的伤害值
	if skill.damage_source_type == 0:
		# 攻击力加成
		# 从玩家的最小攻击力到最大攻击力之间随机一个值
		var attack_value = _data_player.get_final_attack(attack_value_rate)
		# 计算伤害值
		damage_value = attack_value * _damage_rate
	elif skill.damage_source_type == 1:
		# 魔法力加成
		# 从玩家的最小魔法攻击力到最大魔法攻击力之间随机一个值
		var attack_value = _data_player.get_final_magic_attack(attack_value_rate)
		# 计算伤害值
		damage_value = attack_value * _damage_rate
	elif skill.damage_source_type == 2:
		# 攻击力+魔法力加成
		# 从玩家的最小攻击力到最大攻击力之间随机一个值
		var attack_value = _data_player.get_final_attack(attack_value_rate)
		# 从玩家的最小魔法攻击力到最大魔法攻击力之间随机一个值
		var magic_attack_value = _data_player.get_final_magic_attack(attack_value_rate)
		# 计算伤害值
		damage_value = (attack_value + magic_attack_value) * _damage_rate
	
	# 根据伤害类型计算防御减伤
	if skill.damage_type == 0:
		# 计算目标防御减伤
		var defense_reduction_value = target.attribute.defense_reduction_value()
		damage_value -= defense_reduction_value
	elif skill.damage_type == 1:
		# 计算目标魔法防御减伤
		var defense_reduction_value = target.attribute.magic_defense_reduction_value()
		damage_value -= defense_reduction_value


	# 计算最终伤害值（存在各种伤害加成的计算）
	damage_value = _calculate_damage(damage_value, _data_player, target)
	var damage = DataDamage.new(skill.damage_type, DataDamage.SOURCE_TYPE.PLAYER, damage_value)
	damage.value_show_rate = _data_player.get_show_rate(attack_value_rate)
	return damage


func _create_number_damage(
	skill: DataBaseSkill,
	_damage_value: int,
	_data_player: DataPlayer,
	target: DataMonster
) -> DataDamage:
	# 计算伤害值
	var damage_value = 0	
	# 技能增幅加成
	if _data_player.has_skill_enhance(skill.id):
		var skill_enhance = _data_player.get_skill_enhance(skill.id)
		_damage_value *= 1 + skill_enhance.damage

	if skill.damage_type == 0:
		# 物理伤害
		# 计算目标防御减伤
		var defense_reduction_value = target.attribute.defense_reduction_value()
		# 计算伤害值
		damage_value = _damage_value - defense_reduction_value
	elif skill.damage_type == 1:
		# 魔法伤害
		# 计算目标魔法防御减伤
		var defense_reduction_value = target.attribute.magic_defense_reduction_value()
		# 计算伤害值
		damage_value = _damage_value - defense_reduction_value
	# 计算最终伤害值（存在各种伤害加成的计算）
	damage_value = _calculate_damage(damage_value, _data_player, target)
	var damage = DataDamage.new(skill.damage_type, DataDamage.SOURCE_TYPE.PLAYER, damage_value)
	return damage


func _calculate_damage(
	origin_damage_value: int, 
	_data_player: DataPlayer, 
	target: DataMonster
):
	# 伤害值最小为1
	origin_damage_value = max(1, origin_damage_value)
	print("初始伤害值：",origin_damage_value)
	# 特殊效果百分比伤害加成
	#var effect_damage_rate = _effect_damage_rate(_data_player, target)
	#print("特殊效果百分比伤害加成：",effect_damage_rate)
	# 特殊效果固定伤害加成
	var effect_damage_value = _effect_damage_value(_data_player,target)
	print("特殊效果固定伤害加成：",effect_damage_value)
	# 计算最终伤害值
	var final_damage_value = max(1, origin_damage_value + effect_damage_value)
	print("最终伤害值：",final_damage_value)
	return final_damage_value


func _effect_damage_rate(
	_data_player: DataPlayer, 
	_target: DataMonster
) -> float:
	var effect_damage_rate = 0
	return effect_damage_rate


func _effect_damage_value(_data_player: DataPlayer, _target: DataMonster) -> float:
	var effect_damage_value = 0
	# 巨人之力
	if _data_player.has_effect("effect_000011"):
		# 最大生命值相关伤害
		var effect = _data_player.get_effect("effect_000011")
		if effect.value_type == Constants.VALUE_TYPE_PERCENT:
			var max_hp_damage = _data_player.get_final_details().max_hp * effect.value
			print("最大生命值附加伤害：",max_hp_damage)
			effect_damage_value += max_hp_damage
		else:
			# 未实现
			pass
	# 背水一战
	if _data_player.has_effect("effect_000012"):
		var effect = _data_player.get_effect("effect_000012")
		if effect.value_type == Constants.VALUE_TYPE_PERCENT:
			# 损失生命值相关伤害
			var lost_hp = _data_player.get_final_details().max_hp - _data_player.hp
			# 每损失100点生命值，增加value点伤害
			var lost_hp_damage = lost_hp * effect.value
			print("损失生命值附加伤害：",lost_hp_damage)
			effect_damage_value += lost_hp_damage
		else:
			# 未实现
			pass
	# 自损八千
	if _data_player.has_effect("effect_000004"):
		var effect = _data_player.get_effect("effect_000004")
		if effect.value_type == Constants.VALUE_TYPE_NUMBER:
			print("损血特效附加伤害：",effect.value)
			effect_damage_value += effect.value
		else:
			# 未实现
			pass
	# 撕裂
	if _target.has_effect("effect_000023"):
		var effect = _target.get_effect("effect_000023")
		if effect.value_type == Constants.VALUE_TYPE_NUMBER:
			#print("撕裂特效附加伤害：",effect.value)
			effect_damage_value += effect.value
		else:
			# 未实现
			pass
	return effect_damage_value


func _is_attack_hit(attack: DataRole, target: DataRole):
	# 根据玩家命中率和目标闪避率，计算是否命中，命中率计算公式：命中率 = 1 + （玩家命中值 - 目标闪避值）/ 100.0
	var accuracy_rate = 1 + (attack.attribute.final_details.accuracy - target.attribute.final_details.evasion) / 100.0
	# 如果命中率小于0，则不命中
	if accuracy_rate < 0:
		accuracy_rate = 0
	# 如果命中率大于100，则命中率为100
	if accuracy_rate > 1:
		accuracy_rate = 1
	# 随机0-1之间的一个数，如果小于命中率，则命中，否则不命中
	var accuracy_hit = randf()
	if accuracy_hit < accuracy_rate:
		return true
	return


## Buff技能作用到目标
func _player_buff_skill_effect(data_player: DataPlayer, target: DataPlayer, skill: DataBaseSkill):
	if skill is DataAttriBuffSkill:
		pass
	elif skill is DataEffectBuffSkill:
		pass
	elif skill is DataBuffSkill:
		pass


## 处理掉落物的拾取逻辑
func _process_drop_thing_pick(_data_player: DataPlayer):
	# 遍历地图数据中的掉落物
	for drop_thing in data_drop_things.values():
		# 看是否有拾取权属于data_player的物品，如果有的话，则设置归属者为data_player
		if drop_thing.owner == null and drop_thing.picker == _data_player:
			drop_thing_picked.emit(self, drop_thing)
			# 一次只能拾取一个物品
			break


func remove_drop_thing(drop_thing: DataBagItem):
	drop_thing.owner = data_player
	# 从数据中删除
	data_drop_things.erase(drop_thing.uuid)


func _on_player_pick_execute(data_player: DataPlayer):
	# print("_on_player_pick_execute:",data_player.player_name)
	_process_drop_thing_pick(data_player)


func _on_player_hurted(data_player: DataPlayer, data_damage: DataDamage):
	print("_on_player_hurted:",data_damage.value)
	# 检查当前buff
	for buff in data_player.buff_dic.values():
		for effect in buff.get_all_effects():
			if effect.type == DataEffect.DefenseCounterDamage and effect.is_active:
				if Time.get_ticks_msec() - effect.last_invoke_time > effect.invoke_interval * 1000:
					effect.last_invoke_time = Time.get_ticks_msec()

					# 防御反伤，每10点防御力，造成value伤害
					var defense_damage = data_player.get_final_details().defense * effect.value / 10.0
					print("触发防御反伤：",defense_damage)
					# 给半径范围内的怪物造成伤害(等同于执行一个AOE技能)
					var skill = _on_create_defense_counter_damage_skill(defense_damage,effect.radius)
					data_player.execute_skill(skill)


func _on_create_defense_counter_damage_skill(defense_damage: int, radius: int):
	var skill = DataAttackSkill.new(DataEffect.DefenseCounterDamage,"attack")
	skill.name = "防御反伤"
	skill.damage_type = DataDamage.TYPE.PHYSICAL
	skill.target_type = 1
	skill.radius = radius
	skill.count = Constants.INF
	skill.level = 1
	skill.damage_level = [[defense_damage]]
	skill.mp_cost_level = [0]
	skill.damage_value_type = Constants.VALUE_TYPE_NUMBER
	return skill


func on_monster_skill_executed(
	data_monster: DataMonster,
	target: DataRole,
	skill: DataBaseSkill,
	direction: Vector2 = Vector2.RIGHT
):
	if skill is DataAttackSkill:
		if _is_attack_hit(data_monster, target):
			# 防御减伤率
			var defense_reduction_value = target.attribute.defense_reduction_value()
			# 伤害值
			var damage_value = data_monster.attribute.final_details.attack - defense_reduction_value
			# 伤害值最小为1
			damage_value = max(1, damage_value)
			var damage = DataDamage.new(DataDamage.TYPE.PHYSICAL,DataDamage.SOURCE_TYPE.MONSTER, damage_value)
			damage.direction = direction
			target.get_hurt(damage)
		else:
			var damage = DataDamage.new(DataDamage.TYPE.PHYSICAL,DataDamage.SOURCE_TYPE.MONSTER, 0)
			damage.direction = direction
			target.get_hurt(damage)

			# 怪物攻击被闪避时，判定相关特效
			if data_player and data_player.has_effect("effect_000021"):
				var effect = data_player.get_effect("effect_000021")
				if randf() < effect.value:
					# 闪避追击
						data_player.execute_normal_attack()


# 判断玩家是否有魔法屏障技能的buff，如果有，则调整伤害
func update_damage_by_effect(damage: DataDamage):
	var data_buff = data_player.get_buff_by_id("skill_000103")
	if data_buff:
		var effect = data_buff.get_effect(DataEffect.ManaDefense)
		if effect:
			# 计算可以转换的MP量（不能超过玩家当前MP）
			var can_convert_mp = min(effect.value, data_player.mp)
			# 计算剩余伤害
			var rest_damage = damage.value - can_convert_mp
			if rest_damage > 0:
				damage.value = rest_damage
				damage.damage_mp = can_convert_mp
			else:
				damage.value = 0
				damage.damage_mp = damage.value


## 获取总的怪物击杀数量
func get_total_kill_monster_count():
	var total_count = 0
	for count in kill_monster_count_dic.values():
		total_count += count
	return total_count


## 获取单个怪物击杀数量
func get_kill_monster_count(monster_id: String):
	return kill_monster_count_dic.get(monster_id, 0)


func get_player():
	return data_player


## 开始无尽之塔
func start_endless():
	endless_layer += 1
	# 根据层数确定怪物id
	for i in range(monster_count):
		var monster_id = "monster_00000" + str(endless_layer)
		var monster_config = monster_config_dic[monster_id]
		var monster = monster_manager.create_monster(monster_id, false, monster_config)
		# 强化怪物
		monster.upgrade(monster_upgrade)
		# 修改名称
		monster.name = monster.name + "(魔)"
		# 随机一个位置
		var pos = Vector2(randf(), randf())
		# 添加怪物
		_add_monster(monster,pos)


func end_endless():
	# 结束无尽之塔
	endless_ended.emit(self)


func is_endless_max():
	return endless_layer >= ENDLESS_LAYER_MAX


## 保存地图中怪物刷新时间信息
func save() -> Dictionary:
	var result = {}
	
	result["id"] = id
	if is_explored:
		result["is_explored"] = true
	if not monster_refresh_time_dic.is_empty():
		result["monster_refresh_time_dic"] = monster_refresh_time_dic
	if not kill_monster_count_dic.is_empty():
		result["kill_monster_count_dic"] = kill_monster_count_dic
	if not data_npcs.is_empty():
		result["data_npcs"] = {}
		for data_npc in data_npcs.values():
			result["data_npcs"][data_npc.id] = data_npc.save()
	return result


func load(data: Dictionary) -> void:
	id = data.id
	if data.has("is_explored"):
		is_explored = data.is_explored
	if data.has("monster_refresh_time_dic"):
		monster_refresh_time_dic = data.monster_refresh_time_dic
	if data.has("kill_monster_count_dic"):
		kill_monster_count_dic = data.kill_monster_count_dic
	if data.has("data_npcs"):
		for data_npc_id in data["data_npcs"].keys():
			var data_npc = data_npcs[data_npc_id]
			data_npc.load(data["data_npcs"][data_npc_id])
