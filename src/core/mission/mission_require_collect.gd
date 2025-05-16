class_name MissionRequireCollect extends MissionRequire

## 要求收集某一种物品

var item_id: String
var target_count: int
var collect_count: int

# 物品名称(用于显示，从配置文件中获取)
var item_name: String = ""

func is_can_finish() -> bool:
	return collect_count >= target_count


## 更新任务要求的收集数量
## always_update bool true表示不断更新，false表示满足数量后不再更新
func update_collect_count(count: int,always_update: bool = false):
	if count <= target_count or always_update or (collect_count < target_count and count >= target_count):
		collect_count = count
		updated.emit(self)
	else:
		collect_count = count


func save() -> Dictionary:
	return {
		"item_id": item_id,
		"target_count": target_count
	}


func load(_data: Dictionary) -> void:
	item_id = _data["item_id"]
	target_count = _data["target_count"]
