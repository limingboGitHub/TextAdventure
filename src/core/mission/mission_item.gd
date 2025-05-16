class_name MissionItem

## 流通在任务相关业务中的物品信息
##
## 只包含了物品的id和数量

var id: String = ""
var count: int = 0

func _init(id: String, count: int) -> void:
	self.id = id
	self.count = count
