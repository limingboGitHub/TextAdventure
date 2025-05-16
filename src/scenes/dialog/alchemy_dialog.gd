extends Control


var data_alchemy_bag: DataAlchemyBag

var selected_index: int = -1

var make_count: int = 0

signal alchemy_maked(data_alchemy: DataAlchemy, count: int)

func _ready():
	$Back/ItemList.clear()
	$Back/RequireBackPanel/RequireLabel.text = ""


func set_data_alchemy_bag(_data_alchemy_bag: DataAlchemyBag):
	data_alchemy_bag = _data_alchemy_bag
	for data_alchemy in data_alchemy_bag.alchemy_list:
		$Back/ItemList.add_item(data_alchemy.name)

	# 监听炼金配方添加
	data_alchemy_bag.alchemy_added.connect(_on_alchemy_added)


func _on_alchemy_added(data_alchemy: DataAlchemy):
	$Back/ItemList.add_item(data_alchemy.name)


func _on_test_button_pressed() -> void:
	data_alchemy_bag.add_alchemy("alchemy_000001")


func _on_item_list_item_selected(index: int) -> void:
	# 清理上次选中的Item的监听
	if selected_index != -1:
		for require in data_alchemy_bag.alchemy_list[selected_index].requires:
			require.updated.disconnect(_on_require_updated)

	# 展示选中配方的信息
	_show_alchemy_info(index)

	# 计算满足炼金条件的物品数量倍数
	_calculate_make_count(index)

	# 监听选中配方的物品变化
	for require in data_alchemy_bag.alchemy_list[index].requires:
		require.updated.connect(_on_require_updated)

	selected_index = index


func _show_alchemy_info(index: int):
	var data_alchemy = data_alchemy_bag.alchemy_list[index]
	var text = ""
	for require in data_alchemy.requires:
		text += require.item_name + " " + str(require.collect_count) + "/" + str(require.target_count) + "\n"
	$Back/RequireBackPanel/RequireLabel.text = text


func _calculate_make_count(index: int):
	var data_alchemy = data_alchemy_bag.alchemy_list[index]
	# 计算满足炼金条件的物品数量倍数
	var min_count: int = 999999
	for require in data_alchemy.requires:
		var count: int = require.collect_count / require.target_count
		if count < min_count:
			min_count = count
	make_count = min_count
	$MakeCount.text = str(min_count)


func _on_require_updated(_require: MissionRequireCollect):
	_show_alchemy_info(selected_index)
	_calculate_make_count(selected_index)


func _on_make_bt_pressed() -> void:
	if selected_index == -1:
		return

	var count = int($MakeCount.text)
	if count <= 0:
		ToastManager.add_toast("材料不足")
		return
	# 炼金数量不能超过满足炼金条件的物品数量倍数
	if count > make_count:
		count = make_count

	var data_alchemy = data_alchemy_bag.alchemy_list[selected_index]
	alchemy_maked.emit(data_alchemy, count)


func _on_close_button_pressed() -> void:
	hide()
