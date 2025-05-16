extends Control

## 商店对话框

# 商店背包
var shop_bag : DataBag
# 玩家背包
var player_bag : DataBag
# 掉落物管理器
var drop_thing_manager : DropThingManager

const RECYCLE_TAB = "购回"

const SHOP_BT_BUY = "购买"
const SHOP_BT_SELL = "出售"


signal item_show_pressed(ui:BagItem)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	# test()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_bag(shop_bag:DataBag,player_bag:DataBag,dropthing_manager:DropThingManager):
	self.shop_bag = shop_bag
	self.player_bag = player_bag
	self.drop_thing_manager = dropthing_manager

	# 初始化商店背包
	_clear_container($ShopBag)
	for tab_name in shop_bag.items_dic.keys():
		var items = shop_bag.items_dic[tab_name]

		_add_shop_tab(tab_name,items)
		
	# 商店增加一栏购回tab
	_add_shop_tab(RECYCLE_TAB,shop_bag.recycles)
	# TODO 优先将tab切换到第一个有物品的tab
	
	# 初始化玩家背包
	_clear_container($PlayerBag)
	for tab_name in player_bag.items_dic.keys():
		var items = player_bag.items_dic[tab_name]
		# 展示tab
		var items_scene = SingletonGameScenePre.BagTabScene.instantiate()
		items_scene.name = tab_name
		items_scene.set_data(items,SHOP_BT_SELL)
		# 监听物品展示
		items_scene.item_show_pressed.connect(func(ui:BagItem):
			item_show_pressed.emit(ui)
		)
		# 监听商店按钮
		items_scene.shop_bt_pressed.connect(_on_shop_bt_sell_pressed)
		$PlayerBag.add_child(items_scene)
	# 显示金钱
	$Money/Value.text = str(player_bag.money)

	# 监听背包物品移除事件
	player_bag.item_added.connect(_player_bag_item_added)
	player_bag.item_removed.connect(_player_bag_item_removed)
	player_bag.item_updated.connect(_player_bag_item_updated)
	# 监听商店物品移除事件
	shop_bag.item_added.connect(_shop_bag_item_added_recycle)
	shop_bag.item_removed.connect(_shop_bag_item_removed_recycle)
	shop_bag.item_updated.connect(_shop_bag_item_updated_recycle)
	show()


func _add_shop_tab(tab_name: String,items:Array):
	var items_scene = SingletonGameScenePre.BagTabScene.instantiate()
	items_scene.name = tab_name
	items_scene.set_data(items,SHOP_BT_BUY)
	# 监听商店按钮
	items_scene.shop_bt_pressed.connect(_on_shop_bt_buy_pressed)
	# 监听物品展示
	items_scene.item_show_pressed.connect(func(ui:BagItem):
		item_show_pressed.emit(ui)
	)
	$ShopBag.add_child(items_scene)


func _clear_container(container: Control):
	for item in container.get_children():
		container.remove_child(item)
		item.queue_free()


func test():
	# 创建一个商店背包
	var shop_bag = DataBag.new()
	# 装备tab增加一个物品
	var equip = DataEquip.new()
	equip.id = "01302000"
	equip.name = "剑"
	equip.price = 10

	shop_bag.add_item(equip)

	# 创建一个玩家背包
	var player_bag = DataBag.new()
	# 装备tab增加一个物品
	var equip2 = DataEquip.new()
	equip2.id = "01302000"
	equip2.name = "剑"
	equip2.price = 10
	player_bag.add_item(equip2)
	player_bag.money = 5

	# 初始化商店背包
	# set_bag(shop_bag,player_bag)


func _on_shop_bt_sell_pressed(data_bag_item:DataBagItem):
	# 判断物品数量是否大于1
	if data_bag_item.count > 1:
		# 展示数量确认窗口
		$NumInputDialog.show_input(data_bag_item)
		# 监听数量确认事件
		if $NumInputDialog.num_input_ok.is_connected(_on_buy_num_input_ok):
			$NumInputDialog.num_input_ok.disconnect(_on_buy_num_input_ok)
		if not $NumInputDialog.num_input_ok.is_connected(_on_num_input_ok):
			$NumInputDialog.num_input_ok.connect(_on_num_input_ok)
	else:
		_sell_item(data_bag_item,1)
	

func _sell_item(data_bag_item:DataBagItem,sell_count:int):
	# 从玩家背包移除
	var removed_item = player_bag.remove_item(data_bag_item,sell_count)
	if removed_item != null:
		# 添加到商店背包的购回栏
		shop_bag.add_recycle(removed_item)
		
		# 增加金钱
		player_bag.add_money(removed_item.price * sell_count)
		_update_money(player_bag.money)


func _on_shop_bt_buy_pressed(data_bag_item:DataBagItem):
	print("_on_shop_bt_buy_pressed:",data_bag_item)
	# 判断物品数量是否大于1
	if data_bag_item.slot_max > 1:
		# 展示数量确认窗口
		$NumInputDialog.show_input(data_bag_item)
		# 监听数量确认事件
		if $NumInputDialog.num_input_ok.is_connected(_on_num_input_ok):
			$NumInputDialog.num_input_ok.disconnect(_on_num_input_ok)
		if not $NumInputDialog.num_input_ok.is_connected(_on_buy_num_input_ok):
			$NumInputDialog.num_input_ok.connect(_on_buy_num_input_ok)
	else:
		_buy_item(data_bag_item,1)
	

func _buy_item(data_bag_item:DataBagItem,buy_count:int):
	# 检查玩家背包是否有足够的钱
	if player_bag.money < data_bag_item.price * buy_count:
		# 添加弹窗提示
		ToastManager.add_toast("金钱不足")
		return
	
	# 先检查玩家背包是否有足够的空间
	if !player_bag.check_bag_space(data_bag_item,buy_count):
		# 添加弹窗提示
		ToastManager.add_toast("背包空间不足")
		return

	var to_buy_item = null
	# 从商店回收背包移除
	if data_bag_item.is_recycle:
		to_buy_item = shop_bag.remove_item(data_bag_item,buy_count)
		to_buy_item.is_recycle = false
	else:
		# 重新生成一个物品
		to_buy_item = drop_thing_manager.create_item(data_bag_item.id)
		to_buy_item.count = buy_count

	if to_buy_item != null:
		# 添加到玩家背包
		player_bag.add_item(to_buy_item)

		# 减少金钱
		player_bag.add_money(-data_bag_item.price * buy_count)
		_update_money(player_bag.money)


func _update_money(value: int):
	$Money/Value.text = str(value)


func _on_add_money_bt_pressed() -> void:
	player_bag.add_money(1000)
	_update_money(player_bag.money)


func _player_bag_item_added(item: DataBagItem, _item_index: int):
	$PlayerBag.get_node(item.type).add_item(item,SHOP_BT_SELL)


func _player_bag_item_removed(item: DataBagItem, item_index: int):
	$PlayerBag.get_node(item.type).remove_item(item,item_index)


func _player_bag_item_updated(item: DataBagItem, item_index: int):
	$PlayerBag.get_node(item.type).update_item(item,item_index)


func _shop_bag_item_added_recycle(item: DataBagItem, _item_index: int):
	$ShopBag.get_node(RECYCLE_TAB).add_item(item,SHOP_BT_BUY)


func _shop_bag_item_removed_recycle(item: DataBagItem, item_index: int):
	$ShopBag.get_node(RECYCLE_TAB).remove_item(item,item_index)


func _shop_bag_item_updated_recycle(item: DataBagItem, item_index: int):
	$ShopBag.get_node(RECYCLE_TAB).update_item(item,item_index)


func _on_close_button_pressed() -> void:
	hide()


func _on_num_input_ok(data_bag_item:DataBagItem,num: int):
	if num >= data_bag_item.count:
		_sell_item(data_bag_item,data_bag_item.count)
	else:
		_sell_item(data_bag_item,num)


func _on_buy_num_input_ok(data_bag_item:DataBagItem,num: int):
	#if num >= data_bag_item.count:
	#	_buy_item(data_bag_item,data_bag_item.count)
	#else:
	_buy_item(data_bag_item,num)
