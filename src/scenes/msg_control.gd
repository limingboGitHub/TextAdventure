extends Control

## 消息展示控件
##
## 消息有最大显示容量，超过最大容量后，会从最老的消息开始删除
var max_msg_count = 30

var test_index = 0


func _ready():
	# 初始化消息控件
	$PanelContainer/ItemList.clear()


func add_msg(msg:String):
	var item_list = $PanelContainer/ItemList
	item_list.add_item(msg)
	
	# 超过最大消息数量时，删除最早的消息
	if item_list.get_item_count() > max_msg_count:
		item_list.remove_item(0)
	
	# 获取新添加项的索引
	var new_item_index = item_list.get_item_count() - 1
	
	# 选中新添加的项
	item_list.select(new_item_index)
	
	# 确保选中的项可见（滚动列表）
	item_list.ensure_current_is_visible()


func _on_add_msg_button_pressed() -> void:
	add_msg("测试消息" + str(test_index))
	test_index += 1
