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

# 怪物掉落表
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
