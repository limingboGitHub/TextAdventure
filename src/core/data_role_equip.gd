class_name DataRoleEquip

## 装备物品字典
## key : 装备类型
## value : 装备物品DataEquip
var items = {}

# TODO 指环装备，允许装备2件
var rings = []
const ring_count = 2

signal equip_on(data_equip: DataEquip)

signal equip_off(data_equip: DataEquip)

func add(data_equip: DataEquip)-> Array[DataBagItem]:	
	var replace_equips: Array[DataBagItem] = []
	if items.has(data_equip.equip_type) and not items[data_equip.equip_type].is_empty():
		replace_equips.append(items[data_equip.equip_type])
	
	items[data_equip.equip_type] = data_equip
	equip_on.emit(data_equip)
	
	return replace_equips


func remove(data_equip: DataEquip):
	equip_off.emit(data_equip)
	items.erase(data_equip.equip_type)


func has_equip(equip_type: String)-> bool:
	return items.has(equip_type)


func get_equip(equip_type: String)-> DataEquip:
	return items[equip_type]
			

# 移除指定装备类型
func remove_by_type(equip_type: String)-> DataEquip:
	if not items.has(equip_type):
		return null
	var data_equip = items[equip_type]
	items.erase(equip_type)
	equip_off.emit(data_equip)
	return data_equip


# 遍历装备物品字典
func for_each_item(callback: Callable):
	for equip_type in items.keys():
		callback.call(items[equip_type])


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
	
	# 保存指环装备数组
	if not rings.is_empty():
		var rings_data = []
		for ring in rings:
			rings_data.append(ring.save())
		json["rings"] = rings_data
	
	return json


# 加载装备数据
func load(dic: Dictionary) -> void:
	# 清空当前数据
	items.clear()
	rings.clear()
	
	# 加载装备物品字典
	if dic.has("items"):
		var items_data = dic["items"]
		for equip_type in items_data.keys():
			var data_equip = DataEquip.new()
			data_equip.load(items_data[equip_type])
			items[equip_type] = data_equip
	
	# 加载指环装备数组
	if dic.has("rings"):
		var rings_data = dic["rings"]
		for ring_data in rings_data:
			var data_equip = DataEquip.new()
			data_equip.load(ring_data)
			rings.append(data_equip)
