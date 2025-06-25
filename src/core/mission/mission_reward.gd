class_name MissionReward

## 任务奖励基类

var count: int

# 针对职业可见
var limit_job: Array[String] = []


func save() -> Dictionary:
	return {
		"count": count
	}


func load(data: Dictionary):
	count = data["count"]
