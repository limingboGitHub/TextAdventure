extends Node
class_name DamageInfoManager

# 信号定义
signal damage_record_added(damage_data: DataDamage)  # 当新的伤害记录被添加时触发
signal damage_records_cleared()  # 当所有伤害记录被清除时触发

# 用于存储伤害记录的数组
var damage_records: Array[DataDamage] = []
# 最大记录数
var max_records: int = 1000
# 用于记录各种伤害的占比 key：伤害名称，value：伤害值
var damage_dic: Dictionary
# 总伤害值
var total_damage: int = 0
# 是否开启
var enable: bool = false

# 添加伤害记录，如果超出最大记录数，则移除最早的记录 (FIFO)
func add_damage_record(damage_data: DataDamage) -> void:
	if not enable:
		return

	if damage_records.size() > max_records:
		clear_all_damage_records()
	
	damage_records.append(damage_data)
	# 添加伤害占比
	for damage_detail in damage_data.damage_details:
		if damage_dic.has(damage_detail.name):
			damage_dic[damage_detail.name] += damage_detail.value
		else:
			damage_dic[damage_detail.name] = damage_detail.value
	# 总伤害值
	total_damage += damage_data.value
	# 发射信号通知UI层
	emit_signal("damage_record_added", damage_data)

# 获取所有伤害记录
func get_all_damage_records() -> Array[DataDamage]:
	return damage_records

# 清空所有伤害记录
func clear_all_damage_records() -> void:
	damage_records.clear()
	damage_dic.clear()
	total_damage = 0
	
	# 发射信号通知UI层
	emit_signal("damage_records_cleared")

# 获取总伤害输出 (所有记录的伤害值总和)
func get_total_damage_output() -> float:
	var _total_damage: float = 0.0
	for record in damage_records:
		if record != null:
			_total_damage += record.damage_value
	return _total_damage


func get_size() -> int:
	return damage_records.size()


func set_enable(_enable: bool):
	self.enable = _enable