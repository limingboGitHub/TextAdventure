class_name DataMissionPhase

## 任务阶段
##
## 在整个任务对话周期中，将对话分割成多个【任务阶段】。
## 展示多段对话并附带一些要求或奖励，作为一个阶段。
##
## 例如：
## 任务阶段1  NPC_1: 你好，请帮我将这个东西带给NPC_2。（无要求，奖励任务物品A）
## 任务阶段2  NPC_2: 你找我有什么事吗。（要求任务物品A，无奖励）
## 任务阶段3  NPC_1: 谢谢你，这是你的报酬。（无要求，奖励经验和金钱）
##

# 任务主体
var data_mission: DataMission
# 任务阶段ID
var id: String = ""
# 任务阶段名称
var name: String = ""
# 任务附属NPC
var attach_npc_id: String = ""
# 对话内容
var messages: Array[String] = []
# 满足要求后的对话
var messages_matched: Array[String] = []
# 要求
var requires: Array[MissionRequire] = []
# 奖励
var rewards: Array[MissionReward] = []

# 完成对话
var finish_messages: Array[String] = []

# 完成对话后隐藏的NPC
var finish_hide_npc: Array[String] = []
# 完成对话后显示的NPC
var finish_show_npc: Array[String] = []

## 完成状态
##
# 任务未开始
const STATUS_NOT_START = 0
# 任务进行中
const STATUS_IN_PROGRESS = 1
# 任务已完成
const STATUS_FINISH = 2
# 当前任务阶段完成状态
var status: int = 0

# 是否是首个任务阶段
var is_first: bool = false

# 是否是最后一个任务阶段
var is_last: bool = false

signal phase_finished(data_mission_phase: DataMissionPhase)

signal phase_added(data_mission_phase: DataMissionPhase)

signal phase_require_updated(data_mission_phase: DataMissionPhase)


func accept():
	status = STATUS_IN_PROGRESS
	phase_added.emit(self)
	# 监听任务阶段的要求
	for require in requires:
		require.updated.connect(_on_require_updated)


func finish():
	status = STATUS_FINISH
	phase_finished.emit(self)


func is_finish() -> bool:
	return status == STATUS_FINISH


func item_update(item_id: String, item_count: int):
	for require in requires:
		if require is MissionRequireCollect:
			if require.item_id == item_id:
				require.collect_count = item_count


func has_require() -> bool:
	return requires != null and requires.size() > 0


func has_reward() -> bool:
	return rewards != null and rewards.size() > 0


func is_all_require_finish() -> bool:
	for require in requires:
		if not require.is_can_finish():
			return false
	return true


func _on_require_updated(require: MissionRequire) -> void:
	phase_require_updated.emit(self)


func reset():
	status = STATUS_NOT_START


func save() -> Dictionary:
	var dic = {}
	# 如果任务阶段未开始，则不保存任何信息
	if status != STATUS_NOT_START:
		dic["name"] = name
		dic["status"] = status
		# 任务要求需要保存，否则其中包含的进度信息无法还原
		var require_list = []
		for require in requires:
			# 这里注意，由于任务要求没有id，只能通过顺序来区分，因此空的任务要要求也要保存，保证顺序性一致
			var require_dic = require.save()
			require_list.append(require_dic)
		dic["requires"] = require_list
	return dic


func load(data: Dictionary) -> void:
	status = data.status
	# 加载任务要求
	if data.has("requires"):
		for i in range(data["requires"].size()):
			var require_dic = data["requires"][i]
			var require = requires[i]
			require.load(require_dic)
