class_name ResManager

## 管理地图、怪物和掉落物相关的数据、图片等资源信息。
##
## 实现为单例类型，以便MonsterManager和DropThingManager可以直接使用。

# 资源加载路径
var res_path = "user://config/"

# 通用配置
var common_dic = {}

# 名称，传送点信息
var map_res = {}
# 地图的怪物信息
var map_monster = {}
# 地区和地图信息
var map_region_dic = {}

# 怪物掉落表 key：monster_id value：掉落物id和掉落概率
var monster_drops_rate = {}
# 怪物名称和怪物id的映射，方便通过怪物名查询怪物id
var monster_name_id_map = {}

# 人物经验值表
var exp_dic = {}

# 装备信息
var equip_dic = {}
## 消耗品物品信息(包括堆叠信息等)
var consume_dic = {}
## 其他物品
var etc_dic = {}
## 物品ID和名称的映射
var item_id_name_map = {}

## 职业信息
var job_dic = {}
## 技能信息
var skill_dic = {}

## NPC信息
var map_npc_dic = {}

## 任务信息
var mission_dic = {}

## 炼金配方信息
var alchemy_dic = {}

## 特效信息
var effect_dic = {}

## 怪物技能信息
var monster_skill_dic = {}

## 物品出处词典：key为物品ID，value为包含掉落此物品的怪物及其所在地图信息
var item_source_dict = {}

## 按物品类型分类的物品出处词典
var categorized_item_source_dict = {}

# 必要资源加载完成
signal load_res_finished()

# 日志工具
var log = LogTool.new()

	
func load():
	log.init("res_manager")
	log.print_time("load")

	## 加载通用配置
	common_dic = _read_config_json(res_path + "common.json")
	SingletonGame.exp_multiplier = float(common_dic["exp_multiplier"])
	SingletonGame.drop_rate_multiplier = float(common_dic["drop_rate_multiplier"])
	SingletonGame.speed = float(common_dic["speed"])
	if common_dic.has("gold_multiplier"):
		SingletonGame.gold_multiplier = float(common_dic["gold_multiplier"])

	## 加载地图配置
	##
	# 加载地图地区信息
	map_region_dic = _load_map_region()["map"]
	#log.print_finish("加载地图列表:" + str(map_dic))
	# 加载地图信息
	map_res = _read_config_json(res_path + "map.json")

	# 加载地图怪物信息
	map_monster = _read_config_json(res_path + "map_monster.json")
	monster_drops_rate = _read_config_json(res_path + "monster_drops_rate.json")
	log.print_finish("加载地图怪物信息:" + str(map_monster))

	# 加载人物经验值表
	exp_dic = _read_config_json(res_path + "player_level_exp.json")

	# 加载装备信息
	equip_dic = _read_equip_dic()
	# 加载消耗品信息
	consume_dic = _read_config_json(res_path + "Bag/consume.json")["consume"]
	_add_item_name(consume_dic)
	# 加载其他物品信息
	etc_dic = _read_config_json(res_path + "Bag/etc.json")["etc"]
	_add_item_name(etc_dic)

	# 加载职业信息
	job_dic = _read_config_json(res_path + "job.json")["jobs"]

	# 加载技能信息
	skill_dic = _read_config_json(res_path + "skill.json")

	# 加载NPC信息
	map_npc_dic = _read_config_json(res_path + "map_npc.json")

	# 加载任务信息
	mission_dic = _read_config_json(res_path + "mission.json")

	# 加载炼金配方信息
	alchemy_dic = _read_config_json(res_path + "alchemy.json")["alchemy"]

	# 加载特效信息
	effect_dic = _read_config_json(res_path + "effect.json")["effects"]

	# 加载怪物技能信息
	monster_skill_dic = _read_config_json(res_path + "monster_skill.json")["skills"]
	
	# 构建物品出处词典
	_build_item_source_dict()

	load_res_finished.emit()


func _add_item_name(dic: Dictionary):
	for item_id in dic.keys():
		item_id_name_map[item_id] = dic[item_id]["name"]


## 外部接口：获取怪物的配置信息
func get_monster_config(monster_id):
	var config = _load_monster(monster_id)
	if not monster_name_id_map.has(config["name"]):
		monster_name_id_map[config["name"]] = monster_id
	return config


## 外部接口：获取地图的配置信息
func get_map_config(map_id):
	if map_res.has(map_id):
		return map_res[map_id]
	else:
		return null


## 外部接口：获取地图的怪物刷新点
##
## @return 一个数组，每个元素为一个字典，包含怪物刷新点信息。
func get_map_monster_pos(map_id):
	if map_monster.has(map_id):
		return map_monster[map_id]
	else:
		return []


## 外部接口：获取指定地图的所有怪物id
##
## @return 一个字典，key为怪物id，value无用，方便去重。
func get_map_monster_id(map_id) -> Dictionary:
	var map_monster_pos = get_map_monster_pos(map_id)
	var result = {}
	for monster_pos in map_monster_pos:
		for monster_id_and_rate in monster_pos["monster_list"]:
			result[monster_id_and_rate["id"]] = 1
	return result


## 加载怪物id列表
##
## 所有的怪物列表都放在一个目录下，直接通过加载目录的方式全量加载。
## 哪些地图需要显示对应的怪物，直接获取到对应的怪物信息即可。
func _load_monster_list():
	return _load_dir(res_path + "Monster/")


## 加载怪物
func _load_monster(monster_id):
	# 加载怪物配置信息
	var path = res_path + "Monster/" + monster_id + ".json"
	return _read_config_json(path)


## 加载地图地区信息
##
## 地图信息之所以通过json加载，是因为有时候希望配置的地图列表是动态的，而不是固定的。
## 可能存在所有的地图信息都放入游戏了，但是在游戏中只显示部分地图，而不是所有地图。
func _load_map_region():
	return _read_config_json(res_path + "map_region.json")


## 读取指定目录的文件列表
func _load_dir(dir):
	var list = []
	var dir_access = DirAccess.open(dir)
	dir_access.list_dir_begin()
	var file_name = dir_access.get_next()
	while file_name != "":
		list.append(file_name)
		file_name = dir_access.get_next()
	return list


## 读取json配置文件
func _read_config_json(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var json = file.get_as_text()
	var json_data = JSON.parse_string(json)
	file.close()
	return json_data


## 读取装备的详细信息
## 
## 首先根据@see res://resources/body_equip.json
## 读取当前支持哪些类型的装备equip_type
## 再根据支持的装备类型，在res://resources/Bag/Equip目录下读取每一个类型下的详细的装备信息。
## 这样方便仅修改body_equip.json文件，再往装备目录添加原始格式的装备信息，即可支持新的装备类型。
func _read_equip_dic() -> Dictionary:
	var result_dic = {}

	var equip_type_dic = _read_config_json(res_path + "body_equip.json")
	for equip_key in equip_type_dic.keys():
		result_dic[equip_key] = {}

	# 遍历每一个类型下的装备
	var equip_type_id = {}
	for equip_type in equip_type_dic.keys():
		if not result_dic.has(equip_type):
			continue
		# 每一个类型对应一个字典来存储装备信息
		equip_type_id[equip_type] = {}

		## 读取装备的详细信息
		var one_type_equip_dic = _read_config_json(res_path + "Bag/Equip/" + equip_type + ".json")[equip_type]
		
		# 将每一个类型的装备信息存储到result_dic中
		result_dic[equip_type] = one_type_equip_dic

		# 将装备名称存储到item_id_name_map中
		_add_item_name(one_type_equip_dic)


	return result_dic


## 读取装备的string信息
##
## 由于装备的配置信息太大，进行逐行读取，根据id的范围划分到不同的字典中。
func _read_equip_string() -> Dictionary:
	var result_dic = {}

	var equip_type_dic = _read_config_json(res_path + "body_equip.json")
	for equip_key in equip_type_dic.keys():
		result_dic[equip_key] = {}
	
	var file = FileAccess.open(res_path + "string/equip/index.json", FileAccess.READ)

	var line = file.get_line()
	while not file.eof_reached():
		if line.contains("\""):
			var line_split = line.split("\"")
			var key = line_split[1]
			var value = line_split[3]
			# 装备类型
			var equip_type = key.split(".")[1]
			# 根据type划分到不同的字典中
			if result_dic.has(equip_type):
				result_dic[equip_type][key] = value

		line = file.get_line()
	file.close()

	return result_dic


## 读取消耗品的string信息
## 
## 由于消耗品的配置信息太大，进行逐行读取，根据id的范围划分到不同的字典中。
func _read_consume_string() -> Dictionary:
	var result_dic = {}

	var consume_type_dic = _read_config_json(res_path + "consume.json")
	for consume_key in consume_type_dic.keys():
		result_dic[consume_key] = {}

	var file = FileAccess.open(res_path + "string/consume/index.json", FileAccess.READ)
	
	var line = file.get_line()
	while not file.eof_reached():
		if line.contains("\""):
			var line_split = line.split("\"")
			var key = line_split[1]
			var value = line_split[3]
			var id = key.split(".")[0]
			# 根据id的范围划分到不同的字典中
			for consume_key in consume_type_dic.keys():
				var id_min = consume_type_dic[consume_key]["min"]
				var id_max = consume_type_dic[consume_key]["max"]
				if int(id) >= int(id_min) and int(id) <= int(id_max):
					result_dic[consume_key][key] = value
					break

		line = file.get_line()
	file.close()

	return result_dic


func get_map_region_dic():
	return map_region_dic


func get_job_name(job_id) -> String:
	if not job_dic.has(job_id):
		return ""
	return job_dic[job_id]["job_name"]


func get_job_skills(job_id) -> Array:
	if not job_dic.has(job_id):
		return []
	return job_dic[job_id]["skill_list"]


func get_skill_name(skill_id) -> String:
	if not skill_dic.has(skill_id):
		return ""
	return skill_dic[skill_id]["name"]


func get_effect_info(effect_id) -> Dictionary:
	if not effect_dic.has(effect_id):
		return {}
	return effect_dic[effect_id]


## 构建物品出处词典
func _build_item_source_dict():
	item_source_dict.clear()
	categorized_item_source_dict.clear()
	
	# 遍历怪物掉落表
	for monster_id in monster_drops_rate.keys():
		var drops = monster_drops_rate[monster_id]
		
		# 遍历怪物掉落的物品
		for item_id in drops.keys():
			var drop_rate = drops[item_id]["rate"]
			
			# 确保物品ID在词典中存在
			if not item_source_dict.has(item_id):
				item_source_dict[item_id] = {"monsters": []}
			
			# 获取怪物名称
			var monster_name = ""
			if monster_name_id_map.has(monster_id):
				monster_name = monster_name_id_map[monster_id]
			else:
				var monster_config = get_monster_config(monster_id)
				monster_name = monster_config["name"]
			
			# 查找怪物所在的地图
			var maps = []
			for map_id in map_monster.keys():
				var monster_pos_list = map_monster[map_id]
				for monster_pos in monster_pos_list:
					for monster_info in monster_pos["monster_list"]:
						if monster_info["id"] == monster_id:
							var map_name = ""
							if map_res.has(map_id):
								map_name = map_res[map_id]["name"]
							
							maps.append({
								"map_id": map_id,
								"map_name": map_name
							})
							break
			
			# 创建怪物信息
			var monster_info = {
				"monster_id": monster_id,
				"monster_name": monster_name,
				"drop_rate": drop_rate,
				"maps": maps
			}
			
			# 添加怪物信息到物品出处词典
			item_source_dict[item_id]["monsters"].append(monster_info)
			
			# 分类添加到categorized_item_source_dict
			var category = _get_item_category(item_id)
			
			# 确保分类在词典中存在
			if not categorized_item_source_dict.has(category):
				categorized_item_source_dict[category] = {}
			
			# 确保物品ID在分类词典中存在
			if not categorized_item_source_dict[category].has(item_id):
				categorized_item_source_dict[category][item_id] = {"monsters": []}
			
			# 添加怪物信息到分类词典
			categorized_item_source_dict[category][item_id]["monsters"].append(monster_info)
	
	# 对每个类别下的物品按ID进行排序
	_sort_categorized_items()

## 对每个类别下的物品按ID进行排序
func _sort_categorized_items():
	# 遍历所有类别
	for category in categorized_item_source_dict.keys():
		# 获取该类别下的所有物品ID
		var item_ids = categorized_item_source_dict[category].keys()
		# 对物品ID进行排序
		item_ids.sort()
		
		# 创建一个新的有序字典
		var sorted_items = {}
		# 按排序后的ID顺序重建字典
		for item_id in item_ids:
			sorted_items[item_id] = categorized_item_source_dict[category][item_id]
		
		# 用排序后的字典替换原字典
		categorized_item_source_dict[category] = sorted_items

## 根据物品ID获取物品类别
##
## @param item_id 物品ID
## @return 物品类别字符串
func _get_item_category(item_id: String) -> String:
	# 如果物品ID包含下划线，以下划线前的部分作为类别
	if item_id.contains("_"):
		return item_id.split("_")[0]
	
	# 如果是纯数字，尝试根据ID范围判断类别
	if item_id.is_valid_int():
		var id_num = int(item_id)
		# 这里可以根据游戏规则添加更多判断
		# 例如：装备ID在10000-20000范围，消耗品在20001-30000范围等
		if id_num >= 10000 and id_num < 20000:
			return "equip"
		elif id_num >= 20001 and id_num < 30000:
			return "consume"
		# ... 更多类别判断
	
	# 默认类别
	return "unknown"

## 外部接口：查询物品的出处信息
##
## @param item_id 物品ID
## @return 返回包含怪物和地图信息的字典，若物品不存在则返回空字典
func get_item_source(item_id: String) -> Dictionary:
	if item_source_dict.has(item_id):
		return item_source_dict[item_id]
	return {}

## 外部接口：通过物品名称查询物品的出处信息
##
## @param item_name 物品名称
## @return 返回包含怪物和地图信息的字典，若物品不存在则返回空字典
func get_item_source_by_name(item_name: String) -> Dictionary:
	# 通过物品名称查找物品ID
	var item_id = ""
	for id in item_id_name_map.keys():
		if item_id_name_map[id] == item_name:
			item_id = id
			break
	
	# 如果找到物品ID，查询其出处
	if item_id != "":
		return get_item_source(item_id)
	return {}

## 外部接口：获取物品名称
##
## @param item_id 物品ID
## @return 物品名称，若物品不存在则返回空字符串
func get_item_name(item_id: String) -> String:
	if item_id_name_map.has(item_id):
		return item_id_name_map[item_id]
	return ""

## 外部接口：获取按类别分类的物品出处词典
##
## @return 分类后的物品出处词典
func get_categorized_item_source() -> Dictionary:
	return categorized_item_source_dict

## 外部接口：获取指定类别的物品出处信息
##
## @param category 物品类别
## @return 指定类别的物品出处词典，若类别不存在则返回空字典
func get_item_source_by_category(category: String) -> Dictionary:
	if categorized_item_source_dict.has(category):
		return categorized_item_source_dict[category]
	return {}

## 外部接口：获取所有物品类别
##
## @return 物品类别数组
func get_all_item_categories() -> Array:
	return categorized_item_source_dict.keys()
