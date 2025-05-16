extends Control

var select_role_index: int = -1

# 角色id字典 key为角色栏序号 值为角色id String类型
var role_id_dic: Dictionary = {}
# 角色详细信息 key 为id String类型 值为 DataPlayer
var role_dic: Dictionary = {}

var cache_tool: BaseCacheTool

# 角色数量上限
var role_max_num: int = 3

signal game_started(role_id: String)

signal go_back

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if cache_tool != null:
		# 加载角色列表
		var role_id_dic_json = cache_tool.load_roles()
		if not role_id_dic_json.is_empty():
			# 解析角色列表
			var role_id_dic_from_json = JSON.parse_string(role_id_dic_json)
			for index_str in role_id_dic_from_json.keys():
				var index = int(index_str)
				if role_id_dic_from_json.has(index_str):
					var role_id = role_id_dic_from_json[index_str]
					role_id_dic[index_str] = role_id
					role_dic[role_id] = cache_tool.load_data_player(role_id)
					# 展示角色
					add_role(role_dic[role_id], index)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func init_cache_tool(_cache_tool: BaseCacheTool) -> void:
	self.cache_tool = _cache_tool


func add_role(data_player: DataPlayer, index: int) -> void:
	var role_placehold = get_node("RoleSelect/RoleBack/RolePlaceHold" + str(index))
	if role_placehold.get_child_count() == 0:
		# 实例化角色
		var player_scene = SingletonGameScenePre.PlayerScene.instantiate()
		player_scene.init_data(data_player)
		# 点击事件忽略
		player_scene.enable_select()
		player_scene.position = Vector2.ZERO
		player_scene.selected.connect(_on_role_selected.bind(index))
		# 添加角色展示
		role_placehold.add_child(player_scene)


func remove_role(index: int) -> void:
	var role_placehold = get_node("RoleSelect/RoleBack/RolePlaceHold" + str(index))
	if role_placehold.get_child_count() > 0:
		role_placehold.get_child(0).queue_free()


func _get_role_placehold(index: int) -> Control:
	return get_node("RoleSelect/RoleBack/RolePlaceHold" + str(index + 1) + "/RolePlaceHold")


func _on_create_role_bt_pressed() -> void:
	# 如果角色数量达到上限，不允许创建角色
	if role_id_dic.size() >= role_max_num:
		ToastManager.add_toast("角色数量达到上限")
		return
	$RoleSelect.hide()
	$RoleCreate.show_this()


func _on_start_game_bt_pressed() -> void:
	if select_role_index == -1:
		return
	game_started.emit(role_id_dic[str(select_role_index)])


func _on_role_selected(index: int) -> void:
	# 如果没有角色，不允许选择
	if not role_id_dic.has(str(index)):
		return
	# 将上一个选中的角色取消选中
	if select_role_index != -1:
		# 如果角色存在，则取消选中
		if role_id_dic.has(str(select_role_index)):
			get_node("RoleSelect/RoleBack/RolePlaceHold" + str(select_role_index)).get_child(0).unselect()
	# 选中当前角色
	select_role_index = index

	if $RoleSelect/StartGameBt.disabled:
		$RoleSelect/StartGameBt.disabled = false

	# 展示当前角色信息
	$RoleSelect/RoleInfo.show()
	var role = role_dic[role_id_dic[str(index)]]
	$RoleSelect/RoleInfo/NameLabel/Label.text = role.player_name
	$RoleSelect/RoleInfo/JobLabel/Label.text = role.job_name
	$RoleSelect/RoleInfo/LevelLabel/Label.text = str(role.level)
	$RoleSelect/RoleInfo/PowerLabel/Label.text = str(role.attribute.all_ability.power)
	$RoleSelect/RoleInfo/AgilityLabel/Label.text = str(role.attribute.all_ability.agility)
	$RoleSelect/RoleInfo/IntellLabel/Label.text = str(role.attribute.all_ability.intelligence)
	$RoleSelect/RoleInfo/LuckLabel/Label.text = str(role.attribute.all_ability.luck)


func _on_back_bt_pressed() -> void:
	go_back.emit()
	hide()
	$RoleSelect/RoleInfo.hide()


func _on_role_create_go_back() -> void:
	$RoleSelect.show()


func _on_role_create_create_role_info_success(role_name: String, create_info: Dictionary) -> void:
	#region 生成玩家ID
	# 找到角色列表中id最大值
	var max_id = 0
	if not role_id_dic.is_empty():
		for role_id in role_id_dic.values():
			if int(role_id) > max_id:
				max_id = int(role_id)
			# 判断角色名称是否重复
			if role_name == role_dic[role_id].player_name:
				ToastManager.add_toast("角色名称已存在")
				return
	# 生成玩家ID
	var player_id = str(max_id + 1)
	#endregion
	
	# 创建玩家数据
	var data_player = _create_data_player(role_name, player_id, create_info)

	# 保存id和数据详情到内存
	var index = _add_role_id(player_id)
	role_dic[player_id] = data_player
	# 保存id和数据详情到本地缓存
	cache_tool.save_roles(JSON.stringify(role_id_dic))
	cache_tool.save_data_player(data_player, player_id)
	
	# 展示角色列表 并添加新角色
	$RoleSelect.show()
	add_role(data_player, index)
	# 隐藏角色创建界面
	$RoleCreate.hide()


func _create_data_player(role_name: String, player_id: String, create_info: Dictionary) -> DataPlayer:
	var data_player = DataPlayer.new()
	data_player.player_id = str(player_id)
	data_player.player_name = role_name
	data_player.init_base_ability(
		create_info["power"],
		create_info["agility"],
		create_info["intell"],
		create_info["luck"]
	)
	data_player.init_base_details()
	data_player.attribute.update()
	data_player.hp = data_player.attribute.final_details.max_hp
	data_player.mp = data_player.attribute.final_details.max_mp
	return data_player


# 往role_id_dic中添加id，从1开始遍历到role_max_num
# 返回角色栏序号
func _add_role_id(role_id: String) -> int:
	for index in range(1, role_max_num + 1):
		var index_str = str(index)
		if not role_id_dic.has(index_str):
			role_id_dic[index_str] = role_id
			return index
	return -1


func _on_delete_role_bt_pressed() -> void:
	if select_role_index == -1:
		return
	var index_str = str(select_role_index)
	var role_id_to_delete = role_id_dic[index_str]
	# 删除角色内存
	role_id_dic.erase(index_str)
	role_dic.erase(role_id_to_delete)
	# 删除角色缓存
	cache_tool.remove(role_id_to_delete)
	# 保存角色列表到本地缓存
	cache_tool.save_roles(JSON.stringify(role_id_dic))
	# 删除角色展示
	remove_role(select_role_index)

	select_role_index = -1
	$RoleSelect/RoleInfo.hide()
