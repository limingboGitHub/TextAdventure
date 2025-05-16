'''
生成背包物品的工厂
'''
class_name DataBagItemCreateFactory

static func create_item(id: String,config)-> DataBagItem:
	var item = DataBagItem.new()
	item.id = id

	# 根据id中的前4位判断物品类型，0121-0172装备，0200-0299消耗品，0300-0399设置，0400-0499其他，0500-0599特殊
	var type = id.substr(0,4)
	var type_int = int(type)
	
	
	if type_int >= 100 and type_int <= 199:
		var string_id = id.substr(1,id.length())
		
		var equip_name : String
		if type_int >= 100 and type_int <= 104:
			equip_name = "Cap"
		elif type_int >= 105 and type_int <= 106:
			equip_name = "Longcoat"
		elif type_int >= 107 and type_int <= 107:
			equip_name = "Shoes"
		elif type_int >= 121 and type_int <= 172:
			equip_name = "Weapon"
		# if GameResManager.single().equip_string_config.has("Eqp."+equip_name+"."+string_id+".name"):
		# 	item.name = GameResManager.single().equip_string_config["Eqp."+equip_name+"."+string_id+".name"]
			
	# elif type_int >= 200 and type_int <= 299:
	# 	var info = FileTool.read_bag_item_config("0200")
	# 	var string_id = id.substr(1,id.length())
	# 	item.name = GameResManager.single().consume_string_config[string_id+".name"]
	# 	item.desc = GameResManager.single().consume_string_config[string_id+".desc"]
	# 	# 堆叠上限
	# 	if info.has(id + ".info.slotMax"):
	# 		item.slot_max = int(info[id + ".info.slotMax"])
	elif type_int >= 300 and type_int <= 399:
		pass
	# elif type_int >= 400 and type_int <= 499:
	# 	var info = FileTool.read_bag_item_config("0400")
	# 	var string_id = id.substr(1,id.length())
	# 	item.name = GameResManager.single().etc_string_config["Etc."+string_id+".name"]
	# 	item.desc = GameResManager.single().etc_string_config["Etc."+string_id+".desc"]
	# 	# 堆叠上限
	# 	if info.has(id + ".info.slotMax"):
	# 		item.slot_max = int(info[id + ".info.slotMax"])
	print('创建物品：',type_int,' texture:',item.texture)
	item.count = 1
	return item
