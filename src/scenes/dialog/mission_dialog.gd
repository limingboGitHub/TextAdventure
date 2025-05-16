extends Control

var mission_containers = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	mission_containers.append($"TabContainer/未完成")
	mission_containers.append($"TabContainer/已完成")

	# 遍历并清空所有任务
	clear_missions()
	
	# 清空信息
	for container in mission_containers:
		container.get_node("Content/Message").text = ""
		container.get_node("Content/ScrollContainer/RequireOrReward").hide()

	## 测试代码
	#test_mission()

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func test_mission() -> void:
	var mission = DataMission.new()
	mission.id = "1"
	mission.name = "任务1"

	# 任务阶段
	for i in range(1, 4):
		var phase = DataMissionPhase.new()
		phase.id = str(i)
		phase.name = "任务阶段" + str(i)
		phase.messages.append("任务阶段" + str(i) + "的消息1")
		phase.data_mission = mission
		mission.mission_phase_list.append(phase)

	# 给任务阶段1添加要求
	var require = MissionRequireCollect.new()
	require.item_id = "04000000"
	require.target_count = 3
	mission.mission_phase_list[0].requires.append(require)

	# 给任务阶段2添加奖励
	var reward = MissionRewardMoney.new()
	reward.count = 100
	mission.mission_phase_list[1].rewards.append(reward)

	add_mission(mission)


func has_mission(mission_id: String) -> bool:
	for container in mission_containers:
		if container.has_node("ScrollBack/ScrollContainer/MissionListContainer/" + mission_id):
			return true
	return false


# 将任务列表中已经开启的任务添加到任务对话框中展示
#
# @param missions: 任务列表
func init(missions: Array) -> void:
	for mission in missions:
		if mission.is_not_start():
			continue
		add_mission(mission)


func add_mission(mission: DataMission) -> void:
	var container = mission_containers[1] if mission.is_finish() else mission_containers[0]	

	var mission_item_scene = SingletonGameScenePre.MissionItemScene.instantiate()
	mission_item_scene.name = mission.id
	mission_item_scene.add_mission(mission)
	mission_item_scene.mission_phase_selected.connect(_on_mission_phase_selected)
	container.get_node("ScrollBack/ScrollContainer/MissionListContainer").add_child(mission_item_scene)

	# 监听未完成任务的完成事件
	if not mission.is_finish():
		mission.status_changed.connect(_on_mission_status_changed)


func remove_mission(mission: DataMission) -> void:
	for container in mission_containers:
		if container.has_node("ScrollBack/ScrollContainer/MissionListContainer/" + mission.id):
			container.get_node("ScrollBack/ScrollContainer/MissionListContainer/" + mission.id).queue_free()


func _on_mission_status_changed(mission: DataMission) -> void:
	if mission.is_finish():
		# 从未完成tab移除
		remove_mission(mission)
		# 在已完成tab添加
		add_mission(mission)


func clear_missions() -> void:
	for container in mission_containers:
		for child in container.get_node("ScrollBack/ScrollContainer/MissionListContainer").get_children():
			child.queue_free()


func _on_close_button_pressed() -> void:
	hide()


func _on_mission_phase_selected(phase: DataMissionPhase) -> void:
	print("任务阶段被选中：", phase.name)
	mission_phase_updated(phase)


func mission_phase_updated(phase: DataMissionPhase) -> void:

	var container = mission_containers[1] if phase.data_mission.is_finish() else mission_containers[0]
	# 更新任务阶段列表中的任务状态
	var mission_item = container.get_node("ScrollBack/ScrollContainer/MissionListContainer/" + phase.data_mission.id)
	if mission_item:
		mission_item.update_phase(phase)

	if phase.status == DataMissionPhase.STATUS_NOT_START:
		# 任务阶段未开始，展示未知信息
		container.get_node("Content/Message").text = "???"
		container.get_node("Content/ScrollContainer/RequireOrReward").hide()
	else:
		# 展示任务阶段对话
		container.get_node("Content/Message").text = phase.messages[0]
		# 展示任务要求或者奖励，如果都存在，则展示要求
		mission_phase_require_updated(phase)
	

func mission_phase_require_updated(phase: DataMissionPhase) -> void:
	var container = mission_containers[1] if phase.data_mission.is_finish() else mission_containers[0]
	if phase.has_reward():
		if phase.has_require():
			container.get_node("Content/ScrollContainer/RequireOrReward").set_mission_requires(phase.requires)
		else:
			container.get_node("Content/ScrollContainer/RequireOrReward").set_mission_rewards(phase.rewards)
	else:
		if phase.has_require():
			container.get_node("Content/ScrollContainer/RequireOrReward").set_mission_requires(phase.requires)
		else:
			container.get_node("Content/ScrollContainer/RequireOrReward").hide()
