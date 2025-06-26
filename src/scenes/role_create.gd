extends Control

var create_info = {}

# 每种属性点的概率
var rate_table = {
	12: 10,
	11: 10,
	10: 10,
	9: 10,
	8: 10,
	7: 10,
	6: 10,
	5: 10,
	4: 10,
	3: 10
}

var random_num = 0

# 角色名（随机角色名）
var role_name_table = [
	"雷鸣战士土包",
	"荒",
	"荒天帝",
	"迪迦奥特曼",
	"钟岳",
	
	"钢铁之拳",
	"雷鸣战士",
	"盾墙守护者",
	"破甲勇士",
	"铁血骑士",
	"战锤英雄",
	"钢铁意志",
	"圣剑守护者",  
	"无畏先锋",    
	"龙血战士",    
	"荣耀战将",    
	"雷霆领主",    
	# 法师职业
	"月光法师",
	"火焰术士",
	"冰霜咏唱者",
	"暗影法师",
	"风暴召唤师",
	"星辰占卜师",
	"奥术导师",
	"元素掌控者",  
	"虚空学者",    
	"秘法贤者",    
	"时光编织者",  
	"灵魂收割者",  
	# 盗贼职业
	"暗影游侠",
	"迅捷猎手",
	"暗夜潜行者",
	"迅影盗贼",
	"无声隐士",
	"机敏侠客",
	"幽影刺客",    
	"诡术大师",    
	"致命毒师",    
	"幻影舞者",    
	"暗影猎手"
]

'''
创建角色信息成功
create_info: {
	"power": 1,
	"agility": 1,
	"intell": 1,
	"luck": 1
}
'''
signal create_role_info_success(role_name: String,create_info: Dictionary)

signal go_back

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 初始化Player场景
	$Player.clear_data()
	# 随机分配属性点
	_random_allocate()
	# 随机一个角色名称
	_random_role_name()

	for name in role_name_table:
		$ItemList.add_item(name)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _random_allocate() -> void:
	'''
	随机分配属性点
	4种属性点，每种属性点的值在3-12之间
	属性点随机到的概率见表格@rate_table
	'''
	random_num += 1

	var attributes = []
	var sum = 0
	for i in 4:
		var rate = randi() % 100
		var value = 0
		for k in rate_table:
			var v = rate_table[k]
			if rate < v:
				value = k
				sum += value
				break
			rate -= v
		attributes.append(value)
	
	$AttributeRoot/Attribute/Power/Value.text = str(attributes[0])
	$AttributeRoot/Attribute/Agility/Value.text = str(attributes[1])
	$AttributeRoot/Attribute/Intell/Value.text = str(attributes[2])
	$AttributeRoot/Attribute/Luck/Value.text = str(attributes[3])
	$RandomNum/Num.text = str(random_num)

	# 判断总值是否为46
	if sum >= 46:
		$RefreshTimer.stop()
		_high_light_attribute_modulate()
		

func _high_light_attribute_modulate():
	$AttributeRoot/Attribute/Power.modulate = Color.GREEN
	$AttributeRoot/Attribute/Agility.modulate = Color.GREEN
	$AttributeRoot/Attribute/Intell.modulate = Color.GREEN
	$AttributeRoot/Attribute/Luck.modulate = Color.GREEN


func _clear_attribute_modulate():
	$AttributeRoot/Attribute/Power.modulate = Color.WHITE
	$AttributeRoot/Attribute/Agility.modulate = Color.WHITE
	$AttributeRoot/Attribute/Intell.modulate = Color.WHITE
	$AttributeRoot/Attribute/Luck.modulate = Color.WHITE


func _on_ok_create_bt_pressed() -> void:
	$RefreshTimer.stop()
	# 检查角色名是否为空
	var role_name = $RoleNameLineEdit.text
	if role_name == "":
		$PopDialog.tip("角色名不能为空")
		return
	
	# mock 发出创建角色的请求
	create_info["power"] = $AttributeRoot/Attribute/Power/Value.text.to_int()
	create_info["agility"] = $AttributeRoot/Attribute/Agility/Value.text.to_int()
	create_info["intell"] = $AttributeRoot/Attribute/Intell/Value.text.to_int()
	create_info["luck"] = $AttributeRoot/Attribute/Luck/Value.text.to_int()
	_request_create_role(role_name,create_info)


func _on_random_bt_pressed() -> void:
	'''
	重新随机分配的属性点
	'''
	_random_allocate()


func _request_create_role(role_name: String,create_info: Dictionary) -> void:
	_request_create_role_callback(role_name)


func _request_create_role_callback(role_name) -> void:
	create_role_info_success.emit(role_name,create_info)


func show_this():
	show()
	# 随机分配属性点
	_random_allocate()
	# 随机一个角色名称
	_random_role_name()

	random_num = 0
	$RandomNum/Num.text = str(random_num)


func _on_back_bt_pressed() -> void:
	$RefreshTimer.stop()
	go_back.emit()
	hide()


func _on_random_name_bt_pressed() -> void:
	# 重新随机一个名称
	_random_role_name()


func _random_role_name() -> void:
	# 从角色名称表中随机选择一个名称
	if role_name_table.size() > 0:
		var random_index = randi() % role_name_table.size()
		var selected_name = role_name_table[random_index]
		$RoleNameLineEdit.text = selected_name


func _on_auto_refresh_bt_pressed() -> void:
	if $RefreshTimer.is_stopped():
		$RefreshTimer.start()
		_clear_attribute_modulate()


func _on_refresh_timer_timeout() -> void:
	_random_allocate()


func _on_item_list_item_selected(index: int) -> void:
	$RoleNameLineEdit.text = role_name_table[index]
