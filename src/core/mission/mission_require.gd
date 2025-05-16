class_name MissionRequire

## 任务要求基类

signal updated(require: MissionRequire)

## 判断是否满足任务要求
func is_can_finish() -> bool:
	return false


# 子类需要重写
func save() -> Dictionary:
	return {}


# 子类需要重写
func load(_data: Dictionary) -> void:
	pass
