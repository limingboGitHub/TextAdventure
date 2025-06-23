extends Control

var damage_info_manager: DamageInfoManager

@onready var damage_details_label: RichTextLabel = $Back/Panel/RichTextLabel
@onready var clear_tip_label: Label = $Title/Label
@onready var damage_percent_label: RichTextLabel = $Back/Panel2/RichTextLabel

func init(_damage_info_manager: DamageInfoManager) -> void:
	self.damage_info_manager = _damage_info_manager

	_damage_info_manager.damage_record_added.connect(_on_damage_record_added)
	_damage_info_manager.damage_records_cleared.connect(_on_damage_records_cleared)

	damage_details_label.text = ""


func _on_close_button_pressed() -> void:
	hide()


func _on_damage_record_added(damage_data: DataDamage) -> void:
	# 伤害类型
	var damage_type = "攻击/魔法力" + str(damage_data.attack_value)
	if damage_data.type == DataDamage.TYPE.WAR_STOMP:
		damage_type = "战争践踏"
	if damage_data.type == DataDamage.TYPE.POISON:
		damage_type = "中毒"
	elif damage_data.type == DataDamage.TYPE.FIRE:
		damage_type = "灼烧"
		
	var damage_details_str = "【"
	# 攻击力
	damage_details_str += damage_type + " | "
	# 伤害详情
	for damage_detail in damage_data.damage_details:
		damage_details_str += damage_detail.name
		if damage_detail.rate != 0:
			damage_details_str += "("+str(round(damage_detail.rate*100.0)/100.0)+")"
		if damage_detail.value != 0:
			damage_details_str += str(damage_detail.value)
			damage_details_str += "[color=green][" \
				+ str(round(int(damage_detail.value * 10000.0 / damage_data.value))/100.0) + \
				"%][/color]"
		damage_details_str += " | "
	damage_details_str += "最终伤害:" + str(damage_data.value)
	damage_details_str += "】\n"
	damage_details_label.append_text(damage_details_str)
	# 总伤害占比
	_show_damage_percent()

	# 更新进度
	clear_tip_label.text = "1000/" + str(damage_info_manager.get_size())


func _show_damage_percent():
	# 如果没有伤害记录，直接清空并返回
	if damage_info_manager.total_damage == 0:
		damage_percent_label.text = ""
		return
		
	# 预计算不同数量的方块字符串，避免每次循环拼接
	var block_strings = [""]
	var single_block = "+"
	for i in range(1, 11):  # 预计算1到10个方块的字符串
		block_strings.append(block_strings[i-1] + single_block)
	
	# 创建临时数组存储伤害名称和对应的百分比
	var damage_percent_array = []
	
	# 遍历伤害字典，计算百分比并添加到数组
	for damage_name in damage_info_manager.damage_dic.keys():
		var percent = round(int(damage_info_manager.damage_dic[damage_name] * 10000.0 / damage_info_manager.total_damage)) / 100.0
		damage_percent_array.append({"name": damage_name, "percent": percent})
	
	# 按百分比从大到小排序
	damage_percent_array.sort_custom(func(a, b): return a["percent"] > b["percent"])
	
	# 使用字符串数组收集每行内容，最后一次性合并，减少字符串拼接操作
	var lines = []
	
	# 遍历排序后的数组，组装伤害占比字符串，每种伤害单独一行
	for damage_info in damage_percent_array:
		var percent = damage_info["percent"]
		
		# 每达到10%增加一个方块，使用预计算的方块字符串
		var block_count = min(int(percent / 10), 10)  # 限制最多10个方块
		block_count = max(block_count,0)
		var blocks = block_strings[block_count]
		
		lines.append(damage_info["name"] + " " + blocks + str(percent) + "%")
	
	# 一次性合并所有行
	damage_percent_label.text = "\n".join(lines)


func _on_damage_records_cleared() -> void:
	damage_details_label.text = ""
	_show_damage_percent()
	clear_tip_label.text = "1000/0"


func _on_clear_button_pressed() -> void:
	damage_info_manager.clear_all_damage_records()


func _on_enable_button_toggled(toggled_on: bool) -> void:
	damage_info_manager.set_enable(toggled_on)
