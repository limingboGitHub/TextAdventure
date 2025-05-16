extends Node2D

## 根据DataWorld世界的数据更新对应的UI显示

var data_world = DataWorld.new()

# 玩家场景字典 key: player_id, value: player_scene
var player_scene_dic: Dictionary = {}
# 数据保存工具
var save_tool: BaseCacheTool = FileCacheTool.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	data_world.load_res_finished.connect(_on_load_res_finished)
	data_world.load_finished.connect(on_load_finished)
	data_world.local_player_created.connect(_on_local_player_created)
	data_world.start()

	# 监听Toast
	ToastManager.toast_added.connect(_on_toast_added)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _exit_tree() -> void:
	_game_save()


func _on_load_res_finished():
	var player_id = SingletonGame.start_role_id
	# 存档id目前使用的玩家id
	var save_id = player_id
	#region 资源加载完毕，开始加载游戏世界数据
	# 加载全局配置信息
	save_tool.load_singleton_game(save_id)
	# 从缓存中获取角色信息
	var data_player = save_tool.load_data_player(player_id)
	# 从缓存加载玩家背包
	var data_bag = save_tool.load_data_bag(save_id)
	# 加载装备数据
	var data_role_equip = save_tool.load_data_role_equip(save_id)
	# 加载技能背包
	var data_skill_bag = save_tool.load_data_skill_bag(save_id)
	# 加载地图数据
	var map_dic = save_tool.load_maps(save_id)
	# 加载任务数据
	var mission_dic = save_tool.load_missions(save_id)
	# 加载炼金背包数据
	var data_alchemy_bag = save_tool.load_data_alchemy_bag(save_id)

	data_world.load_data_world(data_bag, data_role_equip, data_skill_bag, map_dic, mission_dic, data_alchemy_bag)
	#endregion
	# 加载玩家
	data_world.load_local_player(data_player)


func on_load_finished():
	print('on_load_finished')
	# 游戏世界数据加载完毕，根据加载好的数据，实例化地图场景
	for map in data_world.map_dic.values():
		var map_scene = SingletonGameScenePre.MapScene.instantiate()
		map_scene.name = map.id
		# 给地图场景注入数据
		map_scene.data_map = map
		# 地图加载后，默认隐藏显示，只展示当前玩家所在地图
		map_scene.scene_hide()
		# 监听传送点生成完毕事件
		map_scene.portal_updated.connect(_on_portal_updated)
		# 监听角色传送事件
		map_scene.invoked_portal.connect(_on_player_invoked_portal)
		# 监听角色攻击目标转换
		map_scene.attack_target_changed.connect(_on_attack_target_changed)
		# 监听地图掉落展示事件
		map_scene.map_drop_showed.connect(_on_map_drop_showed)
		if map.is_endless:
			# 监听无尽之塔退出事件
			map_scene.endless_exit.connect(_on_endless_exit)
		# 监听地图探索完毕事件
		map.map_explored.connect(_on_map_explored)
		# 监听玩家加入地图事件
		map.player_added.connect(_on_map_player_added)
		# 监听玩家离开地图事件
		map.player_removed.connect(_on_map_player_removed)
		# 把地图场景添加到当前场景
		$Maps.add_child(map_scene)
	
	# 更新地图绘制
	$CanvasLayer/UI/MapGraph.init_maps(
		data_world.region_dic,
		data_world.region_connects,
		data_world.map_region_dic,
		data_world.region_name_dic
	)

	# 初始化背包
	$CanvasLayer/UI/Dialog/BagDialog.set_bag(data_world.get_data_bag())
	# 监听背包物品点击事件
	$CanvasLayer/UI/Dialog/BagDialog.item_showed.connect(_on_item_showed)
	# 初始化角色装备栏
	$CanvasLayer/UI/Dialog/RoleEquipDialog.set_data_role_equip(data_world.get_data_role_equip())
	# 监听角色装备栏装备展示事件
	$CanvasLayer/UI/Dialog/RoleEquipDialog.item_showed.connect(_on_item_showed)
	# 初始化技能栏
	$CanvasLayer/UI/Dialog/SkillDialog.set_data_skill_bag(data_world.get_data_skill_bag())
	# 初始化怪物手册
	$CanvasLayer/UI/Dialog/MonsterInfoDialog.init(data_world.res_manager, data_world.dropthing_manager, data_world.map_dic)
	# 监听怪物手册掉落物展示事件
	$CanvasLayer/UI/Dialog/MonsterInfoDialog.item_show_bt_pressed.connect(_on_item_showed)
	# 初始化任务对话框
	$CanvasLayer/UI/Dialog/MissionDialog.init(data_world.get_all_missions())
	# 初始化炼金配方对话框
	$CanvasLayer/UI/Dialog/AlchemyDialog.set_data_alchemy_bag(data_world.get_data_alchemy_bag())
	# 初始化消耗品状态栏
	$CanvasLayer/UI/ConsumeStatus.init_data(data_world.get_data_bag())
	# 初始化炼金消耗品状态栏
	$CanvasLayer/UI/AlchemyStatus.init_data(data_world.get_data_bag())
	# 初始化统计信息
	$CanvasLayer/UI/StatsInfoControl.init()
	# 监听NPC对话框
	_set_npc_dialog_listener()
	# 监听商店展示事件
	data_world.shop_showed.connect(_on_npc_shop_showed)
	# 监听NPC任务对话框
	data_world.mission_page_tool.message_showed.connect(_on_message_showed)
	data_world.mission_page_tool.dialog_hided.connect(_on_npc_talk_dialog_hided)
	# 监听任务的变化
	data_world.mission_phase_added.connect(_on_mission_phase_added)
	data_world.mission_phase_finished.connect(_on_mission_phase_finished)
	data_world.mission_phase_require_updated.connect(_on_mission_phase_require_updated)
	# 监听物品拾取事件
	data_world.drop_thing_picked.connect(_on_drop_thing_picked)

	# 监听卷轴使用相关
	# 监听背包的卷轴准备使用事件
	data_world.get_data_bag().scroll_ready_used.connect(_on_scroll_ready_used)
	# 监听卷轴使用成功事件
	data_world.get_data_bag().scroll_used_success.connect(_on_scroll_used_success)
	# 监听卷轴使用失败事件
	data_world.get_data_bag().scroll_used_failed.connect(_on_scrolld_use_failed)
	# 监听卷轴使用对话框的装备展示事件
	$CanvasLayer/UI/Dialog/ScrollUseDialog.item_show_bt_pressed.connect(_on_item_showed)
	# 监听卷轴使用对话框的装备使用事件
	$CanvasLayer/UI/Dialog/ScrollUseDialog.item_use_bt_pressed.connect(_on_scroll_used)
	# 监听技能使用事件
	$CanvasLayer/UI/Dialog/SkillDialog.skill_used.connect(_on_skill_used)
	# 监听技能激活事件
	$CanvasLayer/UI/Dialog/SkillDialog.skill_active_toggled.connect(_on_skill_active_toggled)
	# 监听炼金制作事件
	$CanvasLayer/UI/Dialog/AlchemyDialog.alchemy_maked.connect(_on_alchemy_maked)
	# 监听地图选择事件
	$CanvasLayer/UI/Dialog/MapSelectDialog.map_selected.connect(_move_to_target_map)


func _on_local_player_created(data_player: DataPlayer):
	# 初始化玩家装备
	data_player.init_role_equip(data_world.get_data_role_equip())
	# 实例化玩家场景
	_on_player_scene_created(data_player)
	# 玩家进入地图
	data_world.get_data_map(data_player.map_id).add_player(data_player)
	# 更新玩家当前所在地图
	$CanvasLayer/UI/MapGraph.update_current_map(data_player.map_id)
	# 监听地图选择事件
	$CanvasLayer/UI/MapGraph.map_selected.connect(_on_map_selected)

	# 监听玩家状态变化
	data_player.hp_updated.connect(_on_player_hp_updated)
	data_player.mp_updated.connect(_on_player_mp_updated)
	data_player.exp_updated.connect(_on_player_exp_updated)
	data_player.level_updated.connect(_on_player_level_updated)
	data_player.role_dead.connect(_on_player_dead)
	data_player.job_changed.connect(_on_player_job_changed)
	data_player.damage_caused.connect(_on_player_damage_caused)
	data_player.hp_value_changed.connect(_on_player_hp_value_changed)
	data_player.mp_value_changed.connect(_on_player_mp_value_changed)
	# 监听buff添加
	data_player.buff_added.connect(_on_buff_added)

	# 显示角色状态信息
	$CanvasLayer/UI/StatusBar.show()
	$CanvasLayer/UI/Dialog/PlayerAttriDialog.set_player(data_player)
	# 初始化更新角色状态
	_on_player_hp_updated(data_player)
	_on_player_mp_updated(data_player)
	_update_player_exp_bar(data_player)
	_on_player_level_updated(data_player)
	_on_player_job_changed(data_player)
	
	# 显示操作界面
	$CanvasLayer/UI/ButtonControl.show()
	# 初始化技能快捷栏
	$CanvasLayer/UI/SkillFastKey.set_data(
		data_world.get_data_skill_bag(),
		data_world.get_player().skill
	)

	# 监听挂机设置保存
	$CanvasLayer/UI/Dialog/AutoSettingDialog.setting_saved.connect(_on_setting_saved)
	# 监听技能快捷键选择
	$CanvasLayer/UI/SkillFastKey.skill_selected.connect(_on_skill_fast_key_selected)
	# 监听怪物手册按钮点击事件
	$CanvasLayer/UI/Dialog/OtherFunctionDialog.monster_info_bt_pressed.connect(_on_monster_info_bt_pressed)


func _on_player_scene_created(_data_player: DataPlayer):
	# 实例化玩家场景
	var player_scene = SingletonGameScenePre.PlayerScene.instantiate()
	player_scene.name = _data_player.player_id
	player_scene.data_player = _data_player
	# 更新角色装备
	var role_equip = data_world.get_data_role_equip()
	if role_equip.has_equip(DataEquip.TYPE_WEAPON):
		player_scene.update_role_equip(role_equip.get_equip(DataEquip.TYPE_WEAPON))
	# 把玩家场景添加到玩家场景字典
	player_scene_dic[_data_player.player_id] = player_scene


func _on_exit_game_bt_pressed() -> void:
	# 退出游戏
	get_tree().quit()


#func _on_player_enter_bt_pressed() -> void:
#	var player_id = "123456789"
#	# 先从缓存中获取角色信息
#	var data_player = save_tool.load_data_player(player_id)
#	if data_player == null:
#		data_world.create_local_player(player_id)
#	else:
#		data_world.load_local_player(data_player)
	
#	$CanvasLayer/UI/Login/PlayerEnterBt.hide()


func _on_portal_updated(portal: DataPortal, map_scene: Node2D):
	print("_on_portal_updated:", portal.target_map_name, " map:", map_scene.name)
	# 判断传送点目标地图是否探索过，来决定展示传送点的名称
	var target_map = data_world.get_data_map(portal.target_map_id)
	if target_map != null:
		map_scene.update_portal_name(portal, target_map.is_explored)


func _on_player_invoked_portal(portal: DataPortal, map_scene: Node2D):
	# print("_on_player_invoked_portal:",portal.target_map_name," map:",map_scene.name)
	# 检查传送点是否需要击杀怪物条件
	if portal.need_kill_monster_count > 0:
		# 获取当前地图的击杀数量
		var map_id = data_world.get_player_map_id()
		var data_map = data_world.get_data_map(map_id)
		if data_map != null:
			if data_map.get_total_kill_monster_count() < portal.need_kill_monster_count:
				# 显示条件不满足提示
				ToastManager.add_toast("该地区太危险了，需要继续在当前地区提升实力")
				return
	
	# 传送到目标地图
	_move_to_target_map(portal.target_map_id)


func _move_to_target_map(target_map_id: String):
	# 如果玩家处于自动战斗状态，则关闭自动战斗状态
	if SingletonGame.is_auto:
		$CanvasLayer/UI/ButtonControl/AutoBt.set_pressed(false)
	
	var data_player = data_world.get_player()
	# 将玩家从地图移除
	data_world.get_data_map(data_player.map_id).remove_player(data_player.player_id)

	# 把玩家添加到新地图
	data_world.get_data_map(target_map_id).add_player(data_player)
	
	# 更新地图
	$CanvasLayer/UI/MapGraph.update_current_map(data_player.map_id)


func _action_presse(action: String, pressed: bool):
	var event = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _on_attack_bt_button_down() -> void:
	_action_presse("attack", true)


func _on_attack_bt_button_up() -> void:
	_action_presse("attack", false)


func _process_local_player_attack():
	pass


func _on_player_hp_updated(data_role: DataRole):
	$CanvasLayer/UI/StatusBar/Bar/HpBar/ColorBar.set_value(
			data_role.attribute.final_details.max_hp,
			data_role.hp
	)


func _on_player_mp_updated(data_role: DataRole):
	$CanvasLayer/UI/StatusBar/Bar/MpBar/ColorBar.set_value(
			data_role.attribute.final_details.max_mp,
			data_role.mp
	)


func _on_player_exp_updated(data_role: DataRole, value: int, increase_value: int):
	_update_player_exp_bar(data_role)
	# 添加经验值变化的消息
	if value >= 0:
		if increase_value > 0:
			$CanvasLayer/UI/MsgControl.add_msg("经验值 +" + str(value) + "(+" + str(increase_value) + ")")
		else:
			$CanvasLayer/UI/MsgControl.add_msg("经验值 +" + str(value))
	else:
		$CanvasLayer/UI/MsgControl.add_msg("经验值 " + str(value))


func _update_player_exp_bar(data_role: DataRole):
	# 更新经验条
	$CanvasLayer/UI/StatusBar/Bar/ExpBar/ColorBar.set_value(data_role.max_exp, data_role.exp)


func _on_player_level_updated(data_player: DataPlayer):
	var max_level = "(满级)" if data_player.is_max_level() else ""
	$CanvasLayer/UI/StatusBar/PlayerInfo/Level/Value.text = str(data_player.level) + max_level
	# 升级时同时更新经验值
	_update_player_exp_bar(data_player)


func _on_auto_bt_pressed() -> void:
	pass # Replace with function body.


func _on_auto_bt_toggled(toggled_on: bool) -> void:
	# 如果玩家处在休息状态，则停止休息
	if toggled_on:
		if data_world.get_player().is_resting:
			data_world.get_player().stop_rest()
		
	# 设置自动战斗状态
	SingletonGame.is_auto = toggled_on


func _on_player_info_pressed() -> void:
	if $CanvasLayer/UI/Dialog/PlayerAttriDialog.visible:
		$CanvasLayer/UI/Dialog/PlayerAttriDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/PlayerAttriDialog)


func _on_bag_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/BagDialog.visible:
		$CanvasLayer/UI/Dialog/BagDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/BagDialog)


func _on_role_equip_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/RoleEquipDialog.visible:
		$CanvasLayer/UI/Dialog/RoleEquipDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/RoleEquipDialog)


func _on_player_dead(data_role: DataRole):
	_dialog_show($CanvasLayer/UI/Dialog/DeadDialog)


func _on_player_job_changed(data_player: DataPlayer):
	$CanvasLayer/UI/StatusBar/PlayerInfo/Job.text = data_player.job_name


func _on_player_damage_caused(_data_player: DataPlayer,damage: DataDamage):
	$CanvasLayer/UI/StatsInfoControl.player_damage_caused(damage)


func _on_player_hp_value_changed(_data_player: DataPlayer, change_value: int):
	if change_value < 0:
		$CanvasLayer/UI/StatsInfoControl.player_hp_reduce(-change_value)


func _on_player_mp_value_changed(_data_player: DataPlayer, change_value: int):
	if change_value < 0:
		$CanvasLayer/UI/StatsInfoControl.player_mp_reduce(-change_value)


func _on_revive_bt_pressed() -> void:
	$CanvasLayer/UI/Dialog/DeadDialog.hide()
	data_world.player_revive_and_punish()
	# 复活后，自动战斗状态关闭
	$CanvasLayer/UI/ButtonControl/AutoBt.set_pressed(false)
	# 更新角色信息
	var data_player = data_world.get_player()
	_on_player_hp_updated(data_player)
	_on_player_mp_updated(data_player)
	# 回到当前地区的主城镇
	_back_to_main_town()


func _back_to_main_town():
	var data_player = data_world.get_player()
	var current_map = data_world.get_data_map(data_player.map_id)
	var region_id = data_world.map_region_dic.get(current_map.id)
	if region_id and data_world.region_dic.has(region_id):
		for map in data_world.region_dic[region_id].values():
			if map.main_town:
				_move_to_target_map(map.id)
				break


func _on_skill_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/SkillDialog.visible:
		$CanvasLayer/UI/Dialog/SkillDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/SkillDialog)


func _on_auto_setting_bt_pressed() -> void:
	$CanvasLayer/UI/Dialog/AutoSettingDialog.visible = !$CanvasLayer/UI/Dialog/AutoSettingDialog.visible
	if $CanvasLayer/UI/Dialog/AutoSettingDialog.visible:
		$CanvasLayer/UI/Dialog/AutoSettingDialog.set_data(
			SingletonGame.hp_warning_line,
			SingletonGame.mp_warning_line
		)


func _on_setting_saved(
	hp_warning_line: int,
	mp_warning_line: int
):
	SingletonGame.hp_warning_line = hp_warning_line
	SingletonGame.mp_warning_line = mp_warning_line


func _on_skill_fast_key_selected(skill: DataBaseSkill):
	SingletonGame.auto_skill_id = skill.id
	data_world.get_player().skill = skill


func _on_rest_bt_pressed() -> void:
	data_world.get_player().rest()
	# 如果在挂机状态，则关闭挂机状态
	if SingletonGame.is_auto:
		$CanvasLayer/UI/ButtonControl/AutoBt.set_pressed(false)


func _on_attack_target_changed(attack_target):
	# 如果角色攻击目标转变，不为空，则自动开始挂机
	if attack_target:
		$CanvasLayer/UI/ButtonControl/AutoBt.set_pressed(true)


func _on_toast_added(msg: String):
	$CanvasLayer/UI/ToastControl.add_toast(msg)
	

func _on_npc_shop_showed(shop_bag: DataBag, player_bag: DataBag):
	$CanvasLayer/UI/Dialog/ShopDialog.set_bag(shop_bag, player_bag, data_world.dropthing_manager)
	# 监听物品展示
	$CanvasLayer/UI/Dialog/ShopDialog.item_show_pressed.connect(_on_item_showed)


## 展示任务对话框的消息
##
## @param selections 类型为Array[DataMissionPhase/DataBag/DataTeleport]，可空类型
## @param requires 类型为Array[MissionRequire]，可空类型
## @param rewards 类型为Array[MissionReward]，可空类型
func _on_message_showed(
	title: String,
	message: String,
	ok_bt_text: String,
	selections,
	requires,
	rewards
):
	$CanvasLayer/UI/Dialog/NpcTalkDialog.set_player_name(data_world.get_player().player_name)
	# 展示NPC名称
	$CanvasLayer/UI/Dialog/NpcTalkDialog.set_title(title)
	# 展示NPC默认对话
	$CanvasLayer/UI/Dialog/NpcTalkDialog.set_message(message)
	# 【确认】按钮
	$CanvasLayer/UI/Dialog/NpcTalkDialog.show_ok_bt(ok_bt_text)
	# 任务选项
	$CanvasLayer/UI/Dialog/NpcTalkDialog.set_selections(selections)
	# 任务要求
	if requires != null and requires.size() > 0:
		$CanvasLayer/UI/Dialog/NpcTalkDialog.set_mission_requires(requires)
	# 任务奖励
	if rewards != null and rewards.size() > 0:
		$CanvasLayer/UI/Dialog/NpcTalkDialog.set_mission_rewards(rewards)
	if (requires == null or requires.size() == 0) and (rewards == null or rewards.size() == 0):
		$CanvasLayer/UI/Dialog/NpcTalkDialog.hide_require_or_reward()
	_dialog_show($CanvasLayer/UI/Dialog/NpcTalkDialog)


func _set_npc_dialog_listener():
	# 监听任务选项点击
	$CanvasLayer/UI/Dialog/NpcTalkDialog.mission_phase_selection_pressed.connect(
		_on_mission_phase_selection_pressed
	)
	$CanvasLayer/UI/Dialog/NpcTalkDialog.bag_selection_pressed.connect(
		_on_bag_selection_pressed
	)
	$CanvasLayer/UI/Dialog/NpcTalkDialog.teleport_selection_pressed.connect(
		_on_teleport_selection_pressed
	)
	# 监听按钮
	$CanvasLayer/UI/Dialog/NpcTalkDialog.ok_bt_pressed.connect(_on_mission_ok_bt_pressed)


func _on_mission_phase_selection_pressed(data_mission_phase: DataMissionPhase):
	print("_on_mission_phase_selection_pressed:", data_mission_phase.data_mission.id)
	data_world.mission_page_tool.select_mission_phase(data_mission_phase)


func _on_bag_selection_pressed(bag: DataBag):
	# 展示商店
	_on_npc_shop_showed(bag, data_world.get_data_bag())
	# 隐藏对话框
	_on_npc_talk_dialog_hided()


func _on_teleport_selection_pressed(data_teleport: DataTeleport):
	# 隐藏对话框
	_on_npc_talk_dialog_hided()
	# 展示地图传送窗口
	var maps = []
	for map_id in data_teleport.map_id_list:
		var data_map = data_world.get_data_map(map_id)
		maps.append(data_map)
	$CanvasLayer/UI/Dialog/MapSelectDialog.set_data(maps)
	_dialog_show($CanvasLayer/UI/Dialog/MapSelectDialog)
	


func _on_mission_ok_bt_pressed():
	data_world.mission_page_tool.ok_button_pressed()


func _on_npc_talk_dialog_hided():
	$CanvasLayer/UI/Dialog/NpcTalkDialog.hide()


func _on_mission_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/MissionDialog.visible:
		$CanvasLayer/UI/Dialog/MissionDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/MissionDialog)


func _on_mission_phase_added(data_mission_phase: DataMissionPhase):
	print("_on_mission_phase_added:", data_mission_phase.name)
	var mission_dialog = $CanvasLayer/UI/Dialog/MissionDialog
	if not mission_dialog.has_mission(data_mission_phase.data_mission.id):
		mission_dialog.add_mission(data_mission_phase.data_mission)
	mission_dialog.mission_phase_updated(data_mission_phase)


func _on_mission_phase_finished(data_mission_phase: DataMissionPhase):
	print("_on_mission_phase_finished:", data_mission_phase.name)
	$CanvasLayer/UI/Dialog/MissionDialog.mission_phase_updated(data_mission_phase)


func _on_mission_phase_require_updated(data_mission_phase: DataMissionPhase):
	print("_on_mission_phase_require_updated:", data_mission_phase.name)
	$CanvasLayer/UI/Dialog/MissionDialog.mission_phase_require_updated(data_mission_phase)
	# 如果所有要求都满足了，则Toast提示
	if data_mission_phase.is_all_require_finish():
		ToastManager.add_toast("【" + data_mission_phase.name + "】任务完成")


func _on_drop_thing_picked(drop_thing: DataBagItem):
	$CanvasLayer/UI/MsgControl.add_msg("获得 " + drop_thing.name)


func _on_map_close_bt_pressed() -> void:
	$CanvasLayer/UI/MapGraph.hide()


func _on_role_bt_pressed() -> void:
	_on_player_info_pressed()


func _on_pick_up_bt_button_down() -> void:
	_action_presse("pick", true)


func _on_pick_up_bt_button_up() -> void:
	_action_presse("pick", false)


func _on_debug_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/DebugDialog.visible:
		$CanvasLayer/UI/Dialog/DebugDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/DebugDialog)


func _on_debug_dialog_debug_exp_added(value: int) -> void:
	data_world.get_player().add_exp(value)


func _on_debug_dialog_debug_money_added(value: int) -> void:
	data_world.get_data_bag().add_money(value)


func _on_debug_dialog_debug_item_added(item_id: String) -> void:
	var item = data_world.dropthing_manager.create_item(item_id)
	var result = data_world.get_data_bag().add_item(item)
	if not result:
		ToastManager.add_toast("背包已满")


func _on_buff_added(data_buff: DataBuff):
	print("_on_buff_added:", data_buff.id)
	if data_buff.duration > 0:
		$CanvasLayer/UI/StatusBar/BuffShow.add_buff(data_buff)


func _on_item_showed(ui: BagItem):
	var item = ui.data_bag_item
	if not $CanvasLayer/UI/Dialog/ItemInfoDialog.visible:
		_dialog_show($CanvasLayer/UI/Dialog/ItemInfoDialog)
	elif $CanvasLayer/UI/Dialog/ItemInfoDialog.get_item() == item:
		# 相同物品再次点击，则隐藏弹窗
		$CanvasLayer/UI/Dialog/ItemInfoDialog.hide()

	# 设置弹窗的位置
	# 弹窗的x坐标范围是0-(648-300)
	$CanvasLayer/UI/Dialog/ItemInfoDialog.position = Vector2(
		min(ui.global_position.x, 348),
		ui.global_position.y + 50
	)

	$CanvasLayer/UI/Dialog/ItemInfoDialog.set_item(item)


func _on_scroll_ready_used(item: DataConsume, equips: Array[DataEquip]):
	# print("_on_scroll_ready_used:", item.name, " equips:", equips)
	# 展示卷轴使用对话框
	_dialog_show($CanvasLayer/UI/Dialog/ScrollUseDialog)
	$CanvasLayer/UI/Dialog/ScrollUseDialog.set_data(item, equips)


func _on_scroll_used(ui: BagItem, scroll: DataConsume):
	print("_on_scroll_used:", scroll.name)
	if ui.data_bag_item.can_upgrade():
		if scroll.count > 0:
			data_world.get_data_bag().use_scroll(scroll, ui.data_bag_item)
			# 如果卷轴数量为0，则隐藏卷轴使用对话框
			if data_world.get_data_bag().get_item_total_count(scroll.id) <= 0:
				$CanvasLayer/UI/Dialog/ScrollUseDialog.clear()
	else:
		ToastManager.add_toast("强化次数已达上限")


func _on_scroll_used_success(item: DataConsume, equip: DataEquip):
	print("_on_scroll_used_success:", item.name, " equip:", equip.name)
	# 隐藏卷轴使用对话框
	$CanvasLayer/UI/Dialog/ScrollUseDialog.hide()
	
	ToastManager.add_toast("强化成功")


func _on_scrolld_use_failed(item: DataConsume, equip: DataEquip):
	print("_on_scrolld_use_failed:", item.name, " equip:", equip.name)
	# 隐藏卷轴使用对话框
	$CanvasLayer/UI/Dialog/ScrollUseDialog.hide()
	
	ToastManager.add_toast("强化失败")


func _on_other_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/OtherFunctionDialog.visible:
		$CanvasLayer/UI/Dialog/OtherFunctionDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/OtherFunctionDialog)


func _on_monster_info_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/MonsterInfoDialog.visible:
		$CanvasLayer/UI/Dialog/MonsterInfoDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/MonsterInfoDialog)


func _on_map_explored(data_map: DataMap):
	$CanvasLayer/UI/Dialog/MonsterInfoDialog.update_map()


func _on_map_player_added(data_map: DataMap, data_player: DataPlayer):
	var map_scene = $Maps.get_node(data_map.id)
	var player_scene = player_scene_dic[data_player.player_id]
	map_scene.add_player_scene(data_player, player_scene)


func _on_map_player_removed(data_map: DataMap, data_player: DataPlayer):
	var map_scene = $Maps.get_node(data_map.id)
	map_scene.remove_player_scene(data_player)


func _on_map_drop_showed(data_map: DataMap):
	$CanvasLayer/UI/Dialog/MonsterInfoDialog.show_map_drop(data_map.name)
	_dialog_show($CanvasLayer/UI/Dialog/MonsterInfoDialog)


# 展示对话框，同时将对话框的显示层级设置为最高
func _dialog_show(dialog: Control):
	dialog.show()
	dialog.move_to_front()
		

func _on_save_game_bt_pressed():
	_game_save()

	ToastManager.add_toast("游戏保存成功")


func _game_save():
	var save_id = data_world.get_player().player_id
	save_tool.save(data_world, save_id)


func _on_map_selected(map_id: String) -> void:
	print("_on_map_selected:", map_id)
	# 获取玩家当前所在地图的传送点
	var current_map = data_world.get_data_map(data_world.get_player().map_id)
	var portals_dic = current_map.get_portals()
	for portal in portals_dic.values():
		if portal.target_map_id == map_id:
			# 传送到目标地图
			_on_player_invoked_portal(portal, null)
			return

	# 不是玩家当前所在地图传送点可达的地图
	# 则进一步判断，如果未探索过则无法直达
	var target_map = data_world.get_data_map(map_id)
	if not target_map.is_explored:
		ToastManager.add_toast("目标尚未探索，请先步行探索")
		return
	else:
		# 传送到目标地图
		_move_to_target_map(map_id)


func _on_big_map_bt_pressed() -> void:
	$CanvasLayer/UI/MapGraph.visible = !$CanvasLayer/UI/MapGraph.visible


func _on_skill_used(data_skill: DataBaseSkill) -> void:
	if data_skill is DataBuffSkill:
		var data_buff = data_skill.create_buff()
		data_world.get_player().add_buff(data_buff)


func _on_skill_active_toggled(data_skill: DataEffectBuffSkill, active: bool) -> void:
	data_world.get_player().set_buff_active(data_skill.id, active)


func _on_game_save_timer_timeout() -> void:
	_game_save()


func _on_alchemy_bt_pressed() -> void:
	if $CanvasLayer/UI/Dialog/AlchemyDialog.visible:
		$CanvasLayer/UI/Dialog/AlchemyDialog.hide()
	else:
		_dialog_show($CanvasLayer/UI/Dialog/AlchemyDialog)


func _on_alchemy_maked(data_alchemy: DataAlchemy, count: int) -> void:
	data_world.alchemy_maked(data_alchemy, count)


func _on_endless_exit():
	_back_to_main_town()


func _on_debug_dialog_all_consume_added() -> void:
	var all_scrolls = [
		"consume_002101",
		"consume_002102",
		"consume_002103",
		"consume_002104",
		"consume_002105",
		"consume_002106",
		"consume_002114",
		"consume_002115",
		"consume_002116",
		"consume_002117",
		"consume_002118",
		"consume_002107",
		"consume_002108",
		"consume_002109",
		"consume_002111",
		"consume_002112",
		"consume_002113",
		"consume_002119",
		"consume_002120",
		"consume_002121",
		"consume_002122",
		"consume_002012",
	]
	for scroll_id in all_scrolls:
		var item = data_world.dropthing_manager.create_item(scroll_id)
		item.count = 999
		var result = data_world.get_data_bag().add_item(item)
		if not result:
			ToastManager.add_toast("背包已满")


func _on_debug_dialog_all_job_1_added() -> void:
	var all_equipments = [
		"weapon_000020",
		"cap_000008",
		"lower_body_000009",
		"shoes_000009",
		"upper_body_000009",
	]
	for equipment_id in all_equipments:
		var item = data_world.dropthing_manager.create_item(equipment_id)
		var result = data_world.get_data_bag().add_item(item)
		if not result:
			ToastManager.add_toast("背包已满")


func _on_debug_dialog_all_job_2_added() -> void:
	var all_equipments = [
		"weapon_001011",
		"cap_001007",
		"lower_body_001007",
		"shoes_001007",
		"upper_body_001007",
	]
	for equipment_id in all_equipments:
		var item = data_world.dropthing_manager.create_item(equipment_id)
		var result = data_world.get_data_bag().add_item(item)
		if not result:
			ToastManager.add_toast("背包已满")


func _on_debug_dialog_all_job_3_added() -> void:
	var all_equipments = [
		"weapon_002009",
		"cap_002005",
		"lower_body_002005",
		"shoes_002005",
		"upper_body_002005",
	]
	for equipment_id in all_equipments:
		var item = data_world.dropthing_manager.create_item(equipment_id)
		var result = data_world.get_data_bag().add_item(item)
		if not result:
			ToastManager.add_toast("背包已满")


func _on_role_info_bt_pressed() -> void:
	_on_player_info_pressed()
