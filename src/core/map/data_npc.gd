class_name DataNPC

## Npc数据类

var id: String
var name: String

## 类型
##
const TYPE_SHOP = "shop"
const TYPE_MISSION = "mission"
const TYPE_TELEPORT = "teleport"
# 位置
var position: Vector2
# 商店背包 当NPC类型为TYPE_SHOP时有效
var shop_bag: DataBag
# 任务id列表
var mission_ids: Array[String] = []
# 传送功能数据
var teleport_data: DataTeleport
# 所在地图id
var map_id: String

# NPC的默认对话
var default_messages: Array

# NPC是否可见
var visible: bool = true

## NPC任务状态枚举
##
## 用于NPC头上的气泡提示，提醒玩家可接受或者完成任务。
## 该任务状态区别于@see DataMission.status
# 无任务
const MISSION_STATUS_NONE = ""
# 可接受任务
const MISSION_STATUS_ACCEPTABLE = "可接受"
# 任务进行中
const MISSION_STATUS_DURATION = "进行中"
# 可完成任务
const MISSION_STATUS_COMPLETABLE = "可完成"
# NPC的任务状态
var mission_status: String = ""

## 存储NPC相关的任务阶段
##
## 未完成的任务阶段
var phases: Array[DataMissionPhase] = []
## 已完成任务阶段
var finish_phases: Array[DataMissionPhase] = []

signal npc_function_showed(data_npc: DataNPC)

signal npc_status_changed(data_npc: DataNPC)

signal npc_visible_changed(data_npc: DataNPC)


func _init(id: String,name: String) -> void:
	self.id = id
	self.name = name


# 展示NPC的对应功能
func show_function() -> void:
	npc_function_showed.emit(self)


func change_status(status: String) -> void:
	mission_status = status
	npc_status_changed.emit(self)


func add_mission_phase(mission_id: String, phase: DataMissionPhase) -> void:
	# # 防止重复添加某个任务阶段
	# if phases.has(phase):
	# 	return
	phases.append(phase)
	phase.accept()
	# 监听任务阶段的完成
	phase.phase_require_updated.connect(_on_phase_require_updated)


func get_mission_phases() -> Array[DataMissionPhase]:
	return phases


func get_finish_phases() -> Array[DataMissionPhase]:
	return finish_phases


func _on_phase_require_updated(data_mission_phase: DataMissionPhase) -> void:
	# 更新任务状态
	if data_mission_phase.is_all_require_finish():
		change_status(MISSION_STATUS_COMPLETABLE)
	else:
		change_status(MISSION_STATUS_DURATION)


func change_visible(_visible: bool) -> void:
	self.visible = _visible
	npc_visible_changed.emit(self)


func save() -> Dictionary:
	return {
		"name": name,
		"visible": visible,
	}
	

func load(data: Dictionary) -> void:
	visible = data.get("visible", true)
