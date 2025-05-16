class_name MissionReward

## 任务奖励基类

var count: int


func save() -> Dictionary:
	return {
		"count": count
	}


func load(data: Dictionary):
	count = data["count"]
