extends Control


signal monster_info_bt_pressed()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_monster_info_bt_pressed() -> void:
	monster_info_bt_pressed.emit()


func _on_close_button_pressed() -> void:
	hide()
