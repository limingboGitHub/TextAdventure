class_name DataMission

## NPC任务功能对应的数据类

## 任务信息
##
#region
# 任务ID
var id: String
# 任务名称
var name: String
#endregion

## 任务要求
##
# 任务可见性限制
var visible_limit: MissionVisibleLimit


## 任务阶段
var mission_phase_list: Array[DataMissionPhase] = []


## 任务状态
##
## 该任务状态区别于NPC的任务状态 @see DataNPC.mission_status
## 该任务状态的作用：当任务管理器监听到背包物品变化或者怪物击杀时，
## 筛选出进行中的任务，并进一步更新其中进行中的任务阶段
#region
# 任务未开始
const STATUS_NOT_START = 0
# 任务进行中
const STATUS_IN_PROGRESS = 1
# 任务已完成
const STATUS_FINISH = 2
# 当前任务状态
var status: int = 0
#endregion

# 任务是否可重复
var repeatable: bool = false

signal status_changed(data_mission: DataMission)

func finish():
	status = STATUS_FINISH


func is_not_start():
	return status == STATUS_NOT_START


func is_finish():
	return status == STATUS_FINISH


func change_status(target: int):
	self.status = target
	status_changed.emit(self)


## 获取下一个未完成的任务阶段
func get_next_mission_phase()->DataMissionPhase:
	for mission_phase in mission_phase_list:
		if mission_phase.is_finish():
			continue
		return mission_phase
	return null


func reset():
	status = STATUS_NOT_START
	# 将任务阶段重置
	for mission_phase in mission_phase_list:
		mission_phase.reset()


func save() -> Dictionary:
	var dic = {}
	# 如果任务未开始，则不保存任何信息
	if status != STATUS_NOT_START:
		dic["name"] = name
		dic["status"] = status
		# 保存任务阶段
		var phase_list_to_save = []
		for mission_phase in mission_phase_list:
			var mission_phase_dic = mission_phase.save()
			if mission_phase_dic.is_empty():
				continue
			phase_list_to_save.append(mission_phase_dic)
		if not phase_list_to_save.is_empty():
			dic["mission_phase_list"] = phase_list_to_save
	return dic


func load(data: Dictionary) -> void:
	status = data.status
	# 加载任务阶段
	if data.has("mission_phase_list"):
		for i in range(data["mission_phase_list"].size()):
			var mission_phase_dic = data["mission_phase_list"][i]
			var mission_phase = mission_phase_list[i]
			mission_phase.load(mission_phase_dic)
