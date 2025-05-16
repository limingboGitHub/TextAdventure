extends Node2D

## 地图场景
##
## 负责展示DataMap中的相关数据，以及处理用户的操作

# 地图数据，由世界创建好，并注入当前地图场景中
var data_map: DataMap

var lock_monster_scene

const EFFECT_SKILLS = [
	"skill_000100",
	"skill_000101",
	"skill_000103"
]

# 怪物开始受伤时间 key:怪物id value:开始受伤时间
var boss_hurt_time: Dictionary = {}


signal portal_updated(portal: DataPortal,map_scene: Node2D)

signal invoked_portal(portal: DataPortal, map_scene: Node2D)

signal attack_target_changed(attack_target)

signal map_drop_showed(data_map: DataMap)

signal endless_exit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 确保地图数据已经加载
	assert(data_map, "地图数据未加载")
	# 地图名称
	$CanvasLayer/Name.text = data_map.name

	# 加载地图传送点
	for portal in data_map.data_portals.values():
		_add_portal(portal)
	# 加载地图NPC
	for npc in data_map.data_npcs.values():
		_add_NPC(npc)
	
	# 加载无尽之塔
	if data_map.id == "map_000199":
		var endless_control = SingletonGameScenePre.EndlessControlScene.instantiate()
		$CanvasLayer.add_child(endless_control)
		# 注入数据
		endless_control.init_data(data_map)
		# 监听无尽之塔退出事件
		endless_control.endless_exit.connect(_on_endless_exit)

	# 监听
	data_map.first_player_entered.connect(_on_first_player_entered)
	data_map.monster_added.connect(_add_monster)
	data_map.npc_added.connect(_on_npc_added)
	data_map.drop_thing_dropped.connect(_on_drop_thing_dropped)
	data_map.drop_thing_picked.connect(_on_drop_thing_picked)
	data_map.boss_first_hurted.connect(_on_boss_first_hurted)
	data_map.boss_killed.connect(_on_boss_killed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 判断玩家是否有嘲讽技能
	_process_drag_monster(delta)

	# 更新击杀记录
	_update_boss_kill_record()


func _update_boss_kill_record():
	for start_time in boss_hurt_time.values():
		var hurt_time = Time.get_ticks_msec() - start_time
		$CanvasLayer/BossStatus/CostTime.text = str(hurt_time / 1000.0)


func _process_drag_monster(delta: float):
	var data_player = data_map.get_player()
	if data_player:
		if data_player.has_effect(DataEffect.DragMonster):
			var effect = data_player.get_effect(DataEffect.DragMonster)
			var speed = effect.value
			var player_scene = $CanvasLayer/GameZone/Players.get_node(data_player.player_id)
			for monster_scene in $CanvasLayer/GameZone/Monsters.get_children():
				if monster_scene.data_monster.is_dead:
					continue
				monster_scene.set_attack_target(player_scene)
				var direction = player_scene.global_position - monster_scene.global_position
				if direction.length() > 30:
					monster_scene.position += direction.normalized() * speed * delta


# 添加怪物
func _add_monster(monster: DataMonster,_position: Vector2):
	# 普通怪物场景
	var monster_scene_pre = SingletonGameScenePre.MonsterScene
	# boss怪物场景
	if monster.type == "boss":
		monster_scene_pre = SingletonGameScenePre.MonsterBossScene
	# 初始化怪物场景
	var monster_scene = monster_scene_pre.instantiate()
	monster_scene.data_monster = monster
	monster_scene.name = monster.monster_unique_id
	# 设置怪物位置
	# 获取地图场景的尺寸
	var size = $CanvasLayer/GameZone/Monsters.size
	if _position != Vector2.INF:
		# 如果怪物刷新点位置不为空，则设置怪物位置
		monster_scene.position = Vector2(_position.x * size.x, _position.y * size.y)
	else:
		# 如果怪物刷新点位置为空，则随机一个位置
		monster_scene.position = Vector2(randf() * size.x, randf() * size.y)
	# 加入场景
	$CanvasLayer/GameZone/Monsters.add_child(monster_scene)
	# 监听点击事件
	monster_scene.pressed.connect(_on_monster_pressed.bind(monster_scene))
	# 监听怪物技能执行
	monster.skill_executed.connect(_on_monster_skill_executed)

	# 如果刷新的是boss，则展示击杀信息
	if monster.is_boss():
		$CanvasLayer/BossStatus.show()
		# 展示击杀记录
		if SingletonGame.boss_kill_time.has(monster.monster_id):
			$CanvasLayer/BossStatus/RecordTime.text = str(SingletonGame.boss_kill_time[monster.monster_id]/1000.0)
		else:
			$CanvasLayer/BossStatus/RecordTime.text = "-"
		# 展示击杀时间
		$CanvasLayer/BossStatus/CostTime.text = "-"


func _on_monster_skill_executed(data_monster: DataMonster, skill: DataBaseSkill):
	# 获取目标和自身的方向向量
	var monster_scene = $CanvasLayer/GameZone/Monsters.get_node(data_monster.monster_unique_id)
	var target_scene = monster_scene.attack_target
	var direction = target_scene.global_position - monster_scene.global_position
	# 获取目标和自身距离
	var distance = direction.length()
	# 标准化方向向量
	direction = direction.normalized()
	# 如果距离大于技能半径
	if distance <= skill.radius:
		# 怪物场景添加执行动画
		monster_scene.add_skill_execute_effect(skill,direction)
		# 技能执行
		data_map.on_monster_skill_executed(data_monster, target_scene.data_player, skill, direction)


func _add_portal(portal: DataPortal):
	if portal.disabled:
		return
	
	var portal_scene = SingletonGameScenePre.PortalScene.instantiate()
	portal_scene.name = portal.portal_id
	portal_scene.text = portal.target_map_name
	portal_scene.position = portal.position
	portal_scene.pressed.connect(_on_portal_button_pressed.bind(portal))
	$CanvasLayer/GameZone/Portals.add_child(portal_scene)


## 更新传送点名称
func update_portal_name(portal: DataPortal,is_explored: bool):
	var portal_button = $CanvasLayer/GameZone/Portals.get_node(portal.portal_id)
	if portal_button != null:
		if is_explored:
			portal_button.text = portal.target_map_name
		else:
			portal_button.text = "???"
	

func _add_NPC(data_npc: DataNPC):
	var npc_scene = SingletonGameScenePre.NPCScene.instantiate()
	npc_scene.set_data(data_npc)
	npc_scene.position = data_npc.position
	$CanvasLayer/GameZone/Npc.add_child(npc_scene)


func _on_portal_button_pressed(portal: DataPortal):
	# print("_on_portal_button_pressed:",portal.portal_id)
	invoked_portal.emit(portal, self)


# 首个玩家进入地图，开始刷新怪物
func _on_first_player_entered():
	print("第一个玩家进入地图")
	if data_map.has_monster_refresh_pos():
		if $CloseMonsRefreshTimer.is_stopped():
			$MonsterRefreshTimer.start()
		else:
			$CloseMonsRefreshTimer.stop()


func _on_monster_refresh_timer_timeout() -> void:
	# print('_on_monster_refresh_timer_timeout')
	data_map.refresh_monsters()
	# 如果目前还无怪物，则遍历刷新点信息，更新刷新时间
	if data_map.data_monsters.is_empty():
		for refresh_pos in data_map.map_monster_refresh_pos:
			for refresh_info in refresh_pos.monster_refresh_list:
				# 怪物刷新CD开始时间
				var start_time = data_map.monster_refresh_time_dic[refresh_info.monster_id]
				# 怪物刷新CD时间
				var cd_time = (refresh_info.refresh_interval / float(SingletonGame.speed))
				# 剩余时间
				var left_time = cd_time - (Time.get_unix_time_from_system() - start_time)
				$CanvasLayer/RefreshTime.show()
				$CanvasLayer/RefreshTime/RestTime.text = str(int(left_time))
				# 当前默认只有BOSS有刷新时间，只展示第一个
				return
	else:
		$CanvasLayer/RefreshTime.hide()


func _on_close_mons_refresh_timer_timeout() -> void:
	#print('_on_close_mons_refresh_timer_timeout')
	$MonsterRefreshTimer.stop()
	$CanvasLayer/RefreshTime.hide()


func _on_monster_pressed(monster_scene) -> void:
	#print("_on_monster_pressed:", monster_scene.data_monster.monster_id)
	var data_player = data_map.get_player()
	var player_scene = $CanvasLayer/GameZone/Players.get_node(data_player.player_id)
	if monster_scene.is_selected:
		player_scene.set_attack_target(null)
		#monster_scene.unselect()
	else:
		player_scene.set_attack_target(monster_scene)


func _on_money_dropped(data_money: DataMoney, target: DataRole,offset_index:int):
	# 生成金币场景
	var money_scene = SingletonGameScenePre.MoneyScene.instantiate()
	money_scene.set_money(data_money)
	# 确认目标位置
	var target_pos = _get_data_role_position(target)
	money_scene.position = target_pos
	money_scene.x_offset = _offset_index_to_x(offset_index)
	
	$CanvasLayer/GameZone/DropThingControl.add_child(money_scene)


func _on_drop_thing_dropped(drop_thing: DataBagItem, target: DataRole,offset_index:int):
	# print("_on_drop_thing_dropped:", drop_thing.id)
	# 生成掉落物场景
	if drop_thing is DataMoney:
		_on_money_dropped(drop_thing, target,offset_index)
	else:
		var drop_thing_scene = SingletonGameScenePre.DropThingScene.instantiate()
		drop_thing_scene.set_item(drop_thing)
		# 确认目标位置
		var target_pos = _get_data_role_position(target)
		drop_thing_scene.position = target_pos
		drop_thing_scene.x_offset = _offset_index_to_x(offset_index)

		$CanvasLayer/GameZone/DropThingControl.add_child(drop_thing_scene)


func _get_data_role_position(data_role: DataRole) -> Vector2:
	if data_role is DataPlayer:
		var player_scene = $CanvasLayer/GameZone/Players.get_node(data_role.player_id)
		return player_scene.global_position
	elif data_role is DataMonster:
		var monster_scene = $CanvasLayer/GameZone/Monsters.get_node(data_role.monster_unique_id)
		return monster_scene.global_position
	else:
		return Vector2.ZERO


func _offset_index_to_x(index)-> int:
	var offset_unit = 26
	if index == 0:
		return 0
	elif index % 2 == 0:
		return -int(index / 2) * offset_unit
	else:
		return int((index+1)/2) * offset_unit


func _on_drop_thing_picked(_data_map: DataMap, drop_thing: DataBagItem):
	# 查找到对应的掉落物
	var drop_thing_scene = $CanvasLayer/GameZone/DropThingControl.get_node(drop_thing.uuid)
	# 查找到玩家
	var player_scene = $CanvasLayer/GameZone/Players.get_node(_data_map.get_player().player_id)
	# 设置拾取目标
	drop_thing_scene.set_pick_target(player_scene.global_position)


func _on_boss_first_hurted(_data_map: DataMap, data_monster: DataMonster):
	boss_hurt_time[data_monster.monster_unique_id] = Time.get_ticks_msec()


func _on_boss_killed(_data_map: DataMap, data_monster: DataMonster):
	var hurt_time = Time.get_ticks_msec() - boss_hurt_time[data_monster.monster_unique_id]
	boss_hurt_time.erase(data_monster.monster_unique_id)
	
	# 更新击杀时间
	$CanvasLayer/BossStatus/CostTime.text = str(hurt_time/1000.0)
	# 更新击杀记录
	if not SingletonGame.boss_kill_time.has(data_monster.monster_id) \
		or hurt_time < SingletonGame.boss_kill_time[data_monster.monster_id]:
		SingletonGame.boss_kill_time[data_monster.monster_id] = hurt_time
		$CanvasLayer/BossStatus/RecordTime.text = str(hurt_time/1000.0)


func _on_npc_added(data_npc: DataNPC):
	# print("_on_npc_added:",data_npc.npc_id)
	_add_NPC(data_npc)


func add_player_scene(data_player: DataPlayer,player_scene: Control):
	print('player_added:', data_player.player_id)
	# 获取地图场景的尺寸
	var size = $CanvasLayer/GameZone/Players.size
	# 设置玩家位置
	player_scene.position = Vector2(0.5 * size.x, 0.5 * size.y)
	# 监听寻找攻击目标
	player_scene.find_target_started.connect(_on_find_target_started)
	# 监听攻击目标变换
	player_scene.attack_target_changed.connect(_on_attack_target_changed)
	# 监听玩家的技能执行
	data_player.skill_executed.connect(_on_skill_executed)

	# 加入场景
	$CanvasLayer/GameZone/Players.add_child(player_scene)

	# 更新传送点信息，由于传送点的展示需要依赖其他地图的信息，因此将事件交给上层处理
	for portal in data_map.data_portals.values():
		portal_updated.emit(portal,self)

	scene_show()


func remove_player_scene(data_player: DataPlayer):
	print('remove_player:', data_player.player_id)
	# 根据玩家id删除场景
	var player_scene = $CanvasLayer/GameZone/Players.get_node(data_player.player_id)
	$CanvasLayer/GameZone/Players.remove_child(player_scene)
	# 移除攻击目标
	player_scene.attack_target = null
	# 解除监听
	player_scene.find_target_started.disconnect(_on_find_target_started)
	player_scene.attack_target_changed.disconnect(_on_attack_target_changed)
	data_player.skill_executed.disconnect(_on_skill_executed)
	# 如果地图没有玩家了，延时关闭怪物刷新
	$CloseMonsRefreshTimer.start()

	# 地图隐藏
	scene_hide()


func _on_find_target_started(player_scene: Control):
	#print('find_target_started:')
	var min_distance_monster = _find_min_distance_monster(player_scene)
	player_scene.set_attack_target(min_distance_monster)


func _on_attack_target_changed(attack_target):
	attack_target_changed.emit(attack_target)


func _find_min_distance_monster(player_scene: Control) -> Control:
	var min_distance = INF
	var min_distance_monster = null
	for monster in $CanvasLayer/GameZone/Monsters.get_children():
		if monster.data_monster.is_dead:
			continue
		# 怪物和玩家距离
		var monster_distance = monster.global_position.distance_to(player_scene.global_position)
		# 记录最小距离
		if monster_distance < min_distance:
			min_distance = monster_distance
			min_distance_monster = monster
	return min_distance_monster


# 必须隐藏和展示CanvasLayer，根节点的show和hide无效
func scene_hide():
	$CanvasLayer.hide()


func scene_show():
	$CanvasLayer.show()


func _on_skill_executed(player: DataPlayer, skill: DataBaseSkill,skill_add_count: int = 0):
	print("skill_executed:",player.player_id,skill.name)
	var player_scene = $CanvasLayer/GameZone/Players.get_node(player.player_id)
	if player_scene == null:
		return

	if skill.target_type == 1 or skill.target_type == 2:
		var target_monster_list = _get_skill_effect_monster_list(player_scene, skill)
		if target_monster_list.size() > 0:
			# 添加释放动画
			_skill_executed_casting(
				skill,
				player_scene,
				target_monster_list[0],
				skill_add_count,
				func(scene: Node2D):
					# 解除和玩家的联系，加入到地图特效中
					_add_to_effect_groups(scene)

					var _target_monster_list = _get_skill_effect_monster_list(player_scene, skill)
					if _target_monster_list and _target_monster_list.size() > 0:
						# 添加技能名称动画
						_add_skill_name_ani(_target_monster_list[0],player_scene,skill)
						# 设置技能目标
						if scene:
							scene.set_target_scene(_target_monster_list[0]),
				func():
					# 重置玩家执行CD
					player.reset_execute_cd(),
				func():
					# 开始伤害判定
					skill.damage_array_index = 0
					# 确定技能作用目标
					var _target_monster_list = _get_skill_effect_monster_list(player_scene, skill)

					if _target_monster_list and _target_monster_list.size() > 0:
						_skill_executed_damage_judge(_target_monster_list,skill,player_scene)
						print("第0段技能伤害判定")
						# 如果技能追加判定为真，则执行追加技能
						if skill_add_count > 0:
							for i in range(skill_add_count):
								_skill_executed_damage_judge(_target_monster_list,skill,player_scene)

						# 如果技能伤害判定段数未结束，则启动剩余伤害判定定时器
						if not skill.is_damage_array_index_end():
							for i in range(1,skill.get_damage_array_size()):
								await get_tree().create_timer(skill.damage_interval/2).timeout
								_skill_executed_damage_judge(_target_monster_list,skill,player_scene)
								print("第",i,"段技能伤害判定")
			)
			
		# 处理技能释放后的特殊效果
		if skill.is_effect_after_skill_executed:
			_effect_after_skill_executed(player, skill)


	elif skill.target_type == 0 or skill.target_type == 2:
		# 寻找技能作用目标
		var target_player_list = []

		# TODO 需要根据技能的作用范围，找到技能半径内的玩家
		for target_player in data_map.data_players.values():
			target_player_list.append(target_player)
		#print("执行技能：", skill.name, " 选取玩家目标：", target_player_list)

		# 技能作用到目标
		for target in target_player_list:
			data_map.player_buff_skill_effect(player, target, skill)


# 解除链接并加入地图特效层（防止技能弹道脱手后仍然跟随玩家移动）
func _add_to_effect_groups(scene: Node2D):
	if not scene:
		return
	var global_pos = scene.global_position
	var parent = scene.get_parent()
	if parent:
		parent.remove_child(scene)
		$CanvasLayer/GameZone/Effects.add_child(scene)
		scene.global_position = global_pos


# 统计技能作用半径内的怪物
func _get_skill_effect_monster_list(player_scene: Control, skill: DataBaseSkill) -> Array:
	var effect_position = skill.effect_position
	if effect_position == null:
		# 如果技能中心点类型为0，则使用玩家位置
		if skill.center_type == 0:
			effect_position = player_scene.global_position
		# 如果技能中心点类型为1，则使用目标位置作为中心位置
		else:
			if player_scene.attack_target:
				effect_position = player_scene.attack_target.global_position
			else:
				return []

	# 技能半径
	var radius = skill.radius
	# 技能目标数量
	var count = skill.count
	# 特殊效果增幅
	if player_scene.data_player.has_skill_enhance(skill.id):
		var skill_enhance = player_scene.data_player.get_skill_enhance(skill.id)
		radius += skill_enhance.radius
		count += skill_enhance.count
	# 其他增幅
	radius *= (1 + player_scene.data_player.attack_range_increase)

	# 统计技能半径范围内的怪物
	var temp_monster_list = []
	for monster_scene in $CanvasLayer/GameZone/Monsters.get_children():
		if monster_scene.data_monster.is_dead:
			continue
		var monster_distance = monster_scene.global_position.distance_to(effect_position)
		if monster_distance <= radius:
			temp_monster_list.append({"monster": monster_scene, "distance": monster_distance})
	
	# 按距离从小到大排序
	temp_monster_list.sort_custom(func(a, b): return a.distance < b.distance)
		
	# 取前skill.count个最近的怪物
	var target_monster_list = []
	for i in range(min(count, temp_monster_list.size())):
		target_monster_list.append(temp_monster_list[i].monster)
	return target_monster_list


# 技能执行后，正在施放阶段
func _skill_executed_casting(
	skill: DataBaseSkill,
	player_scene: Control,
	first_target: Control,
	skill_add_count: int,
	call_back_cast_finished: Callable,
	call_back_cast_interrupted: Callable,
	call_back_finished: Callable,
):
	if EFFECT_SKILLS.has(skill.id):
		if player_scene.data_player.is_resting:
			return
		var attack_effect = SingletonGameScenePre.AttackEffect2Scene.instantiate()
		attack_effect.skill_id = skill.id
		attack_effect.skill_radius = skill.radius
		attack_effect.skill_add_count = skill_add_count
		player_scene.add_child(attack_effect)
		attack_effect.set_target_scene(first_target)
		attack_effect.global_position = player_scene.global_position
		attack_effect.move_speed = skill.skill_move_speed
		attack_effect.scale_duration = skill.cd
		# 技能增幅
		if player_scene.data_player.has_skill_enhance(skill.id):
			var skill_enhance = player_scene.data_player.get_skill_enhance(skill.id)
			attack_effect.scale_duration = skill.cd + skill_enhance.cd
			attack_effect.skill_radius = skill.radius + skill_enhance.radius
		# 监听动画释放完毕
		attack_effect.ani_skill_cast_finished.connect(call_back_cast_finished)
		# 监听动画被打断，动画打断则重置玩家执行CD
		attack_effect.ani_skill_cast_interrupted.connect(call_back_cast_interrupted)
		# 监听动画结束
		attack_effect.ani_all_finished.connect(call_back_finished)
	else:
		# 没有释放动画的直接执行回调
		call_back_cast_finished.call(null)
		call_back_finished.call()


# 伤害判定
func _skill_executed_damage_judge(_target_monster_list, skill: DataBaseSkill, player_scene):
	for monster_scene in _target_monster_list:
		# 计算攻击方向
		var direction = (monster_scene.global_position - player_scene.global_position).normalized()
		# 伤害判定
		data_map.player_attack_skill_effect(player_scene.data_player, monster_scene.data_monster, skill, direction)
		# 如果怪物未死亡，则设定目标为攻击者
		if not monster_scene.data_monster.is_dead:
			monster_scene.set_attack_target(player_scene)
		# 技能作用到目标后的特殊效果
		_effect_after_attack_target(player_scene.data_player, skill, monster_scene,direction)


func _add_skill_name_ani(first_target,player_scene,skill):
	# 添加释放特效
	var direction = (first_target.global_position - player_scene.global_position).normalized()
	player_scene.add_skill_executed_effect(skill,direction)


func _on_attack_effect_finished(
	attack_effect: Node2D,
	player_scene: Control,
	_target_scene: Control,
	skill: DataBaseSkill,
	direction: Vector2 = Vector2.RIGHT):
	if _target_scene.data_monster.is_dead:
		return

	attack_effect.animation_finished.disconnect(_on_attack_effect_finished)
	# 移除特效
	attack_effect.queue_free()
	# 技能作用到目标
	data_map.player_attack_skill_effect(player_scene.data_player, _target_scene.data_monster, skill, direction)
	# 如果怪物未死亡，则设定目标为攻击者
	if not _target_scene.data_monster.is_dead:
		_target_scene.set_attack_target(player_scene)
	# 技能作用到目标后的特殊效果
	_effect_after_attack_target(player_scene.data_player, skill, _target_scene,direction)


func _effect_after_attack_target(
	_player: DataPlayer, 
	_skill: DataBaseSkill, 
	_monster_scene: Control, 
	_direction: Vector2
):
	if _player.has_effect("effect_000005"):
		# 只有常规攻击技能会触发该效果
		if _skill.id.begins_with("skill_"):	
			var effect = _player.get_effect("effect_000005")
			# 10%的概率命中
			var hit_rate = randf() <= 0.1
			if hit_rate:
				print("赤焰爆炸：",effect.value)
				var skill = effect.get_special_skill()
				if skill != null:
					skill.effect_position = _monster_scene.global_position
					# 不触发技能释放特效
					_on_skill_executed(_player,skill)
					# 添加爆炸粒子特效
					_add_explode_particle_effect(_monster_scene.position)


func _add_explode_particle_effect(_position: Vector2):
	var explode_particle_effect = SingletonGameScenePre.AttackEffectScene.instantiate()
	explode_particle_effect.position = _position
	$CanvasLayer/GameZone/Effects.add_child(explode_particle_effect)
	explode_particle_effect.play_effect()


# 技能执行后，处理一些特殊效果，例如"自身受到伤害"
func _effect_after_skill_executed(_player: DataPlayer, _skill: DataBaseSkill):
	if _player.has_effect("effect_000004"):
		var effect = _player.get_effect("effect_000004")
		var damage = DataDamage.new(DataDamage.TYPE.MAGICAL, DataDamage.SOURCE_TYPE.MONSTER, effect.value)
		_player.get_hurt(damage)


func _on_drag_monster_requested(_player: DataPlayer,_speed: int):
	print("drag_monster_requested:",_player.player_id)
	var _player_scene = $CanvasLayer/GameZone/Players.get_node(_player.player_id)
	# 将当前地图所有怪物吸引至目标位置30码
	for monster_scene in $CanvasLayer/GameZone/Monsters.get_children():
		if monster_scene.data_monster.is_dead:
			continue


func _on_map_drop_bt_pressed() -> void:
	map_drop_showed.emit(data_map)


func _on_endless_exit():
	endless_exit.emit()
