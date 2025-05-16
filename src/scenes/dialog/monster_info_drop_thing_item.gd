extends HBoxContainer

## 怪物信息框中的掉落物信息

signal item_show_bt_pressed(ui: BagItem)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_drop_thing_item(data_bag_item: DataBagItem, drop_rate: float) -> void:
	$BagItem.set_item(data_bag_item)
	$DropRate.text = str(drop_rate * 100) + "%"


func _on_bag_item_item_show_bt_pressed(ui: BagItem) -> void:
	item_show_bt_pressed.emit(ui)
