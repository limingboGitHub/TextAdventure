extends Control

# 层数
var data_map: DataMap
# 开始时间(毫秒)
var start_time : int = 0
var end_time : int = 0

signal endless_exit()


func init_data(_data_map: DataMap):
	self.data_map = _data_map
	# 监听无尽之塔结束事件
	data_map.endless_ended.connect(_on_endless_ended)
	# 监听玩家退出
	data_map.player_removed.connect(_on_player_removed)


func _on_player_removed(_data_map: DataMap, _data_player: DataPlayer):
	stop()
	reset()


func _on_endless_ended(_data_map: DataMap):
	$Timer.stop()
	$Panel1/StartBt.disabled = _data_map.is_endless_max()


func reset():
	start_time = 0
	$Panel1/Time.text = "用时：0秒"
	$Panel2.text = "用时：0秒"
	$Panel1/Layer/Label.text = "1"
	$Panel1/Damage/Label.text = "0"
	$Panel1/StartBt.disabled = false


func stop():
	$Timer.stop()
	end_time = Time.get_ticks_msec()


func update_damage(damage: int):
	$Panel1/Damage/Label.text = str(damage)


func _on_panel_2_pressed() -> void:
	# 隐藏pannel2 显示pannel1
	$Panel2.hide()
	$Panel1.show()


func _on_start_bt_pressed() -> void:
	# 开始记时
	$Timer.start()
	start_time = Time.get_ticks_msec()
	# 开始无尽之塔
	data_map.start_endless()
	# 更新层数
	$Panel1/Layer/Label.text = str(data_map.endless_layer)
	
	# 禁用开始按钮
	$Panel1/StartBt.disabled = true


func _on_title_bt_pressed() -> void:
	$Panel1.hide()
	$Panel2.show()


func _on_timer_timeout() -> void:
	# 更新时间（显示为n分m秒）
	var time = Time.get_ticks_msec() - start_time
	var minute = int(time / 60000.0)
	var second = int((time % 60000) / 1000.0)
	if minute > 0:
		$Panel1/Time.text = "用时：" + str(minute) + "分" + str(second) + "秒"
		$Panel2.text = "用时：" + str(minute) + "分" + str(second) + "秒"
	else:
		$Panel1/Time.text = "用时：" + str(second) + "秒"
		$Panel2.text = "用时：" + str(second) + "秒"


func _on_exit_bt_pressed() -> void:
	endless_exit.emit()
