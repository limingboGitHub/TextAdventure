extends BaseDropThing


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	#set_money(1000)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)


func set_money(data_money: DataMoney):
	name = data_money.uuid

	var style = "1"
	if data_money.count < 100:
		style = "1"
	elif data_money.count >= 100 and data_money.count <1000:
		style = "2"
	else:
		style = "3"
	var style_box = load("res://theme/item/money_style" + style +".tres")
	add_theme_stylebox_override("panel",style_box)
