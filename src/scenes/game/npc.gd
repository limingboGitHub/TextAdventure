extends Control

var data_npc: DataNPC


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_panel_my_pressed(ui: Control) -> void:
	if data_npc == null:
		return
	data_npc.show_function()


func set_data(data: DataNPC) -> void:
	name = data.name
	data_npc = data
	$Name.text = data_npc.name
	_on_mission_status_changed(data)
	# 设置NPC是否可见
	_on_npc_visible_changed(data)

	# 监听任务状态变化
	data_npc.npc_status_changed.connect(_on_mission_status_changed)
	# 监听NPC可见性变化
	data_npc.npc_visible_changed.connect(_on_npc_visible_changed)


func _on_mission_status_changed(data_npc: DataNPC) -> void:
	if data_npc.mission_status == DataNPC.MISSION_STATUS_NONE:
		$MissionTip/Label.text = ""
	elif data_npc.mission_status == DataNPC.MISSION_STATUS_ACCEPTABLE:
		$MissionTip/Label.text = "!"
	elif data_npc.mission_status == DataNPC.MISSION_STATUS_DURATION:
		$MissionTip/Label.text = "..."
	elif data_npc.mission_status == DataNPC.MISSION_STATUS_COMPLETABLE:
		$MissionTip/Label.text = "✓"


func _on_npc_visible_changed(data_npc: DataNPC) -> void:
	if data_npc.visible:
		show()
	else:
		hide()
