class_name DataWorld

## 承载整个游戏世界数据的初始类
##
## 从该类开始加载游戏世界数据，加载地图、任务管理器、资源管理器、人物管理器等
var map_manager = MapManager.new()
var mission_manager = MissionManager.new()
var res_manager = ResManager.new()
var player_manager = PlayerManager.new()
var dropthing_manager: DropThingManager

# 地区数据 key:地区id,value:地区数据，结构见map_region.json
var region_dic: Dictionary = {}
# 地区名称 key:地区id,value:地区名称
var region_name_dic: Dictionary = {}
# 地区的连通信息 key:地区id,value:地图连通信息Array
var region_connects: Dictionary = {}
# 地图的地区信息 key:地图id,value:地区id
var map_region_dic: Dictionary = {}
# 地图数据 key:地图id,value:地图数据
var map_dic: Dictionary = {}

# 日志工具
var log_tool = LogTool.new()

# 任务页面展示工具
var mission_page_tool = MissionPageTool.new()

# NPC和地图的映射，key:npc_id,value:map_id
var npc_map_dic = {}

# 记录任务的被依赖关系，当任务完成时，触发依赖任务的可见性限制
# key:被依赖任务id,value:依赖任务id列表
var mission_depend_dic = {}

signal load_res_finished

signal load_finished

signal local_player_created(data_player: DataPlayer)

signal shop_showed(shop_bag: DataBag, player_bag: DataBag)

signal mission_phase_added(data_mission_phase: DataMissionPhase)

signal mission_phase_finished(data_mission_phase: DataMissionPhase)

signal mission_phase_require_updated(data_mission_phase: DataMissionPhase)

signal drop_thing_picked(drop_thing: DataBagItem)


func start():
	log_tool.init("data_world", "")
	log_tool.print_time('start')
	# 加载资源
	res_manager.load_res_finished.connect(_on_load_res_finished)
	res_manager.load()




func _on_load_res_finished():
	log_tool.print_time('_on_load_res_finished')

	load_res_finished.emit()


# 加载游戏世界数据
func load_data_world(
	data_bag_from_cache: DataBag, 
	data_role_equip_from_cache: DataRoleEquip, 
	data_skill_bag_from_cache: DataSkillBag,
	map_dic_from_cache: Dictionary,
	mission_dic_from_cache: Dictionary,
	data_alchemy_bag_from_cache: DataAlchemyBag
):
	#加载任务管理器
	mission_manager.init_missions(res_manager, mission_dic_from_cache)
	
	# 加载掉落物管理器
	dropthing_manager = DropThingManager.new(res_manager)

	#region 初始化背包
	# 如果背包数据不为空，则表示有存档数据。
	# 为了节省存储空间，存档数据里只包含基础信息，需要根据基础信息加载详细信息
	if data_bag_from_cache != null:
		data_bag_from_cache.for_each_item(dropthing_manager.load_item)
	# 将背包输入注入玩家管理器
	player_manager.init_data_bag(data_bag_from_cache)
	# 任务管理器监听背包物品变化
	player_manager.data_bag.item_count_changed.connect(mission_manager.data_bag_item_changed)
	#endregion

	#region 初始化炼金背包
	# 将炼金背包输入注入玩家管理器
	player_manager.init_data_alchemy_bag(
		data_alchemy_bag_from_cache,
		res_manager.alchemy_dic,
		res_manager.item_id_name_map
	)
	# 更新任务中的物品要求信息
	player_manager.data_alchemy_bag.update_mission_require_collect(func(item_id: String) -> int:
		return player_manager.get_data_bag().get_item_total_count(item_id)
	)
	# 炼金背包监听背包物品变化
	player_manager.data_bag.item_count_changed.connect(player_manager.data_alchemy_bag.item_count_changed)
	#endregion
	
	#region 初始化装备栏
	# 如果装备栏数据不为空，则表示有存档数据。
	# 为了节省存储空间，存档数据里只包含基础信息，需要根据基础信息加载详细信息
	if data_role_equip_from_cache != null:
		data_role_equip_from_cache.for_each_item(dropthing_manager.load_item)
	# 将装备栏输入注入玩家管理器
	player_manager.init_role_equip(data_role_equip_from_cache)
	#endregion

	# 初始化技能背包
	player_manager.create_data_skill_bag(
		res_manager.skill_dic,
		res_manager.effect_dic,
		data_skill_bag_from_cache
	)

	#region 加载地图数据
	var map_region_dic = res_manager.get_map_region_dic()
	for region_id in map_region_dic.keys():
		var region_config = map_region_dic[region_id]
		# 获取地区名称
		var region_name = region_config["name"]
		region_name_dic[region_id] = region_name
		# 获取地图列表
		var maps_dic = region_config["maps"]
		for map_id in maps_dic.keys():
			# 获取地图的配置
			var map_config = res_manager.get_map_config(map_id)
			# 获取地图怪物刷新位置
			var map_monster_refresh_pos = res_manager.get_map_monster_pos(map_id)
			# 根据地图怪物获取怪物配置信息
			var map_monster_config_dic = get_monster_config_dic(map_monster_refresh_pos)
			# 无尽之塔需要获取所有怪物配置信息
			if map_config.has("endless"):
				map_monster_config_dic = get_monster_config_dic_endless()
			# 创建地图
			var map = map_manager.get_map_by_config(
				map_id,
				map_config,
				map_monster_refresh_pos,
				map_monster_config_dic,
				res_manager.map_npc_dic,
				dropthing_manager,
				mission_manager
			)
			# 完善地图位置信息
			map.position = Vector2(maps_dic[map_id]["x"],maps_dic[map_id]["y"])
			# 完善地图的传送点信息
			fill_portal_name(map,region_id)
			# 添加地区信息
			_add_region_info(map,region_id)
			# 将地图添加到地图列表中
			map_dic[map_id] = map
			# 如果有地图存档数据，则加载地图存档数据
			if map_dic_from_cache.has(map_id):
				map.load(map_dic_from_cache[map_id])
			# 监听地图的拾取事件
			map.drop_thing_picked.connect(_on_map_drop_thing_picked)
			# （任务管理器）监听地图的击杀怪物事件
			# 监听玩家的进入和离开
			map.player_added.connect(_on_map_player_added)
			map.player_removed.connect(_on_map_player_removed)
			map.player_killed_monster.connect(mission_manager.data_player_killed_monster)
			# 监听npc的事件
			for npc in map.data_npcs.values():
				npc.npc_function_showed.connect(_on_map_npc_function_showed)
				# 记录NPC和地图的映射关系
				npc_map_dic[npc.id] = map_id

	log_tool.print_finish('load_map_list')
	#endregion

	# 背包加载完毕后，更新任务中的物品要求信息
	mission_manager.foreach_mission_require_collect(func(item_id: String) -> int:
		return player_manager.get_data_bag().get_item_total_count(item_id)
	)
	
	print('世界初始化完成')
	load_finished.emit()


func _add_region_info(map: DataMap, region_id: String):
	if not region_dic.has(region_id):
		region_dic[region_id] = {}
	region_dic[region_id][map.id] = map

	if not region_connects.has(region_id):
		region_connects[region_id] = []
	region_connects[region_id].append(map.id)

	# 将地图的地区信息添加到地图的地区信息列表中
	map_region_dic[map.id] = region_id


func _set_map_npc_mission_status(
	map_id: String
):
	var map = map_dic[map_id]
	for npc in map.data_npcs.values():
		# 设置NPC的任务状态
		set_npc_mission_status(npc, mission_manager, player_manager)


## 设置NPC的任务状态（进行中，可完成）
static func set_npc_mission_status(
	npc: DataNPC,
	mission_manager: MissionManager,
	player_manager: PlayerManager
):
	# 初始化状态
	npc.change_status(DataNPC.MISSION_STATUS_NONE)
	# 遍历NPC身上的任务阶段
	for phase in npc.get_mission_phases():
		if phase.is_finish():
			continue
		# 查看是否满足任务阶段对应的主任务的可见性限制
		if not is_visible_limit_met(
			player_manager.data_player,
			phase.data_mission.visible_limit,
			mission_manager
		):
			continue
		# 查看是否满足任务阶段对应的主任务
		if phase.is_first:
			npc.change_status(DataNPC.MISSION_STATUS_ACCEPTABLE)
			return
		# 是否满足任务阶段的要求，如果满足，则NPC呈现可完成状态
		if is_require_met(
			player_manager.data_player,
			player_manager.data_bag,
			phase.requires,
			mission_manager
		):
			npc.change_status(DataNPC.MISSION_STATUS_COMPLETABLE)
			return
		else:
			# 不满足要求，则NPC呈现进行中状态
			npc.change_status(DataNPC.MISSION_STATUS_DURATION)
			return


## 根据配置json里的刷新点信息，获取怪物配置信息
func get_monster_config_dic(map_monster_refresh_pos):
	var monster_config_dic = {}
	for refresh_dic in map_monster_refresh_pos:
		# 获取刷新点可能刷新的怪物ID
		var monster_list = refresh_dic["monster_list"]

		for monster_info in monster_list:
			var monster_id = monster_info["id"]
			if not monster_config_dic.has(monster_id):
				monster_config_dic[monster_id] = res_manager.get_monster_config(monster_id)
	return monster_config_dic


func get_monster_config_dic_endless():
	var monster_config_dic = {}
	for i in range(1, 10):
		var monster_id = "monster_00000" + str(i)
		var monster_config = res_manager.get_monster_config(monster_id)
		monster_config_dic[monster_id] = monster_config
	return monster_config_dic


func fill_portal_name(map: DataMap, region_id: String):
	# 遍历传送点
	for portal in map.data_portals.values():
		# 根据地图ID获取地图名称
		var target_map_id = portal.target_map_id
		var target_map_config = res_manager.get_map_config(target_map_id)
		if target_map_config != null:
			portal.target_map_name = target_map_config["name"]
			# 构建地图的连通信息
			if not region_connects.has(region_id):
				region_connects[region_id] = []
			region_connects[region_id].append([map.id, target_map_id])

		else:
			portal.disabled = true


# 创建新的本地玩家
func create_local_player(player_id: String):
	# 创建新玩家
	var data_player = player_manager.create_player(player_id,res_manager.exp_dic)

	# 给一把初始武器
	var init_weapon = dropthing_manager.create_item("weapon_000004")
	init_weapon.count = 1
	player_manager.data_bag.add_item(init_weapon)
	# # TODO 测试代码，卷轴
	# for i in range(0, 5):
	# 	var weapon = dropthing_manager.create_item("weapon_000001")
	# 	weapon.upgrade_level = i
	# 	player_manager.data_bag.add_item(weapon)
	# for i in range(0, 5):
	# 	var weapon = dropthing_manager.create_item("weapon_000003")
	# 	weapon.upgrade_level = i
	# 	player_manager.data_bag.add_item(weapon)
	# for i in range(0, 5):
	# 	var weapon = dropthing_manager.create_item("weapon_000004")
	# 	weapon.upgrade_level = i
	# 	player_manager.data_bag.add_item(weapon)
	# for i in range(0, 5):
	# 	var weapon = dropthing_manager.create_item("weapon_000005")
	# 	weapon.upgrade_level = i
	# 	player_manager.data_bag.add_item(weapon)
	
	load_local_player(data_player)


# 加载本地玩家数据
func load_local_player(data_player: DataPlayer):
	# 注入玩家数据到玩家管理器
	player_manager.load_player(data_player)
	# 注入职业名称
	data_player.job_name = res_manager.get_job_name(data_player.job_id)
	# 注入普通攻击技能
	data_player.normal_attack = player_manager.data_skill_bag.normal_attack
	# 设置默认技能
	data_player.skill = player_manager.data_skill_bag.get_skill(SingletonGame.auto_skill_id)
	# 加载永久被动技能的属性
	player_manager.load_attribute_buff_skill()
	# 重新加载角色装备
	player_manager.load_role_equip()
	# 更新初始属性
	data_player.update_attribute()
	# 从资源管理器中更新升级经验表
	data_player.init_exp_dic(res_manager.exp_dic)

	## 处理任务管理器中的任务
	#region
	## 将任务中的第一个未完成的任务阶段和NPC进行关联
	for mission in mission_manager.get_all_missions():
		for mission_phase in mission.mission_phase_list:
			if not mission_phase.is_finish():
				var npc_id = mission_phase.attach_npc_id
				var npc = map_dic[npc_map_dic[npc_id]].data_npcs[npc_id]
				npc.add_mission_phase(mission.id, mission_phase)
				# 监听任务阶段完成
				mission_phase.phase_finished.connect(_on_mission_phase_finished)
				# 监听任务阶段要求更新
				mission_phase.phase_require_updated.connect(_on_mission_phase_require_updated)
				# 只处理第一个未完成的任务阶段
				break
		# 处理任务的依赖关系
		if mission.visible_limit != null:
			for depend_mission_id in mission.visible_limit.missions:
				if mission_depend_dic.has(depend_mission_id):
					mission_depend_dic[depend_mission_id].append(mission.id)
				else:
					mission_depend_dic[depend_mission_id] = [mission.id]
		# 监听任务完成
		mission.status_changed.connect(_on_mission_status_changed)

	#endregion
	
	# 初始化玩家当前所在地图的NPC任务状态
	_set_map_npc_mission_status(data_player.map_id)
	# 监听玩家等级变化
	data_player.level_updated.connect(_on_player_level_updated)
	# 监听玩家血量变化
	data_player.hp_updated.connect(_on_player_hp_updated)
	# 监听玩机技能释放前
	data_player.before_skill_executed.connect(_on_player_before_skill_executed)
	
	# 发出玩家创建的信号
	local_player_created.emit(data_player)
	print('本地玩家加载完成:', data_player.player_name)


func get_player_map_id():
	return player_manager.data_player.map_id


func get_player_id():
	return player_manager.data_player.player_id


func get_player():
	return player_manager.data_player


func _on_map_drop_thing_picked(data_map: DataMap, drop_thing: DataBagItem):
	var result = player_manager.data_bag.add_item(drop_thing)
	if not result:
		ToastManager.add_toast("背包已满")
	else:
		data_map.remove_drop_thing(drop_thing)
		drop_thing_picked.emit(drop_thing)


func _on_map_npc_function_showed(data_npc: DataNPC):
	mission_page_tool.set_data(data_npc, mission_manager, player_manager)


func _on_map_npc_shop_showed(data_npc: DataNPC):
	shop_showed.emit(data_npc.shop_bag, player_manager.data_bag)


func _on_map_npc_mission_showed(data_npc: DataNPC):
	# 发出信号：对话框展示的信息
	mission_page_tool.set_data(data_npc, mission_manager, player_manager)


func cancel_mission(data_mission: DataMission):
	mission_manager.cancel_mission(data_mission)


func get_data_bag():
	return player_manager.data_bag


func get_data_map(map_id: String) -> DataMap:
	if region_dic[map_region_dic[map_id]].has(map_id):
		return region_dic[map_region_dic[map_id]][map_id]
	else:
		return null


func get_maps():
	return map_dic


func get_data_alchemy_bag():
	return player_manager.data_alchemy_bag


func get_data_role_equip():
	return player_manager.role_equip


func get_data_skill_bag():
	return player_manager.data_skill_bag


func get_missions():
	return mission_manager.missions_dic


func player_revive_and_punish():
	player_manager.data_player.revive()
	player_manager.data_player.punish_exp()


func _on_player_hp_updated(data_player: DataPlayer):
	var hp_warning_value = data_player.get_max_hp() * SingletonGame.hp_warning_line / 100.0
	if data_player.hp <= hp_warning_value:
		#print("玩家血量低，尝试使用药品")
		var use_success = player_manager.data_bag.find_hp_medicine_and_use()
		if not use_success and SingletonGame.is_auto:
			# 自动进入休息状态
			data_player.rest()


func _on_player_before_skill_executed(data_player: DataPlayer, _skill: DataBaseSkill):
	var mp_warning_value = data_player.get_max_mp() * SingletonGame.mp_warning_line / 100.0
	if data_player.mp <= mp_warning_value:
		print("玩家蓝量低，尝试使用药品")
		player_manager.data_bag.find_mp_medicine_and_use()


## 判断任务可见性限制是否满足
static func is_visible_limit_met(
	data_player: DataPlayer,
	visible_limit: MissionVisibleLimit,
	mission_manager: MissionManager
) -> bool:
	if visible_limit != null:
		# 等级要求
		if visible_limit.level > data_player.level:
			return false
		# 职业要求
		if not visible_limit.jobs.is_empty() and data_player.job_id not in visible_limit.jobs:
			return false
		# 任务要求
		if visible_limit.missions.size() > 0:
			for mission_id in visible_limit.missions:
				if not mission_manager.is_mission_finished(mission_id):
					return false

	return true


## 判断任务是否满足前置条件
static func is_require_met(
	data_player: DataPlayer,
	data_bag: DataBag,
	requires: Array[MissionRequire],
	mission_manager: MissionManager
) -> bool:
	for require in requires:
		if require is MissionRequireCollect:
			if not data_bag.have_item(require.item_id, require.target_count):
					return false
		elif require is MissionRequireKill:
			if require.target_count > require.kill_count:
				return false
	return true


## 当任务阶段被添加时触发的回调函数
## 主要用于处理任务阶段中的收集类型任务的监听
## 
## @param phase 被添加的任务阶段对象
func _on_mission_phase_added(phase: DataMissionPhase):
	# 检查任务阶段是否有要求
	if phase.requires != null and phase.requires.size() > 0:
		# 遍历所有要求
		for require in phase.requires:
			# 如果是收集类型的任务要求
			if require is MissionRequireCollect:
				# 监听背包物品数量变化事件
				# 当物品数量变化时,通知任务阶段更新收集进度
				player_manager.data_bag.item_count_changed.connect(phase.item_update)
				
				# 根据背包中的物品数据，更新任务阶段中的收集进度
				phase.item_update(require.item_id, player_manager.data_bag.get_item_total_count(require.item_id))

	mission_phase_added.emit(phase)


func _on_mission_phase_finished(phase: DataMissionPhase):
	# 判断阶段是否有奖励
	if phase.rewards != null and phase.rewards.size() > 0:
		_mission_rewarded(phase.rewards)
	
	## 将下一个任务阶段给到对应的NPC
	##
	# 找到对应的任务主体
	var data_mission = phase.data_mission
	# 下一个任务阶段对应的NPC
	var next_mission_phase_npc = null
	## 从mission中获取下一个未完成的任务阶段
	var next_mission_phase = data_mission.get_next_mission_phase()
	if next_mission_phase != null:
		var npc_id = next_mission_phase.attach_npc_id
		var map_id = npc_map_dic[npc_id]
		var map = map_dic[map_id]
		if map.data_npcs.has(npc_id):
			var talk_npc = map.data_npcs[npc_id]
			# 监听任务阶段完成
			next_mission_phase.phase_finished.connect(_on_mission_phase_finished)
			# 监听任务阶段添加
			next_mission_phase.phase_added.connect(_on_mission_phase_added)
			# 监听任务阶段要求更新
			next_mission_phase.phase_require_updated.connect(_on_mission_phase_require_updated)

			talk_npc.add_mission_phase(data_mission.id, next_mission_phase)
			
			# 更新NPC的任务状态
			set_npc_mission_status(talk_npc, mission_manager, player_manager)

			next_mission_phase_npc = talk_npc
	# 更新任务发起者的任务状态
	var phase_npc_id = phase.attach_npc_id
	set_npc_mission_status(
		map_dic[npc_map_dic[phase_npc_id]].data_npcs[phase_npc_id],
		mission_manager,
		player_manager
	)

	mission_phase_finished.emit(phase)

	# 查看是否有需要隐藏的NPC
	if phase.finish_hide_npc.size() > 0:
		for npc_id in phase.finish_hide_npc:
			var npc = map_dic[npc_map_dic[npc_id]].data_npcs[npc_id]
			npc.change_visible(false)
	# 查看是否有需要显示的NPC
	if phase.finish_show_npc.size() > 0:
		for npc_id in phase.finish_show_npc:
			var npc = map_dic[npc_map_dic[npc_id]].data_npcs[npc_id]
			npc.change_visible(true)

	# 如果下一个任务阶段的NPC仍然是当前NPC，则直接展示下一个任务阶段
	if next_mission_phase_npc != null:
		if next_mission_phase_npc.id == phase_npc_id:
			mission_page_tool.select_mission_phase(next_mission_phase)


func _on_mission_phase_require_updated(phase: DataMissionPhase):
	mission_phase_require_updated.emit(phase)


func alchemy_maked(data_alchemy: DataAlchemy, count: int):
	# 消耗物品
	for require in data_alchemy.requires:
		if require is MissionRequireCollect:
			player_manager.data_bag.remove_item_by_id(require.item_id, require.target_count * count)
	# 奖励物品
	for reward in data_alchemy.rewards:
		var item = dropthing_manager.create_item(reward.item_id)
		item.count = reward.count * count
		player_manager.data_bag.add_item(item)
		# 添加系统消息，这里item.count会在添加入背包后被清空，需要使用reward.count进行展示
		ToastManager.add_toast("获取物品：" + item.name + " × " + str(reward.count * count))


func _mission_rewarded(rewards: Array[MissionReward]):
	for reward in rewards:
		if reward is MissionRewardExp:
			player_manager.data_player.add_exp(reward.count,false)
		elif reward is MissionRewardMoney:
			player_manager.data_bag.add_money(reward.count)
		elif reward is MissionRewardItem:
			# 生成物品
			var item = dropthing_manager.create_item(reward.item_id)
			item.count = reward.count
			player_manager.data_bag.add_item(item)
			# 添加系统消息，这里item.count会在添加入背包后被清空，需要使用reward.count进行展示
			ToastManager.add_toast("获取物品：" + item.name + " × " + str(reward.count))
		elif reward is MissionRewardJob:
			var data_player = get_player()
			data_player.change_job(reward.job_id, reward.job_name)
			# 获取职业技能
			var job_skills = res_manager.get_job_skills(reward.job_id)
			# 将职业技能添加到技能背包中
			var skill_bag = player_manager.data_skill_bag
			for skill_id in job_skills:
				var skill = skill_bag.create(skill_id)
				skill_bag.add_skill(reward.job_name, skill)
		elif reward is MissionRewardAlchemy:
			player_manager.data_alchemy_bag.add_alchemy(reward.alchemy_id)
			# 更新炼金配方中的物品要求数量信息
			player_manager.data_alchemy_bag.update_mission_require_collect(func(item_id: String) -> int:
				return player_manager.get_data_bag().get_item_total_count(item_id)
			)
		elif reward is MissionRewardSkill:
			var skill_bag = player_manager.data_skill_bag
			var skill = skill_bag.create(reward.skill_id)
			skill_bag.add_skill(reward.skill_phase, skill)
			# 设置技能等级为1
			skill.add_level(1)


func _on_player_level_updated(data_player: DataPlayer):
	# 角色等级提升时，遍历玩家所在地图的所有NPC
	var map_id = data_player.map_id
	var map = map_dic[map_id]
	# 遍历地图中的每个NPC
	for npc in map.data_npcs.values():
		# 重新设置NPC的任务状态
		set_npc_mission_status(npc, mission_manager, player_manager)
	

func get_all_missions():
	return mission_manager.get_all_missions()


func _on_mission_status_changed(data_mission: DataMission):
	if data_mission.is_finish():
		# 如果任务完成，则触发依赖任务的可见性限制
		if mission_depend_dic.has(data_mission.id):
			for depend_mission_id in mission_depend_dic[data_mission.id]:
				var depend_mission = mission_manager.get_data_mission(depend_mission_id)
				if depend_mission != null:
					_update_mission_npc_status(depend_mission)
		# 如果任务是可重复的，则完成后继续将任务重置为未开始状态
		if data_mission.repeatable:
			# 重置任务状态
			data_mission.reset()
			# 更新NPC的任务状态
			_update_mission_npc_status(data_mission)
		

func _update_mission_npc_status(data_mission: DataMission):
	# 通过任务的第一个阶段，获取NPC
	var npc_id = data_mission.mission_phase_list[0].attach_npc_id
	var npc = map_dic[npc_map_dic[npc_id]].data_npcs[npc_id]
	# 设置NPC的任务状态
	set_npc_mission_status(npc, mission_manager, player_manager)

	# 由于任务阶段处在进行中状态时，任务要求才会实时更新数据。
	# 因此任务阶段状态刚刚变更时，需要手动更新一次任务要求的数据
	for phase in data_mission.mission_phase_list:
		if phase.status == DataMissionPhase.STATUS_IN_PROGRESS:
			for require in phase.requires:
				phase.item_update(require.item_id, player_manager.data_bag.get_item_total_count(require.item_id))


func _on_map_player_added(data_map: DataMap, data_player: DataPlayer):
	print('player_added:', data_player.player_id)
	# 刷新NPC的任务状态
	_set_map_npc_mission_status(data_player.map_id)


func _on_map_player_removed(data_map: DataMap, data_player: DataPlayer):
	print('player_removed:', data_player.player_id)
