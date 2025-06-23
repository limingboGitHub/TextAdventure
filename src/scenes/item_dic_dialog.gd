extends Control

## 物品出处信息
## {
##   "etc": {
##     "etc_0000001": {
##       "name": "物品名称",
##       "desc": "物品描述",
##       "type": "物品类型",
##       "from": "物品出处"
##     }
##   },
##   "weapon": {
##     "weapon_0000001": {
##       "name": "武器名称",
##       "desc": "武器描述",
##       "type": "武器类型",
##       "from": "武器出处"
##     }
##   }
## }
var item_from_info: Dictionary
## 物品分类展示的顺序
var item_category_order = [
	"weapon",
	"upper",
	"lower",
	"shoes",
	"cap",
	"consume",
	"etc"
]

var dropthing_manager: DropThingManager

@onready var tab_container = $Back/TabContainer

signal item_show_bt_pressed(bag_item: BagItem)

func _ready():
	for child in tab_container.get_children():
		child.queue_free()


func set_data(data: Dictionary, _dropthing_manager: DropThingManager):
	item_from_info = data
	self.dropthing_manager = _dropthing_manager
	
	for tab in item_category_order:
		# tab转换为中文
		var tab_name = _tab_name_to_chinese(tab)

		var scroll_container: ScrollContainer = ScrollContainer.new()
		var vbox_container: VBoxContainer = VBoxContainer.new()
		scroll_container.name = tab_name
		for item_id in data[tab].keys():
			var data_bag_item = dropthing_manager.create_item(item_id,false)
			var item_from_info_scene = SingletonGameScenePre.ItemFromInfoScene.instantiate()
			item_from_info_scene.set_data(data_bag_item, data[tab][item_id])
			vbox_container.add_child(item_from_info_scene)
			# 监听item点击事件
			item_from_info_scene.item_show_bt_pressed.connect(_on_item_show_bt_pressed)
		scroll_container.add_child(vbox_container)
		tab_container.add_child(scroll_container)

func _tab_name_to_chinese(tab_name: String) -> String:
	match tab_name:
		"etc":
			return "材料"
		"weapon":
			return "武器"
		"cap":
			return "帽子"
		"upper":
			return "衣服"
		"lower":
			return "裤子"
		"shoes":
			return "鞋子"
		"consume":
			return "消耗品"
		_:
			return tab_name


func _on_close_button_pressed() -> void:
	hide()


func _on_item_show_bt_pressed(bag_item: BagItem):
	item_show_bt_pressed.emit(bag_item)
