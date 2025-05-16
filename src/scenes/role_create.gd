extends Control

var create_info = {}

# 每种属性点的概率
var rate_table = {
	12: 1,
	11: 2,
	10: 3,
	9: 5,
	8: 12,
	7: 13,
	6: 16,
	5: 16,
	4: 16,
	3: 16
}

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _random_allocate() -> void:
	'''
	随机分配属性点
	4种属性点，每种属性点的值在3-12之间
	属性点随机到的概率：
	12	2%
	11	3%
	10	5%
	9	10%
	8	10%
	7	10%
	6	15%
	5	15%
	4	15%
	3	15%
	'''
	var attributes = []
	for i in 4:
		var rate = randi() % 100
		var value = 0
		for k in rate_table:
			var v = rate_table[k]
			if rate < v:
				value = k
				break
			rate -= v
		attributes.append(value)
	print(attributes)
	$AttributeRoot/Attribute/Power/Value.text = str(attributes[0])
	$AttributeRoot/Attribute/Agility/Value.text = str(attributes[1])
	$AttributeRoot/Attribute/Intell/Value.text = str(attributes[2])
	$AttributeRoot/Attribute/Luck/Value.text = str(attributes[3])
	
	
func _on_ok_create_bt_pressed() -> void:
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
	# 清空角色名
	$RoleNameLineEdit.text = ""
	_random_allocate()


func _on_back_bt_pressed() -> void:
	go_back.emit()
	hide()
