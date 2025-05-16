class_name MissionRewardItem extends MissionReward

## 任务奖励物品

var item_id: String

var item_name: String = ""


func save() -> Dictionary:
	var data = super.save()
	data["item_id"] = item_id
	return data


func load(_data: Dictionary) -> void:
	super.load(_data)
	item_id = _data["item_id"]
