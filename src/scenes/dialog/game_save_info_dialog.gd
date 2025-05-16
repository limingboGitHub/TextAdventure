extends Control

# 存档信息弹窗

# 按钮组
var button_group = ButtonGroup.new()

signal game_save_selected(player_id: String)

signal game_save_deleted(player_id: String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 清除存档信息展示
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_delete_game_save_bt_pressed() -> void:
	# TODO 删除存档数据
	game_save_deleted.emit(button_group.get_pressed_button().name)

	# 删除显示
	var node_name = button_group.get_pressed_button().name
	$ScrollContainer/VBoxContainer.get_node(NodePath(node_name)).queue_free()


func _on_select_game_save_bt_pressed() -> void:
	# 读取存档进入游戏
	game_save_selected.emit(button_group.get_pressed_button().name)
	hide()


func _on_close_button_pressed() -> void:
	hide()

