extends PanelContainer

var data_mission: DataMission

signal mission_phase_selected(phase: DataMissionPhase)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# 测试代码
	# _add_phase("任务阶段1")

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_mission(mission: DataMission) -> void:
	data_mission = mission
	# 设置任务主题名称
	$OneMissionContainer/MissionName/Label.text = mission.name

	# 清空所有任务节点
	for child in $OneMissionContainer/PhaseContainer.get_children():
		child.queue_free()

	for phase in mission.mission_phase_list:
		_add_phase(phase)


# 添加单个任务节点的文本限时
func _add_phase(phase: DataMissionPhase) -> void:
	var phase_scene = SingletonGameScenePre.MissionPhaseScene.instantiate()
	phase_scene.name = phase.name
	if phase.status == DataMissionPhase.STATUS_NOT_START:
		phase_scene.text = "---???"
	else:
		phase_scene.text = "---" + phase.name + " " + _finish_status(phase)
	$OneMissionContainer/PhaseContainer.add_child(phase_scene)
	# 监听点击事件
	phase_scene.pressed.connect(_on_phase_pressed.bind(phase))


func _on_phase_pressed(phase: DataMissionPhase) -> void:
	print("点击了任务阶段：", phase.name)
	# 发送信号，通知任务阶段被选中
	mission_phase_selected.emit(phase)


# 更新任务阶段
func update_phase(phase: DataMissionPhase) -> void:
	# 找到对应的任务阶段
	var phase_scene = $OneMissionContainer/PhaseContainer.get_node(phase.name)
	if phase_scene:
		if phase.status == DataMissionPhase.STATUS_NOT_START:
			phase_scene.text = "---???"
		else:
			phase_scene.text = "---" + phase.name + " " + _finish_status(phase)


func _finish_status(phase: DataMissionPhase) -> String:
	if phase.is_finish():
		return "✓"
	else:
		return ""
