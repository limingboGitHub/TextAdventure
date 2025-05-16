'''
通过文件FileAccess进行缓存的工具类
'''
extends BaseCacheTool

class_name FileCacheTool

# 游戏存档目录
var game_save_dir = "user://game_save"

# 配置资源目录内部目录
var config_res_dir = "res://assets/config"
# 配置资源用户目录 Windows平台: 应用缓存目录 Android平台：应用的沙盒存储files目录
var config_user_dir = OS.get_user_data_dir().path_join("config")

# 保存角色数据
func save_data_player(data_player: DataPlayer,save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	if !DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)

	_write_file(save_dir + "/player.txt", data_player.save())


# 加载角色数据
func load_data_player(save_id: String) -> DataPlayer:
	var save_dir = game_save_dir + "/" + save_id
	if !DirAccess.dir_exists_absolute(save_dir):
		return null

	var dic = _read_file(save_dir + "/player.txt")
	if dic:
		var data_player = DataPlayer.new()
		data_player.load(dic)
		return data_player
	else:
		return null


# 保存背包数据
func save_data_bag(data_bag: DataBag,save_id: String):
	var save_dir = game_save_dir + "/" + save_id

	_write_file(save_dir + "/bag.txt", data_bag.save())


# 加载背包数据
func load_data_bag(save_id: String) -> DataBag:
	var save_dir = game_save_dir + "/" + save_id

	var dic = _read_file(save_dir + "/bag.txt")
	if dic:
		var data_bag = DataBag.new()
		data_bag.load(dic)
		return data_bag
	else:
		return null


# 装备数据
func save_data_role_equip(data_role_equip: DataRoleEquip,save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	_write_file(save_dir + "/role_equip.txt", data_role_equip.save())


# 加载装备数据
func load_data_role_equip(save_id: String) -> DataRoleEquip:
	var save_dir = game_save_dir + "/" + save_id
	var dic = _read_file(save_dir + "/role_equip.txt")
	if dic:
		var data_role_equip = DataRoleEquip.new()
		data_role_equip.load(dic)
		return data_role_equip
	else:
		return null


# 保存技能背包
func save_data_skill_bag(data_skill_bag: DataSkillBag,save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	_write_file(save_dir + "/skill_bag.txt", data_skill_bag.save())


# 加载技能背包
func load_data_skill_bag(save_id: String) -> DataSkillBag:
	var save_dir = game_save_dir + "/" + save_id
	var dic = _read_file(save_dir + "/skill_bag.txt")
	if dic:
		var data_skill_bag = DataSkillBag.new()
		data_skill_bag.load(dic)
		return data_skill_bag
	else:
		return null


# 保存地图数据
func save_maps(map_dic: Dictionary,save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	var dic = {}
	# 遍历地图数据，将地图数据序列化后再存储
	for map_id in map_dic:
		var data_map = map_dic[map_id]
		var data_map_dic = data_map.save()
		if data_map_dic.is_empty():
			continue
		dic[map_id] = data_map_dic
	
	if dic.is_empty():
		return
	_write_file(save_dir + "/maps.txt", dic)


# 加载地图数据
func load_maps(save_id: String) -> Dictionary:
	var save_dir = game_save_dir + "/" + save_id
	var dic = _read_file(save_dir + "/maps.txt")
	if dic:
		return dic
	else:
		return {}


## 保存任务数据
## 
## @param missions_dic 任务数据字典 key:任务id value:任务数据DataMission
func save_missions(missions_dic: Dictionary,save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	var dic = {}
	# 遍历任务数据，将任务数据序列化后再存储
	for mission_id in missions_dic:
		var data_mission = missions_dic[mission_id]
		var data_mission_dic = data_mission.save()
		if data_mission_dic.is_empty():
			continue
		dic[mission_id] = data_mission_dic
	if dic.is_empty():
		return
	_write_file(save_dir + "/missions.txt", dic)


# 加载任务数据
func load_missions(save_id: String) -> Dictionary:
	var save_dir = game_save_dir + "/" + save_id
	var dic = _read_file(save_dir + "/missions.txt")
	if dic:
		return dic
	else:
		return {}


# 保存炼金背包数据
func save_data_alchemy_bag(data_alchemy_bag: DataAlchemyBag,save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	_write_file(save_dir + "/alchemy_bag.txt", data_alchemy_bag.save())


# 加载炼金背包数据
func load_data_alchemy_bag(save_id: String) -> DataAlchemyBag:
	var save_dir = game_save_dir + "/" + save_id
	var dic = _read_file(save_dir + "/alchemy_bag.txt")
	if dic:
		var data_alchemy_bag = DataAlchemyBag.new()
		data_alchemy_bag.load(dic)
		return data_alchemy_bag
	else:
		return null


# 保存全局配置信息
func save_singleton_game(save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	_write_file(save_dir + "/singleton_game.txt", SingletonGame.save())


# 加载全局配置信息
func load_singleton_game(save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	var dic = _read_file(save_dir + "/singleton_game.txt")
	if dic:
		SingletonGame.load(dic)


# 保存游戏数据
# 
# @param data_world 保存的游戏数据
func save(data_world: DataWorld,save_id: String):
	# 保存玩家信息
	save_data_player(data_world.get_player(),save_id)
	# 保存背包信息
	save_data_bag(data_world.get_data_bag(),save_id)
	# 保存装备信息
	save_data_role_equip(data_world.get_data_role_equip(),save_id)
	# 保存技能背包
	save_data_skill_bag(data_world.get_data_skill_bag(),save_id)
	# 保存任务数据
	save_missions(data_world.get_missions(),save_id)
	# 保存地图数据
	save_maps(data_world.get_maps(),save_id)
	# 保存炼金背包数据
	save_data_alchemy_bag(data_world.get_data_alchemy_bag(),save_id)
	# 保存通用参数
	save_singleton_game(save_id)


func remove(save_id: String):
	var save_dir = game_save_dir + "/" + save_id
	if !DirAccess.dir_exists_absolute(save_dir):
		return
	# 遍历文件夹，删除文件
	var dir = DirAccess.open(save_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var file_path = save_dir.path_join(file_name)
				if dir.current_is_dir():
					# 如果是子目录，递归删除
					remove(file_path.replace(game_save_dir + "/", ""))
				else:
					# 删除文件
					DirAccess.remove_absolute(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# 删除文件夹
	DirAccess.remove_absolute(save_dir)


func _load(file_name: String):
	var file = FileAccess.open(game_save_dir + "/" + file_name, FileAccess.READ)
	while file.get_position() < file.get_length():
		var json_string = file.get_line()
		print(json_string)
	file.close()


func save_roles(role_json: String):
	if !DirAccess.dir_exists_absolute(game_save_dir):
		DirAccess.make_dir_recursive_absolute(game_save_dir)

	var file = FileAccess.open(game_save_dir + "/role_list.save", FileAccess.WRITE)
	file.store_line(role_json)


func load_roles() -> String:
	var file = FileAccess.open(game_save_dir + "/role_list.save", FileAccess.READ)
	if file:
		return file.get_as_text()
	else:
		return ''


func _read_file(file_name: String):
	var file = FileAccess.open(file_name, FileAccess.READ)
	if file:
		var json = file.get_as_text()
		file.close()
		return JSON.parse_string(json)
	else:
		return null


func _write_file(file_name: String, data: Dictionary):
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	var json = JSON.stringify(data)
	file.store_string(json)
	file.close()


func copy_resources_to_user_dir(is_force: bool = false):
	# 如果用户的配置文件目录已经存在了，则使用已有的配置信息，不再复制
	if !is_force and DirAccess.dir_exists_absolute(config_user_dir):
		print("配置文件目录已经存在，不再复制")
		return

	# 创建用户配置文件目录
	DirAccess.make_dir_recursive_absolute(config_user_dir)
	# 执行递归复制
	copy_directory(config_res_dir, config_user_dir)


# 递归复制文件夹
func copy_directory(source_dir: String, target_dir: String) -> void:
	print("copy_directory", source_dir, target_dir)
	var dir = DirAccess.open(source_dir)
	if dir:
		# 确保目标目录存在
		if not DirAccess.dir_exists_absolute(target_dir):
			DirAccess.make_dir_recursive_absolute(target_dir)
		
		# 开始列举源文件夹中的内容
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name != "." and file_name != "..":
				var source_path = source_dir.path_join(file_name)
				var target_path = target_dir.path_join(file_name)
				
				if dir.current_is_dir():
					# 递归复制子文件夹
					copy_directory(source_path, target_path)
				else:
					# Android平台不支持DirAccess.copy_absolute从"res://"复制文件
					# 必须采用FileAccess读取文件内容再写入一个新文件
					copy_file(source_path, target_path)
					print("copy_file", source_path, target_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()


func copy_file(source_path: String, target_path: String) -> bool:
	var file = FileAccess.open(source_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var new_file = FileAccess.open(target_path, FileAccess.WRITE)
		new_file.store_string(content)
		new_file.close()
		return true
	else:
		return false


func import_dir_to_user_dir(dir: String) -> String:
	# 递归遍历dir以及其子目录下的所有文件，同时在config_user_dir目录下递归寻找同名文件
	
	# 检查源目录是否存在
	if !DirAccess.dir_exists_absolute(dir):
		return "导入目录不存在：" + dir
	
	# 调用辅助函数进行递归导入
	var result = _import_dir_recursive(dir, config_user_dir)
	return result


# 递归导入目录中的文件
# 
# @return 导入失败的原因 如果导入成功，返回空字符串
func _import_dir_recursive(source_dir: String, target_dir: String) -> String:
	var reason = ""

	var dir = DirAccess.open(source_dir)
	if !dir:
		reason = "无法打开源目录：" + source_dir
		return reason
	
	# 开始遍历目录
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name != "." and file_name != "..":
			var source_path = source_dir.path_join(file_name)
			
			if dir.current_is_dir():
				# 递归处理子目录
				reason = _import_dir_recursive(source_path, target_dir)
				if reason != "":
					return reason
			else:
				# 读取源文件内容
				var source_file = FileAccess.open(source_path, FileAccess.READ)
				if source_file:
					var content = source_file.get_as_text()
					source_file.close()
					
					# 在目标目录中查找同名文件并替换
					_find_and_replace_file(target_dir, file_name, content)
				else:
					reason = "无法打开源文件：" + source_path
			
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return reason


func import_file_to_user_dir(file: String) -> String:
	# 递归遍历config_user_dir目录以及其子目录下的所有文件，
	# 如果找到同名文件，则将file文件内容覆盖写入
	
	# 检查输入文件是否存在
	if !FileAccess.file_exists(file):
		return "导入文件不存在：" + file
	
	# 获取文件名（不含路径）
	var file_name = file.get_file()
	
	# 读取源文件内容
	var source_file = FileAccess.open(file, FileAccess.READ)
	if !source_file:
		return "无法打开源文件：" + file
	
	var content = source_file.get_as_text()
	source_file.close()
	
	# 寻找目标文件并覆盖
	var result = _find_and_replace_file(config_user_dir, file_name, content)
	return result



# 递归查找文件并替换内容
# 
# @return 失败的原因 如果成功，返回空字符串
func _find_and_replace_file(dir_path: String, target_file_name: String, content: String) -> String:
	var dir = DirAccess.open(dir_path)
	if !dir:
		return "无法打开目录：" + dir_path
	
	var found = false
	
	# 开始遍历目录
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path = dir_path.path_join(file_name)
			
			if dir.current_is_dir():
				# 递归查找子目录
				var sub_found = _find_and_replace_file(full_path, target_file_name, content)
				if sub_found:
					found = true
			elif file_name == target_file_name:
				# 找到同名文件，覆盖内容
				var target_file = FileAccess.open(full_path, FileAccess.WRITE)
				if target_file:
					target_file.store_string(content)
					target_file.close()
					print("已成功导入文件到：", full_path)
					found = true
				else:
					return "无法写入目标文件：" + full_path
			
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return ""
