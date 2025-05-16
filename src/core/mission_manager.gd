class_name MissionManager

## 管理任务信息、进度、状态等。

# 任务表
# key:任务id value:任务DataMission
var missions_dic: Dictionary = {}

var res_manager: ResManager


func init_missions(res_manager: ResManager, mission_dic_from_cache: Dictionary):
	self.res_manager = res_manager
	# 读取任务配置
	var mission_config_dic = res_manager.mission_dic
	# 生成任务映射表
	for mission_id in mission_config_dic.keys():
		var mission_info = mission_config_dic[mission_id]
		if not mission_info["enable"]:
			continue

		# 生成任务表
		var mission = _create_mission(
						mission_id,
						mission_info
					)
		# 尝试从缓存中加载任务相关信息
		if mission_dic_from_cache.has(mission_id):
			mission.load(mission_dic_from_cache[mission_id])
		# 将任务添加到任务表
		missions_dic[mission_id] = mission


func accept_mission(data_mission: DataMission):
	data_mission.change_status(DataMission.STATUS_IN_PROGRESS)


func cancel_mission(data_mission: DataMission):
	data_mission.change_status(DataMission.STATUS_NOT_START)


func finish_mission(data_mission: DataMission):
	data_mission.change_status(DataMission.STATUS_FINISH)


func is_mission_finished(mission_id: String) -> bool:
	if missions_dic.has(mission_id):
		var mission = missions_dic[mission_id]
		return mission.is_finish()
	return false


func get_data_mission(mission_id: String) -> DataMission:
	if missions_dic.has(mission_id):
		return missions_dic[mission_id]
	return null


func get_all_missions() -> Array:
	return missions_dic.values()


func _create_mission(mission_id, mission_info) -> DataMission:
	var mission = DataMission.new()
	mission.id = mission_id
	mission.name = mission_info["name"]
	# 任务可见要求
	if mission_info.has("visible_limit"):
		var visible_limit_info = mission_info["visible_limit"]
		mission.visible_limit = get_visible_limit_from_config(visible_limit_info)
	# 任务是否可重复
	if mission_info.has("repeatable"):
		mission.repeatable = bool(mission_info["repeatable"])
	# 任务阶段列表
	if mission_info.has("mission_phase_list"):
		var mission_phase_list_info = mission_info["mission_phase_list"]
		# 标记首个任务阶段，用于NPC任务阶段显示的区分
		var is_first: bool = true
		for mission_phase_info in mission_phase_list_info:
			var mission_phase = _get_data_mission_phase(mission_phase_info)
			# 设置任务阶段ID
			mission_phase.id = str(mission.mission_phase_list.size() + 1)
			mission_phase.is_first = is_first
			mission_phase.data_mission = mission
			mission.mission_phase_list.append(mission_phase)
			is_first = false
		# 标记最后一个任务阶段，用于NPC任务阶段显示的区分
		mission.mission_phase_list[-1].is_last = true
	return mission


static func get_visible_limit_from_config(visible_limit_info: Dictionary) -> MissionVisibleLimit:
	var mission_visible_limit = MissionVisibleLimit.new()
	if visible_limit_info.has("level"):
		mission_visible_limit.level = visible_limit_info["level"]
	if visible_limit_info.has("jobs"):
		for job_id in visible_limit_info["jobs"]:
			mission_visible_limit.jobs.append(job_id)
	if visible_limit_info.has("missions"):
		for mission_id in visible_limit_info["missions"]:
			mission_visible_limit.missions.append(mission_id)
	return mission_visible_limit


func _get_data_mission_phase(
	info: Dictionary
) -> DataMissionPhase:
	var data_mission_phase = DataMissionPhase.new()
	# 任务阶段名称
	if info.has("name"):
		data_mission_phase.name = info["name"]
	# 任务附属NPC
	if info.has("attach_npc_id"):
		data_mission_phase.attach_npc_id = info["attach_npc_id"]
	# 对话
	if info.has("messages"):
		for message in info["messages"]:
			data_mission_phase.messages.append(message)
	# 满足要求后的对话
	if info.has("messages_matched"):
		for message in info["messages_matched"]:
			data_mission_phase.messages_matched.append(message)
	# 要求
	if info.has("requires"):
		var require_info_list = info["requires"]
		for require_info in require_info_list:
			data_mission_phase.requires.append(_get_require_from_config(require_info))
	# 奖励
	if info.has("rewards"):
		var reward_info_list = info["rewards"]
		for reward_info in reward_info_list:
			data_mission_phase.rewards.append(_get_reward_from_config(reward_info))
	# 完成对话
	if info.has("finish_messages"):
		for message in info["finish_messages"]:
			data_mission_phase.finish_messages.append(message)
	# 完成对话后隐藏的NPC
	if info.has("finish_hide_npc"):
		for npc_id in info["finish_hide_npc"]:
			data_mission_phase.finish_hide_npc.append(npc_id)
	# 完成对话后显示的NPC
	if info.has("finish_show_npc"):
		for npc_id in info["finish_show_npc"]:
			data_mission_phase.finish_show_npc.append(npc_id)
	return data_mission_phase



func _get_require_from_config(require_info: Dictionary) -> MissionRequire:
	var type = require_info["type"]
	if type == "item":
		var mission_require = MissionRequireCollect.new()
		mission_require.item_id = require_info["id"]
		mission_require.item_name = _get_item_name_from_config(require_info["id"])
		mission_require.target_count = require_info["count"]
		return mission_require
	elif type == "kill":
		var mission_require = MissionRequireKill.new()
		mission_require.monster_id = require_info["id"]
		# FIXME 频繁读取配置文件，需要优化
		mission_require.monster_name = res_manager.get_monster_config(require_info["id"])["name"]
		mission_require.target_count = require_info["count"]
		return mission_require
	else:
		assert(false, "未知的需求类型：" + type)
		return null


func _get_reward_from_config(reward_info: Dictionary) -> MissionReward:
	var type = reward_info["type"]
	if type == "exp":
		var mission_reward = MissionRewardExp.new()
		mission_reward.count = reward_info["count"]
		return mission_reward
	elif type == "money":
		var mission_reward = MissionRewardMoney.new()
		mission_reward.count = reward_info["count"]
		return mission_reward
	elif type == "item":
		var mission_reward = MissionRewardItem.new()
		mission_reward.item_id = reward_info["id"]
		mission_reward.item_name = _get_item_name_from_config(reward_info["id"])
		mission_reward.count = reward_info["count"]
		return mission_reward
	elif type == "job_change":
		var mission_reward = MissionRewardJob.new()
		mission_reward.job_id = reward_info["job_id"]
		mission_reward.job_name = res_manager.get_job_name(reward_info["job_id"])
		return mission_reward
	elif type == "alchemy":
		var mission_reward = MissionRewardAlchemy.new()
		mission_reward.alchemy_id = reward_info["id"]
		mission_reward.alchemy_name = res_manager.alchemy_dic[reward_info["id"]]["name"]
		return mission_reward
	elif type == "skill":
		var mission_reward = MissionRewardSkill.new()
		mission_reward.skill_id = reward_info["id"]
		mission_reward.skill_name = res_manager.get_skill_name(reward_info["id"])
		mission_reward.skill_phase = reward_info["skill_phase"]
		return mission_reward
	else:
		assert(false, "未知的奖励类型：" + type)
		return null


func _get_items_from_config(items_config: Array) -> Array[MissionItem]:
	var mission_items: Array[MissionItem] = []
	for item_config in items_config:
		var mission_item = MissionItem.new(item_config["id"],item_config["count"])
		mission_items.append(mission_item)
	return mission_items


# 遍历进行中的任务，并调用回调函数
func foreach_mission_require_collect(callback: Callable):
	# 遍历进行中的任务
	for mission in missions_dic.values():
		if mission.status != DataMission.STATUS_IN_PROGRESS:
			continue
		# 遍历进行中的任务阶段
		for mission_phase in mission.mission_phase_list:
			if mission_phase.status == DataMissionPhase.STATUS_FINISH:
				continue
			# 遍历任务阶段的要求
			for require in mission_phase.requires:
				if require is MissionRequireCollect:
					var item_count = callback.call(require.item_id)
					require.update_collect_count(item_count)


func data_bag_item_changed(item_id: String, item_count: int):
	# 遍历进行中的任务
	for mission in missions_dic.values():
		if mission.status != DataMission.STATUS_IN_PROGRESS:
			continue
		# 遍历进行中的任务阶段
		for mission_phase in mission.mission_phase_list:
			if mission_phase.status == DataMissionPhase.STATUS_FINISH:
				continue
			# 遍历任务阶段的要求
			for require in mission_phase.requires:
				if require is MissionRequireCollect:
					if require.item_id == item_id:
						require.update_collect_count(item_count)


func data_player_killed_monster(data_player: DataPlayer,target: DataMonster):
	# 遍历进行中的任务
	for mission in missions_dic.values():
		if mission.status != DataMission.STATUS_IN_PROGRESS:
			continue
		# 遍历进行中的任务阶段
		for mission_phase in mission.mission_phase_list:
			if mission_phase.status != DataMissionPhase.STATUS_IN_PROGRESS:
				continue
			# 遍历任务阶段的要求
			for require in mission_phase.requires:
				if require is MissionRequireKill:
					if require.monster_id == target.monster_id:
						require.add_kill_count(1)
					

func _get_item_name_from_config(item_id: String) -> String:
	if DataEtc.is_etc(item_id):
		return res_manager.etc_dic[item_id]["name"]
	elif DataConsume.is_consume(item_id):
		return res_manager.consume_dic[item_id]["name"]
	elif DataEquip.is_equip(item_id):
		var index = item_id.rfind("_")
		var equip_type = item_id.substr(0, index)
		return res_manager.equip_dic[equip_type][item_id]["name"]
	else:
		assert(false, "未知物品类型：" + item_id)
		return ""
