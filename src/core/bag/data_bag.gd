class_name DataBag

## 背包物品
## key : tab_name
## value : Array[DataBagItem]
var items_dic: Dictionary = {}

var tab_names = [
	DataBagItem.TYPE_EQUIP,
	DataBagItem.TYPE_CONSUME,
	DataBagItem.TYPE_ETC
]
var recycles: Array = []

var capcity: Dictionary = {
	DataBagItem.TYPE_EQUIP: 50,
	DataBagItem.TYPE_CONSUME: 50,
	DataBagItem.TYPE_ETC: 50
}

var money: int = 0

## 物品数量字典
## 
## 该字典的作用：当物品添加或者移除时，更新物品数量字典
## 当背包物品发生变化时，通过该字典可以快速获取物品的总数量
## 而不用遍历背包物品。
##
## *该数据不做持久化存储，在背包数据初始化加载完毕后需要刷新
## key : item_id
## value : item_count
var item_count_dic: Dictionary = {}

signal item_added(item: DataBagItem, item_index: int)

signal item_removed(item: DataBagItem, item_index: int)

signal item_updated(item: DataBagItem, item_index: int)

signal item_used(item: DataBagItem)

signal item_removed_recycle(item: DataBagItem, item_index: int)

signal money_changed(money: int)

signal item_count_changed(item_id: String, item_count: int)

signal scroll_ready_used(item: DataConsume, equips: Array[DataEquip])

signal scroll_used_success(item: DataConsume, equip: DataEquip)

signal scroll_used_failed(item: DataConsume, equip: DataEquip)

func _init() -> void:
	# 初始化背包物品
	for tab_name in tab_names:
		items_dic[tab_name] = []


## 添加物品到背包，可能失败
func add_item(item: DataBagItem) -> bool:
	return _add_attempt_slot(item, items_dic[item.type])


## 将物品添加到空的背包槽位中
## @param item: DataBagItem 要添加的物品
## @param item_array: Array 物品数组
## @return bool 是否成功添加物品
func _add_empty(item: DataBagItem, item_array: Array) -> bool:
	# 检查背包是否已满
	if item_array.size() >= capcity[item.type]:
		# 如果背包已满，返回false
		return false

	# 将物品添加到背包中
	item_array.append(item)
	# 调用添加物品成功的处理函数
	_add_item_success(item, item_array.size() - 1)
	# 更新物品数量字典
	_update_item_count_dic(item.id, item.count)
	# 返回true表示添加成功
	return true
	

## 尝试将物品添加到已有的堆叠槽位中，如果没有可堆叠的位置，则加入空位置
## @param item: DataBagItem 要添加的物品
## @param items: Array 物品数组
## @return bool 是否成功添加物品
func _add_attempt_slot(item: DataBagItem, items) -> bool:
	# 遍历物品数组，查找是否有可以堆叠的位置
	for i in items.size():
		var now_item: DataBagItem = items[i]
		# 如果找到相同ID且未达到最大堆叠数量的物品，则将新物品数量加到该位置
		if now_item.id == item.id and now_item.count < now_item.slot_max:
			# 需要计算可堆叠的数量
			var can_add: int = min(item.count, now_item.slot_max - now_item.count)
			now_item.count += can_add
			item.count -= can_add
			# 更新物品数据
			item_updated.emit(now_item, i)
			# 更新物品数量字典
			_update_item_count_dic(now_item.id, can_add)
			# 如果还有剩余物品需要继续处理
			if item.count <= 0:
				return true
	# 如果没有可堆叠的位置，则加入空位置
	return _add_empty(item, items)


func _add_item_success(item: DataBagItem, item_index: int):
	item_added.emit(item, item_index)


## 根据索引移出物品 FIXME 可能会删除失败
func remove_item_by_index(items: Array, item_index: int, count: int) -> DataBagItem:
	if items[item_index].is_empty():
		return null
	else:
		var to_removed = items[item_index]
		if to_removed.count > count:
			to_removed.count -= count
			# 更新物品数量字典
			_update_item_count_dic(to_removed.id, -count)
			# 发送物品更新信号
			item_updated.emit(to_removed, item_index)
			# 返回删除掉的堆叠物品时，需要复制一个新的类，改变其数量
			var removed = to_removed.copy()
			removed.count = count
			return removed
		elif to_removed.count == count:
			items.remove_at(item_index)
			# 更新物品数量字典
			_update_item_count_dic(to_removed.id, -count)
			# 发送物品删除信号
			item_removed.emit(to_removed, item_index)
			return to_removed
		else:
			# 删除失败
			return null
			
		
## 移除物品
func remove_item(to_remove_item: DataBagItem, count: int):
	var type_items = []
	if to_remove_item.is_recycle:
		type_items = recycles
	else:
		type_items = items_dic[to_remove_item.type]
	for item_index in type_items.size():
		if to_remove_item.uuid == type_items[item_index].uuid:
			return remove_item_by_index(type_items, item_index, count)
	return null


## 消耗物品
## 
## 区别于移除物品，消耗物品时，除了将对象从背包拿出来，还需要减少物品的数量
func consume_item(item: DataBagItem, count: int):
	var removed = remove_item(item, count)
	if removed != null:
		removed.count -= count


## 根据物品id移除物品 FIXME 可能会删除失败
func remove_item_by_id(item_id: String, count: int):
	for tab_name in items_dic.keys():
		for item_index in items_dic[tab_name].size():
			var item = items_dic[tab_name][item_index]
			if item.id == item_id:
				var to_remove_item = remove_item_by_index(items_dic[tab_name], item_index, count)
				# 删除成功就结束
				if to_remove_item != null:
					break


## 获得物品
func get_item(index: int, tab_name: String) -> DataBagItem:
	return items_dic[tab_name][index]


## 获取某种物品的总数量
func get_item_total_count(item_id: String) -> int:
	if item_count_dic.has(item_id):
		return item_count_dic[item_id]
	return 0


## 更新物品数量字典
func _update_item_count_dic(item_id: String, count_change: int) -> void:
	if not item_count_dic.has(item_id):
		item_count_dic[item_id] = 0
	item_count_dic[item_id] += count_change
	if item_count_dic[item_id] <= 0:
		item_count_dic.erase(item_id)
	item_count_changed.emit(item_id, item_count_dic.get(item_id, 0))


## 交换物品
func exchange_item(item1: DataBagItem, item2: DataBagItem):
	pass


## 整理物品，按照id排序
func sort_item():
	for items in items_dic.values():
		items.sort()


## 删除选择的物品
func remove_selected_item() -> void:
	for tab_name in items_dic.keys():
		var item_index = 0
		while item_index < items_dic[tab_name].size():
			var item = items_dic[tab_name][item_index]
			if item.is_selected:
				items_dic[tab_name].remove_at(item_index)
				# 更新物品数量字典
				_update_item_count_dic(item.id, -item.count)
				item_removed.emit(item, item_index)
			else:
				item_index += 1


func use_item(item: DataBagItem) -> void:
	if item.is_empty():
		return
	assert(item.count > 0)
	
	item_used.emit(item)


## 查找hp回复值最小的药品，使用
func find_hp_medicine_and_use() -> bool:
	var min_hp_item = find_hp_medicine()

	if min_hp_item != null:
		use_item(min_hp_item)
		return true
	return false


func find_hp_medicine() -> DataBagItem:
	# 最小的固定恢复值的药品
	var min_hp = INF
	var min_hp_item = null
	# 最小的百分比恢复值的药品
	var min_hp_r = INF
	var min_hp_r_item = null

	for tab_name in items_dic.keys():
		for item_index in items_dic[tab_name].size():
			var item = items_dic[tab_name][item_index]
			if item is DataConsume and item.recovery != null:
				if item.recovery.spec_hp > 0 and item.recovery.spec_hp < min_hp:
					min_hp = item.recovery.spec_hp
					min_hp_item = item
				if item.recovery.spec_hp_r > 0 and item.recovery.spec_hp_r < min_hp_r:
					min_hp_r = item.recovery.spec_hp_r
					min_hp_r_item = item
	if min_hp_item != null:
		return min_hp_item
	elif min_hp_r_item != null:
		return min_hp_r_item
	return null


func find_mp_medicine_and_use() -> bool:
	var min_mp_item = find_mp_medicine()
	if min_mp_item != null:
		use_item(min_mp_item)
		return true
	return false


func find_mp_medicine() -> DataBagItem:
	# 最小的固定恢复值的药品
	var min_mp = INF
	var min_mp_item = null
	# 最小的百分比恢复值的药品
	var min_mp_r = INF
	var min_mp_r_item = null

	for tab_name in items_dic.keys():
		for item_index in items_dic[tab_name].size():
			var item = items_dic[tab_name][item_index]
			if item is DataConsume and item.recovery != null:
				if item.recovery.spec_mp > 0 and item.recovery.spec_mp < min_mp:
					min_mp = item.recovery.spec_mp
					min_mp_item = item
				if item.recovery.spec_mp_r > 0 and item.recovery.spec_mp_r < min_mp_r:
					min_mp_r = item.recovery.spec_mp_r
					min_mp_r_item = item
	if min_mp_item != null:
		return min_mp_item
	elif min_mp_r_item != null:
		return min_mp_r_item
	return null


func add_recycle(item: DataBagItem) -> void:
	item.is_recycle = true
	# 尝试将物品添加到回收栏中
	_add_attempt_slot(item, recycles)


func remove_recycle(item: DataBagItem) -> void:
	for i in recycles.size():
		if recycles[i] == item:
			recycles.remove_at(i)
			item.is_recycle = false
			item_removed_recycle.emit(item, i)
			return


func have_item(item_id: String, count: int) -> bool:
	return get_item_total_count(item_id) >= count


func add_money(_money: int) -> void:
	self.money += _money
	money_changed.emit(self.money)


# 检查背包是否能放下指定数量的物品
func check_bag_space(item: DataBagItem, count: int) -> bool:
	var rest_count = count
	var type_items = items_dic[item.type]
	
	# 先计算已有槽位的剩余空间
	for i in type_items.size():
		var now_item = type_items[i]
		if now_item.id == item.id and now_item.count < now_item.slot_max:
			var can_add = now_item.slot_max - now_item.count
			rest_count -= can_add
			if rest_count <= 0:
				return true
	
	# 再计算需要的新槽位数量（考虑堆叠上限）
	if rest_count > 0:
		var needed_slots = ceil(float(rest_count) / item.slot_max)
		var available_slots = capcity[item.type] - type_items.size()
		return available_slots >= needed_slots
	
	return true


# 准备使用卷轴类物品
func ready_use_scroll(item: DataConsume) -> void:
	if item.scroll == null:
		return
	# 根据当前卷轴的使用类型，找出背包中符合要求的装备
	var equips: Array[DataEquip] = []
	for equip in items_dic[DataBagItem.TYPE_EQUIP]:
		if (equip.equip_type == item.scroll.use_type or item.scroll.use_type == "") and equip.can_upgrade():
			equips.append(equip)
	# 发出准备对装备进行卷轴操作的信号
	scroll_ready_used.emit(item, equips)


# 使用卷轴，根据卷轴的强化属性，增加到装备上
func use_scroll(item: DataConsume, equip: DataEquip) -> void:
	if randf() < item.scroll.success_rate:
		# 根据卷轴的强化属性，增加到装备上
		equip.upgrade_success(
			item.scroll.attribute_ability, 
			item.scroll.attribute_details, 
			item.scroll.data_effect)
		# 发出使用卷轴成功的信号
		scroll_used_success.emit(item, equip)
	else:
		equip.upgrade_failed()
		scroll_used_failed.emit(item, equip)

	# 使用后减少数量
	consume_item(item, 1)


## 遍历背包中的所有物品
## @param callback: Callable 回调函数
func for_each_item(callback: Callable) -> void:
	for tab_items in items_dic.values():
		for item in tab_items:
			callback.call(item)


func save() -> Dictionary:
	var dic = {}
	# 遍历items_dic，将每个标签页中的物品保存
	var items_dic_save = {}
	for tab_name in items_dic.keys():
		var items = []
		for item in items_dic[tab_name]:
			items.append(item.save())
		items_dic_save[tab_name] = items
	dic["items_dic"] = items_dic_save

	# 保存recycles
	var recycles_save = []
	for item in recycles:
		recycles_save.append(item.save())
	if recycles_save.size() > 0:
		dic["recycles"] = recycles_save

	# 保存money
	dic["money"] = money

	return dic


func load(dic: Dictionary):
	# 遍历items_dic，将每个标签页中的物品加载
	for tab_name in dic["items_dic"].keys():
		for item in dic["items_dic"][tab_name]:
			if DataEquip.is_equip(item.id):
				var data_equip = DataEquip.new()
				data_equip.load(item)
				items_dic[tab_name].append(data_equip)
			elif DataConsume.is_consume(item.id):
				var data_consume = DataConsume.new()
				data_consume.load(item)
				items_dic[tab_name].append(data_consume)
			elif DataEtc.is_etc(item.id):
				var data_etc = DataEtc.new()
				data_etc.load(item)
				items_dic[tab_name].append(data_etc)
	# 加载recycles
	if dic.has("recycles"):
		for item in dic["recycles"]:
			var data_bag_item = DataBagItem.new()
			data_bag_item.load(item)
			recycles.append(data_bag_item)
	# 加载money
	money = dic["money"]

	#region 根据items_dic更新item_count_dic字典
	# 清空当前的物品数量字典
	item_count_dic.clear()
	# 遍历所有背包标签页
	for tab_name in items_dic.keys():
		# 遍历该标签页中的所有物品
		for item in items_dic[tab_name]:
			# 更新物品数量字典
			_update_item_count_dic(item.id, item.count)
	#endregion
