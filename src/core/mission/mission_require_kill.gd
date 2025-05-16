class_name MissionRequireKill extends MissionRequire

## 要求击杀某一种怪物

var monster_id: String
var target_count: int
var kill_count: int

var monster_name: String

func is_can_finish() -> bool:
	return kill_count >= target_count


func add_kill_count(count: int):
	# 如果已经满足要求，则不增加击杀数量
	if kill_count < target_count:
		kill_count += count

		updated.emit(self)


func save() -> Dictionary:
	var dic = {}
	dic["monster_id"] = monster_id
	dic["target_count"] = target_count
	dic["kill_count"] = kill_count
	return dic


func load(data: Dictionary) -> void:
	monster_id = data["monster_id"]
	target_count = data["target_count"]
	kill_count = data["kill_count"]
