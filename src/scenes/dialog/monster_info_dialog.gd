extends Control


## 资源管理器
var res_manager: ResManager = null
## 掉落物管理器
var drop_thing_manager: DropThingManager = null
## 地图数据
var map_dic: Dictionary = {}

# 展示的地图列表信息
var map_list: Array = []
# 地图名称和地图id的映射
var map_name_id_map: Dictionary = {}

# 当前展示的地图id
var current_map_id: String = ""

# 怪物ID和地图ID的映射，方便通过怪物ID获取怪物所在地图位置，查找到地图里的怪物击杀数量信息
var monster_id_map_id_map: Dictionary = {}

signal item_show_bt_pressed(ui: BagItem)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# 清除地图选择菜单的数据
	_clear_map_container()
	# 清除怪物信息展示容器
	_clear_monster_info_container()
	# 清除物品掉落信息展示容器
	_clear_drop_thing_info_container()

	# 清空怪物数量展示
	$MonsterInfo/KillCountTitle/Label.text = "0"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## 初始化数据注入
##
## res_manager: 资源管理器，地图、怪物、掉落物等数据
## drop_thing_manager: 掉落物管理器，根据掉落物id生成相关数据
## map_dic: 地图数据 key:地图id value:地图数据
func init(
	res_manager: ResManager,
	drop_thing_manager: DropThingManager,
	map_dic: Dictionary	
) -> void:
	self.res_manager = res_manager
	self.drop_thing_manager = drop_thing_manager
	self.map_dic = map_dic

	# 初始化怪物ID和地图ID的映射
	for map_id in map_dic.keys():
		var map_data = map_dic[map_id]
		for monster_id in map_data.monster_config_dic.keys():
			monster_id_map_id_map[monster_id] = map_id

	update_map()


func update_map() -> void:
	# 更新探索过的地图
	_update_explored_maps()
	# 根据地图名称搜索地图id
	_update_map_container($MapInput/MapEdit.text)


func _update_explored_maps() -> void:
	map_list.clear()
	map_name_id_map.clear()
	# 遍历地图数据字典，将其中探索过的地图加入列表
	for data_map in map_dic.values():
		if data_map.is_explored:
			map_list.append(data_map)
			map_name_id_map[data_map.name] = data_map.id


func _on_map_input_ok_bt_pressed() -> void:
	var map_name = $MapInput/MapEdit.text
	# 获取地图id
	var map_id = _map_name_part_search(map_name)
	if map_id == "":
		return
	# 防止重复展示
	if map_id == current_map_id:
		return

	current_map_id = map_id
	_update_monster_info_container()


func _update_monster_info_container() -> void:
	# 清除怪物信息展示容器
	_clear_monster_info_container()
	# 获取地图的怪物信息
	var map_monster_id_dic = res_manager.get_map_monster_id(current_map_id)
	# 根据怪物列表获取怪物信息
	for monster_id in map_monster_id_dic.keys():
		var monster_config = res_manager.get_monster_config(monster_id)
		_add_monster_item(monster_id,monster_config)
	
	# 怪物信息更新后，清空爆率信息
	_clear_drop_thing_info_container()
	# 展示地图的全部怪物击杀数量
	$MonsterInfo/KillCountTitle/Label.text = str(
		int(map_dic[current_map_id].get_total_kill_monster_count())
	)


# 根据关键字更新地图容器
func _update_map_container(keyword: String) -> void:
	# 清除地图容器
	_clear_map_container()
	# 根据关键字更新地图容器
	for map_name in map_name_id_map.keys():
		if keyword == "":
			_add_map_button(map_name)
		elif map_name.find(keyword) != -1:
			_add_map_button(map_name)

	# 地图信息更新后，清空爆率信息
	_clear_drop_thing_info_container()


func _add_monster_item(monster_id: String,monster_config: Dictionary) -> void:
	# 展示怪物名称和等级
	var monster_info_item = SingletonGameScenePre.MonsterInfoItemScene.instantiate()
	monster_info_item.text = monster_config["name"] + " Lv." + monster_config["level"]
	$MonsterInfo/ScrollContainer/MonsterContainer.add_child(monster_info_item)
	# 监听怪物信息点击事件
	monster_info_item.pressed.connect(func():
		_on_monster_drop_info_show(monster_id)
	)


func _add_map_button(map_name: String) -> void:
	var map_button = Button.new()
	map_button.text = map_name
	map_button.custom_minimum_size = Vector2($MapInput/ScrollContainer.size.x, 0)
	# 点击事件
	map_button.pressed.connect(func():
		$MapInput/MapEdit.text = map_name
		_on_map_input_ok_bt_pressed()
	)
	$MapInput/ScrollContainer/MapContainer.add_child(map_button)


func _on_monster_drop_info_show(monster_id: String) -> void:
	# 获取怪物掉落信息
	var monster_drops_rate = drop_thing_manager.get_drop_rate_info(monster_id)
	print("monster_drops_rate:", monster_drops_rate)

	# 清除掉落物信息展示容器
	_clear_drop_thing_info_container()

	# 根据怪物掉落信息生成掉落物信息
	for drop_thing_id in monster_drops_rate.keys():
		var drop_rate = monster_drops_rate[drop_thing_id]["rate"]
		var drop_thing = drop_thing_manager.create_item(drop_thing_id)
		# 创建掉落物的场景
		var drop_thing_item = SingletonGameScenePre.MonsterInfoDropThingItemScene.instantiate()
		drop_thing_item.set_drop_thing_item(drop_thing,drop_rate)
		$MonsterInfo/DropThingScroll/Container.add_child(drop_thing_item)
		# 设置掉落物信息展示监听
		drop_thing_item.item_show_bt_pressed.connect(_on_item_showed)

	# 展示怪物击杀数量
	$MonsterInfo/KillCountTitle/Label.text = str(
		int(map_dic[monster_id_map_id_map[monster_id]].get_kill_monster_count(monster_id))
	)


func _on_item_showed(ui: BagItem) -> void:
	item_show_bt_pressed.emit(ui)	


func _on_close_button_pressed() -> void:
	hide()


func _on_monster_input_ok_bt_pressed() -> void:
	# 获取怪物id
	var monster_id = $MonsterInput.text
	print("monster_id:", monster_id)


func _clear_map_container() -> void:
	for child in $MapInput/ScrollContainer/MapContainer.get_children():
		child.queue_free()


func _clear_monster_info_container() -> void:
	for child in $MonsterInfo/ScrollContainer/MonsterContainer.get_children():
		child.queue_free()


func _clear_drop_thing_info_container() -> void:
	for child in $MonsterInfo/DropThingScroll/Container.get_children():
		child.queue_free()


# 地图名称部分搜索
#
# @return 返回地图id
func _map_name_part_search(map_name: String)-> String:
	for map_name_part in map_name_id_map.keys():
		if map_name_part.find(map_name) != -1:
			return map_name_id_map[map_name_part]
	return ""


# 怪物名称部分搜索
func _monster_name_part_search(monster_name: String) -> void:
	pass


func _on_map_edit_text_changed(new_text: String) -> void:
	# 结束倒计时
	$SearchMapTimer.stop()
	# 倒计时开始
	$SearchMapTimer.start()


# 倒计时结束开始根据地图名称搜索地图id
func _on_search_map_timer_timeout() -> void:
	_update_map_container($MapInput/MapEdit.text)


func show_map_drop(map_name: String) -> void:
	$MapInput/MapEdit.text = map_name
	_update_map_container(map_name)
	_on_map_input_ok_bt_pressed()


func _on_monster_edit_text_changed(new_text: String) -> void:
	# 结束倒计时
	$SearchMonsterTimer.stop()
	# 倒计时开始
	$SearchMonsterTimer.start()


func _on_search_monster_timer_timeout() -> void:
	var monster_name_keyword = $MonsterInfo/MonsterEdit.text
	if monster_name_keyword == "":
		# 如果地图名称不为空，则根据地图名称搜索怪物
		if $MapInput/MapEdit.text != "":
			_update_monster_info_container()
		return
	# 清除怪物信息展示容器
	_clear_monster_info_container()
	# 根据关键字更新怪物信息展示容器
	var monster_name_id_map = res_manager.monster_name_id_map
	for monster_name in monster_name_id_map.keys():
		if monster_name.find(monster_name_keyword) != -1:
			var monster_id = monster_name_id_map[monster_name]
			# 获取怪物所在地图id
			var map_id = monster_id_map_id_map[monster_id]
			# 只有探索过的地图才展示怪物
			if map_dic[map_id].is_explored:
				var monster_config = res_manager.get_monster_config(monster_id)
				_add_monster_item(monster_id,monster_config)


func _on_clear_map_input_bt_pressed() -> void:
	$MapInput/MapEdit.text = ""
	# 刷新地图信息
	_on_search_map_timer_timeout()


func _on_clear_monster_input_bt_pressed() -> void:
	$MonsterInfo/MonsterEdit.text = ""
	# 刷新怪物信息
	_on_search_monster_timer_timeout()
