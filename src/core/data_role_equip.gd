class_name DataRoleEquip

## 装备物品字典
## key : 装备类型
## value : 装备物品DataEquip
var items = {}
# 备用装备物品字典
var items2 = {}
var items3 = {}

var items_list = [items, items2, items3]

# 当前生效哪一套装备的索引
var current_equip_index = 0

signal equip_on(data_equip: DataEquip,tab_index: int)

signal equip_off(data_equip: DataEquip,tab_index: int)

signal current_equip_index_changed(index: int,items: Dictionary)
# 装备属性生效
signal equip_attribute_on(data_equip: DataEquip)
# 装备属性失效
signal equip_attribute_off(data_equip: DataEquip)

func add(data_equip: DataEquip)-> Array[DataBagItem]:	
	var replace_equips: Array[DataBagItem] = []
	var _items = items_list[current_equip_index]
	if _items.has(data_equip.equip_type) and not _items[data_equip.equip_type].is_empty():
		replace_equips.append(_items[data_equip.equip_type])
	
	_items[data_equip.equip_type] = data_equip
	equip_attribute_on.emit(data_equip)
	equip_on.emit(data_equip,current_equip_index)
	
	return replace_equips


func remove(data_equip: DataEquip):
	var _items = items_list[current_equip_index]
	_items.erase(data_equip.equip_type)
	equip_attribute_off.emit(data_equip)
	equip_off.emit(data_equip,current_equip_index)


func has_equip(equip_type: String)-> bool:
	var _items = items_list[current_equip_index]
	return _items.has(equip_type)


func get_equip(equip_type: String)-> DataEquip:
	var _items = items_list[current_equip_index]
	return _items[equip_type]
			

# 移除指定装备类型
func remove_by_type(equip_type: String)-> DataEquip:
	var _items = items_list[current_equip_index]
	if not _items.has(equip_type):
		return null
	var data_equip = _items[equip_type]
	_items.erase(equip_type)
	equip_attribute_off.emit(data_equip)
	equip_off.emit(data_equip,current_equip_index)
	return data_equip


# 遍历装备物品字典
func for_each_item(callback: Callable):
	for tab_index in range(items_list.size()):
		var _items = items_list[tab_index]
		for equip_type in _items.keys():
			callback.call(_items[equip_type])


func set_current_equip_index(index: int):
	if current_equip_index == index:
		return
	# 装备属性失效
	for equip_type in items_list[current_equip_index].keys():
		equip_attribute_off.emit(items_list[current_equip_index][equip_type])
	# 装备属性生效
	current_equip_index = index
	for equip_type in items_list[index].keys():
		equip_attribute_on.emit(items_list[index][equip_type])
	# 装备栏切换
	current_equip_index_changed.emit(index,items_list[index])
	

# 保存装备数据
# 如果数组或字典为空，则不进行存储
func save() -> Dictionary:
	var json = {}
	
	# 保存装备物品字典
	if not items.is_empty():
		var items_data = {}
		for equip_type in items.keys():
			items_data[equip_type] = items[equip_type].save()
		json["items"] = items_data

	if not items2.is_empty():
		var items_data = {}
		for equip_type in items2.keys():
			items_data[equip_type] = items2[equip_type].save()
		json["items2"] = items_data

	if not items3.is_empty():
		var items_data = {}
		for equip_type in items3.keys():
			items_data[equip_type] = items3[equip_type].save()
		json["items3"] = items_data
	# 保存当前装备栏
	json["current_equip_index"] = current_equip_index
	return json


# 加载装备数据
func load(dic: Dictionary) -> void:
	# 清空当前数据
	items.clear()
	items2.clear()
	items3.clear()
	
	# 加载装备物品字典
	if dic.has("items"):
		var items_data = dic["items"]
		for equip_type in items_data.keys():
			var data_equip = DataEquip.new()
			data_equip.load(items_data[equip_type])
			items[equip_type] = data_equip
	if dic.has("items2"):
		var items_data = dic["items2"]
		for equip_type in items_data.keys():
			var data_equip = DataEquip.new()
			data_equip.load(items_data[equip_type])
			items2[equip_type] = data_equip
	if dic.has("items3"):
		var items_data = dic["items3"]
		for equip_type in items_data.keys():
			var data_equip = DataEquip.new()
			data_equip.load(items_data[equip_type])
			items3[equip_type] = data_equip
	if dic.has("current_equip_index"):
		current_equip_index = dic["current_equip_index"]
