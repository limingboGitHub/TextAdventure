extends Control

# 物品出处信息
# {
#   "monsters": [
#     {
#       "monster_id": "怪物id",
#       "monster_name": "怪物名称",
#       "drop_rate": "掉落概率",
#       "maps": [
#         {
#           "map_id": "地图id",
#           "map_name": "地图名称"
#         }
#       ]
#     }
#   ]
# }
var item_from_info: Dictionary
var bag_item: DataBagItem


signal item_show_bt_pressed(bag_item: BagItem)
	

func _ready():
	if bag_item:
		var bag_item_scene = $BagItem
		# 展示物品的随机属性列表
		bag_item.is_random_attribute_crate = true
		# 展示物品信息
		$BagItem.set_item(bag_item,false)
		# 展示掉落怪物名称
		$Monster/Label.text = item_from_info["monsters"][0]["monster_name"]
		# 展示掉落地图名称
		$Map/Label.text = item_from_info["monsters"][0]["maps"][0]["map_name"]
		# 监听物品信息点击事件
		bag_item_scene.item_show_bt_pressed.connect(_on_item_show_bt_pressed)


func set_data(_bag_item: DataBagItem, data: Dictionary):
	item_from_info = data
	self.bag_item = _bag_item


func _on_item_show_bt_pressed(_bag_item: BagItem):
	item_show_bt_pressed.emit(_bag_item)
