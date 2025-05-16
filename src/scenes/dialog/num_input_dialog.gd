extends Panel


var data_bag_item:DataBagItem

signal num_input_ok(data_bag_item:DataBagItem,num: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ok_bt_pressed() -> void:
	# 数字输入框合法性检查
	var num = int($LineEdit.text)
	if num > 0:
		num_input_ok.emit(data_bag_item,num)
		hide()
	else:
		ToastManager.add_toast("请输入正确的数量")


func show_input(_data_bag_item:DataBagItem):
	show()
	self.data_bag_item = _data_bag_item
	# 默认数量为物品数量
	$LineEdit.text = str(_data_bag_item.count)


func _on_cancel_bt_pressed() -> void:
	hide()
