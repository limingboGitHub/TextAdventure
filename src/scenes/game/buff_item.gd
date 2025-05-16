extends Label

var progress_max_height: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 测试代码
	# var attribute_ability = AttributeAbility.new()
	# # attribute_ability.luck = 10
	# var attribute_details = AttributeDetails.new()
	# attribute_details.max_hp = 1000
	# var buff = DataBuff.new(
	# 	"1",
	# 	1,
	# 	attribute_details,
	# 	attribute_ability,
	# 	5000
	# )
	# set_buff(buff)

	progress_max_height = $Progress.size.y

	pass

var buff: DataBuff = null


func set_buff(_buff: DataBuff):
	self.buff = _buff

	if _buff.buff_type == 0:
		# 增益
		var style = load("res://theme/item/buff_label_back_increase.tres")
		self.add_theme_stylebox_override("normal", style)
	else:
		# 减益
		var style = load("res://theme/item/buff_label_back_decrease.tres")
		self.add_theme_stylebox_override("normal", style)
	
	$Label.text = _buff.name
	# 监听buff更新
	_buff.buff_updated.connect(_on_buff_updated)
	# 监听buff移除
	_buff.buff_removed.connect(_on_buff_removed)


func _on_buff_updated(_buff: DataBuff):
	# 使用ColorRect组件的高度来表示buff的剩余时间
	#print("buff.last_update_time: ", buff.last_update_time)
	$Progress.size.y = progress_max_height * (1 - buff.last_update_time / buff.duration)


func _on_buff_removed(_buff: DataBuff):
	queue_free()


# 获取最大属性名称
func _get_max_attr_name(data_buff: DataBuff) -> String:
	var max_attr_name = ""
	var max_attr_value = 0
	if data_buff.attribute_details != null:
		if data_buff.attribute_details.max_hp > max_attr_value:
			max_attr_name = "血"
			max_attr_value = data_buff.attribute_details.max_hp
		if data_buff.attribute_details.max_mp > max_attr_value:
			max_attr_name = "蓝"
			max_attr_value = data_buff.attribute_details.max_mp
		if data_buff.attribute_details.attack > max_attr_value:
			max_attr_name = "攻"
			max_attr_value = data_buff.attribute_details.attack
		if data_buff.attribute_details.defense > max_attr_value:
			max_attr_name = "防"
			max_attr_value = data_buff.attribute_details.defense
		if data_buff.attribute_details.magic > max_attr_value:
			max_attr_name = "魔"
			max_attr_value = data_buff.attribute_details.magic
		if data_buff.attribute_details.magic_def > max_attr_value:
			max_attr_name = "防"
			max_attr_value = data_buff.attribute_details.magic_def
		if data_buff.attribute_details.accuracy > max_attr_value:
			max_attr_name = "准"
			max_attr_value = data_buff.attribute_details.accuracy
		if data_buff.attribute_details.evasion > max_attr_value:
			max_attr_name = "闪"
			max_attr_value = data_buff.attribute_details.evasion
		if data_buff.attribute_details.hand_technology > max_attr_value:
			max_attr_name = "技"
			max_attr_value = data_buff.attribute_details.hand_technology
		if data_buff.attribute_details.move_speed > max_attr_value:
			max_attr_name = "速"
			max_attr_value = data_buff.attribute_details.move_speed
		if data_buff.attribute_details.jump_power > max_attr_value:
			max_attr_name = "跳"
			max_attr_value = data_buff.attribute_details.jump_power

	if data_buff.attribute_ability != null:
		if data_buff.attribute_ability.power > max_attr_value:
			max_attr_name = "力"
			max_attr_value = data_buff.attribute_ability.power
		if data_buff.attribute_ability.agility > max_attr_value:
			max_attr_name = "敏"
			max_attr_value = data_buff.attribute_ability.agility
		if data_buff.attribute_ability.intelligence > max_attr_value:
			max_attr_name = "智"
			max_attr_value = data_buff.attribute_ability.intelligence
		if data_buff.attribute_ability.luck > max_attr_value:
			max_attr_name = "运"
			max_attr_value = data_buff.attribute_ability.luck
		
	return max_attr_name
