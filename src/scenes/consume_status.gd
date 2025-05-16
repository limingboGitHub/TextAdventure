extends Control


var data_bag: DataBag

func _ready():
	$HP/Name.text = ""
	$HP/Count.text = ""

	$MP/Name.text = ""
	$MP/Count.text = ""

func init_data(_data_bag: DataBag):
	data_bag = _data_bag

	_update_hp_and_mp()
	# 监听物品的使用
	data_bag.item_used.connect(_on_item_used)
	# 监听物品的添加
	data_bag.item_added.connect(_on_item_added)
	# 监听物品的删除
	data_bag.item_removed.connect(_on_item_removed)


func _on_item_used(item: DataBagItem):
	if item is DataConsume and item.recovery != null:
		call_deferred("_update_hp_and_mp")


func _on_item_added(item: DataBagItem, _index: int):
	if item is DataConsume and item.recovery != null:
		call_deferred("_update_hp_and_mp")


func _on_item_removed(item: DataBagItem, _index: int):
	if item is DataConsume and item.recovery != null:
		call_deferred("_update_hp_and_mp")


func _update_hp_and_mp():
	var min_hp_item = data_bag.find_hp_medicine()
	if min_hp_item:
		set_hp(min_hp_item.name,str(data_bag.get_item_total_count(min_hp_item.id)))
	else:
		set_hp("","")
	var min_mp_item = data_bag.find_mp_medicine()
	if min_mp_item:
		set_mp(min_mp_item.name,str(data_bag.get_item_total_count(min_mp_item.id)))
	else:
		set_mp("","")


func set_hp(_name: String,count: String):
	$HP/Name.text = _name
	$HP/Count.text = count


func set_mp(_name: String, count: String):
	$MP/Name.text = _name
	$MP/Count.text = count
