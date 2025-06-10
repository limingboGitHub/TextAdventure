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


func set_data(bag_item: DataBagItem, data: Dictionary):
	item_from_info = data
	# 展示物品信息
	$BagItem.set_item(bag_item,false)
	# 展示掉落怪物名称
	$Monster/Label.text = item_from_info["monsters"][0]["monster_name"]
	# 展示掉落地图名称
	$Map/Label.text = item_from_info["monsters"][0]["maps"][0]["map_name"]
