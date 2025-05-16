class_name MissionPageTool

## 任务翻页工具
##
## 负责处理NPC对话框的内容展示逻辑


var npc: DataNPC
var player_manager: PlayerManager
var mission_manager: MissionManager
# 当前对话阶段
var mission_phase = null
# 当前对话阶段按钮类型
var mission_phase_ok_bt_type = ""
# 类型枚举
const OK_BT_TYPE_CLOSE = "close"
const OK_BT_TYPE_ACCEPT = "accept"
const OK_BT_TYPE_FINISH = "finish"
# 当前信息的索引
var current_index: int = 0

# 对话框消息展示
signal message_showed(
	title: String,
	message: String,
	ok_bt_text: String,
	selections: Array,
	requires: Array[MissionRequire],
	rewards: Array[MissionReward]
)
# 关闭对话框
signal dialog_hided()


func set_data(
	data_npc: DataNPC,
	mission_manager: MissionManager,
	player_manager: PlayerManager
):
	self.npc = data_npc
	self.mission_manager = mission_manager
	self.player_manager = player_manager

	# 重置数据
	current_index = 0
	mission_phase_ok_bt_type = ""

	# 任务对话框展示的信息
	var title = npc.name
	var messages = []
	# NPC功能选项，如果NPC有商店功能，则展示商店功能选项，
	# 可能是DataMissionPhase/DataBag/DataTeleport类型
	var selections: Array = []

	# 查看NPC是否有商店功能
	if npc.shop_bag != null:
		selections.append(npc.shop_bag)

	# 查看NPC是否有传送功能
	if npc.teleport_data != null:
		if DataWorld.is_visible_limit_met(
			player_manager.data_player,
			npc.teleport_data.visible_limit,
			mission_manager
		):
			selections.append(npc.teleport_data)

	# 遍历当前NPC的未完成任务阶段
	for phase in npc.get_mission_phases():
		if phase.is_finish():
			continue
		# 查看是否满足任务阶段对应的主任务的可见性限制
		if not DataWorld.is_visible_limit_met(
			player_manager.data_player,
			phase.data_mission.visible_limit,
			mission_manager
		):
			continue
		selections.append(phase)
	
	# 遍历当前NPC的已完成任务阶段，将已完成任务阶段中的finish_messages覆盖默认对话
	for phase in npc.get_finish_phases():
		if phase.is_finish() and phase.finish_messages != null:
			messages = phase.finish_messages

	# 如果没有其他对话，则展示默认对话
	if messages.size() == 0:
		messages = npc.default_messages
	
	# 展示信息
	message_showed.emit(
		title,
		messages[current_index],
		"",
		selections,
		null,
		null
	)


func ok_button_pressed():
	# 根据按钮类型进一步处理
	if _is_last_message():
		match mission_phase_ok_bt_type:
			OK_BT_TYPE_CLOSE:
				dialog_hided.emit()
			OK_BT_TYPE_ACCEPT:
				# 隐藏对话框
				dialog_hided.emit()
				# 标记任务主体的进行中状态
				mission_manager.accept_mission(mission_phase.data_mission)
				# 任务阶段完成
				_mission_phase_finished(mission_phase)
			OK_BT_TYPE_FINISH:
				# 关闭对话框
				dialog_hided.emit()

				# 有时任务阶段只有一个，且同时这个任务阶段可以被完成，
				# 需先要进入进行中状态，处理完部分逻辑后，再进行完成状态
				if mission_phase.is_first:
					# 标记任务主体的进行中状态
					mission_manager.accept_mission(mission_phase.data_mission)
				
				# 判断是否满足任务完成的要求
				if mission_phase.requires != null and mission_phase.requires.size() > 0:
					if !DataWorld.is_require_met(
						player_manager.data_player,
						player_manager.data_bag,
						mission_phase.requires,
						mission_manager
					):
						ToastManager.add_toast("任务要求未满足")
						return
					else:
						# 消耗任务物品
						for require in mission_phase.requires:
							if require is MissionRequireCollect:
								player_manager.data_bag.remove_item_by_id(require.item_id, require.target_count)
				
				# 任务阶段完成
				_mission_phase_finished(mission_phase)
				
	else:
		_next_message()


func _mission_phase_finished(data_mission_phase: DataMissionPhase):
	# 任务阶段完成
	data_mission_phase.finish()
	# 如果任务阶段是最后一个，则完成任务
	if data_mission_phase.is_last:
		mission_manager.finish_mission(data_mission_phase.data_mission)


func _next_message():
	current_index += 1

	# 如果当前是最后一条消息，则展示任务要求和奖励
	var requires = null
	var rewards = null
	if _is_last_message():
		requires = mission_phase.requires
		rewards = mission_phase.rewards

		# 如果该任务阶段同时有要求和奖励，则根据是否满足任务要求来展示其中一个
		if mission_phase.has_require() and mission_phase.has_reward():
			if DataWorld.is_require_met(
				player_manager.data_player,
				player_manager.data_bag,
				mission_phase.requires,
				mission_manager
			):
				requires = null
				rewards = mission_phase.rewards
			else:
				requires = mission_phase.requires
				rewards = null

	message_showed.emit(
		npc.name,
		mission_phase.messages[current_index],
		_ok_bt_text(mission_phase_ok_bt_type),
		null,
		requires,
		rewards
	)


## 用户选择任务
##
## 根据任务当前状态进一步判定：
## 1. 如果任务未开始，则展示接受前的对话内容
## 2. 如果任务进行中，且未满足完成条件，则展示接受任务后的对话内容
## 3. 如果任务进行中，且已满足完成条件，则修改任务完成状态，并展示完成后的对话内容
func select_mission_phase(phase: DataMissionPhase):
	current_index = 0
	mission_phase = phase
	mission_phase_ok_bt_type = OK_BT_TYPE_ACCEPT
	
	var is_matched = _is_matched_require(phase)

	if phase.has_require():
		if is_matched:
			# 有任务要求，且已经满足
			mission_phase_ok_bt_type = OK_BT_TYPE_FINISH
		else:
			# 有任务要求，但未满足
			mission_phase_ok_bt_type = OK_BT_TYPE_CLOSE
	elif phase.is_first:
		if phase.is_last:
			# 无任务要求，是最后一个任务阶段
			mission_phase_ok_bt_type = OK_BT_TYPE_FINISH
		else:
			# 无任务要求，是第一个任务阶段
			mission_phase_ok_bt_type = OK_BT_TYPE_ACCEPT
	else:
		# 无任务要求，不是第一个任务阶段
		mission_phase_ok_bt_type = OK_BT_TYPE_FINISH

	var title = npc.name
	var ok_bt_text = _ok_bt_text(mission_phase_ok_bt_type)

	var message = mission_phase.messages[current_index]
	# 如果已满足要求，则展示满足任务要求后的对话
	if is_matched:
		message = mission_phase.messages_matched[current_index]
	
	# 如果当前是最后一条消息，则展示任务要求和奖励
	var requires = null
	var rewards = null
	if _is_last_message():
		requires = mission_phase.requires
		rewards = mission_phase.rewards

		# 如果该任务阶段同时有要求和奖励，则根据是否满足任务要求来展示其中一个
		if mission_phase.has_require() and mission_phase.has_reward():
			if is_matched:
				requires = null
				rewards = mission_phase.rewards
			else:
				requires = mission_phase.requires
				rewards = null
			
	# 展示对话框消息
	message_showed.emit(title, message, ok_bt_text, null, requires, rewards)


# 如果还有下一条消息，则展示“继续”按钮
func _ok_bt_text(type: String) -> String:
	if _is_last_message():
		return _ok_bt_type_to_text(type)
	else:
		return "继续"


# 按钮类型转中文
func _ok_bt_type_to_text(type: String) -> String:
	match type:
		OK_BT_TYPE_CLOSE:
			return "关闭"
		OK_BT_TYPE_ACCEPT:
			return "接受"
		OK_BT_TYPE_FINISH:
			return "完成"
		_:
			return "关闭"


func _is_last_message() -> bool:
	if _is_matched_require(mission_phase):
		return mission_phase.messages_matched.size() <= current_index + 1
	else:
		return mission_phase.messages.size() <= current_index + 1


func _is_matched_require(phase: DataMissionPhase) -> bool:
	return phase.has_require() and \
		DataWorld.is_require_met(
			player_manager.data_player,
			player_manager.data_bag,
			phase.requires,
			mission_manager)
