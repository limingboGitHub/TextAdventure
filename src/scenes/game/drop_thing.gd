extends BaseDropThing

## 掉落物品场景

var item_data:DataBagItem


var color_common = Color.hex(0x999999ff)
var color_good = Color.hex(0x7ac8ffff)
var color_rare = Color.hex(0x9973ffff)
var color_epic = Color.hex(0xc78c51ff)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	# 测试代码
	# _set_back_color(DataBagItem.QUALITY_EPIC)

	# $GPUParticles2D.emitting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)


func set_item(data_bag_item:DataBagItem):
	item_data = data_bag_item
	# 场景名称设置为uuid，方便查找
	name = data_bag_item.uuid
	# 设置物品名称
	$Back/HBoxContainer/Label.text = data_bag_item.name

	# 设置背景颜色
	_set_back_color(data_bag_item.quality)


func _set_back_color(quality: String):
	var style_box = $Back.get_theme_stylebox("panel").duplicate()

	match quality:
		DataBagItem.QUALITY_COMMON:
			style_box.bg_color = color_common
		DataBagItem.QUALITY_GOOD:
			style_box.bg_color = color_good
		DataBagItem.QUALITY_RARE:
			style_box.bg_color = color_rare
		DataBagItem.QUALITY_EPIC:
			style_box.bg_color = color_epic
			$GPUParticles2D.emitting = true
	$Back.add_theme_stylebox_override("panel", style_box)
