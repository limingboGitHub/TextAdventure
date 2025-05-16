extends Control

signal debug_exp_added(value: int)

signal debug_item_added(item_id: String)

signal debug_speed_added(speed: int)

signal debug_money_added(money: int)

signal all_consume_added

signal all_job1_added

signal all_job2_added

signal all_job3_added

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_bt_pressed() -> void:
	hide()


func _on_get_exp_bt_pressed() -> void:
	var value = int($LineEdit.text)

	debug_exp_added.emit(value)


func _on_get_item_bt_pressed() -> void:
	var item_id = $ItemEdit.text

	debug_item_added.emit(item_id)


func _on_speed_ok_bt_pressed() -> void:
	var speed = int($SpeedEdit.text)
	SingletonGame.speed = speed


func _on_skill_radius_toggled(toggled_on: bool) -> void:
	SingletonGame.show_skill_radius = toggled_on


func _on_get_money_bt_pressed() -> void:
	var money = int($MoneyEdit.text)
	debug_money_added.emit(money)


func _on_scroll_bt_pressed() -> void:
	all_consume_added.emit()


func _on_job_1_bt_pressed() -> void:
	all_job1_added.emit()


func _on_job_2_bt_pressed() -> void:
	all_job2_added.emit()


func _on_job_3_bt_pressed() -> void:
	all_job3_added.emit()
