class_name MapManager

## 地图管理器
##
## 负责地图的加载逻辑，解耦地图Config类和DataMap类。
## 地图本身不再关心地形和Npc这些信息是怎么来的，后续调整加载方式也不会影响地图本身。


## 对外接口：根据配置信息创建地图
func get_map_by_config(
	map_id,
	map_config,
	monster_refresh_pos_list,
	map_monster_config_dic,
	map_npc_dic,
	dropthing_manager,
	mission_manager
):
	var map = DataMap.new()
	map.id = map_id
	map.name = map_config["name"]
	map.region_id = map_config["region"]
	# 是否为主城
	if map_config.has("main_town"):
		map.main_town = map_config["main_town"]
	# 注入怪物爆率表
	map.drop_thing_manager = dropthing_manager

	# 加载传送点
	if map_config.has("portals"):
		for config_key in map_config["portals"].keys():
			var portal = _create_portal(config_key, map_config["portals"][config_key])
			map.add_portal(portal)
	# 加载无尽之塔
	if map_config.has("endless"):
		map.is_endless = true
		map.monster_upgrade = map_config["endless"]["monster_upgrade"]
		map.monster_count = map_config["endless"]["monster_count"]

	# 加载NPC
	for map_id_key in map_npc_dic.keys():
		if map_id_key == map_id:
			var npc_list = map_npc_dic[map_id_key]
			for npc_dic in npc_list:
				# 信息
				var npc = DataNPC.new(npc_dic["id"], npc_dic["name"])
				npc.default_messages = npc_dic["default_messages"]
				npc.position = Vector2(npc_dic["position"]["x"], npc_dic["position"]["y"])
				npc.map_id = map_id
				if npc_dic.has("visible"):
					npc.visible = npc_dic["visible"]
				# NPC功能
				if npc_dic.has("function"):
					for function in npc_dic["function"]:
						var function_type = function["type"]
						if function_type == DataNPC.TYPE_SHOP:
							npc.shop_bag = _create_shop_bag(function["shop_bag"], dropthing_manager)
						elif function_type == DataNPC.TYPE_MISSION:
							# 任务数据在MissionManager中统一管理，NPC只存任务id
							npc.mission_ids.append(function["mission_id"])
						elif function_type == DataNPC.TYPE_TELEPORT:
							var data_teleport = DataTeleport.new()
							for teleport_map_id in function["map_id_list"]:
								data_teleport.map_id_list.append(teleport_map_id)
							data_teleport.visible_limit = MissionManager.get_visible_limit_from_config(
								function["visible_limit"]
							)
							npc.teleport_data = data_teleport
				
				map.add_npc(npc)

	# 加载怪物刷新点
	# monster_refresh_pos_list的size表示不同刷新点的种类个数
	for i in range(monster_refresh_pos_list.size()):
		var refresh_pos_dic = monster_refresh_pos_list[i]
		# count表示一类刷新点的个数
		var count = refresh_pos_dic["count"]
		# 刷新点的id
		var refresh_pos_id = 0
		for j in range(count):
			var refresh_pos = MonsterRefreshPos.new(refresh_pos_id)
			# id自增
			refresh_pos_id += 1

			# 加载刷新点的怪物的随机信息
			for refresh_monster in refresh_pos_dic["monster_list"]:
				var refresh_info = MonsterRefreshPos.RefreshInfo.new()
				refresh_info.monster_id = refresh_monster["id"]
				refresh_info.rate = float(refresh_monster["refresh_rate"])
				if refresh_monster.has("refresh_interval"):
					refresh_info.refresh_interval = refresh_monster["refresh_interval"]
				refresh_pos.monster_refresh_list.append(refresh_info)

			# 怪物刷新点的位置
			if refresh_pos_dic.has("position"):
				refresh_pos.pos = Vector2(refresh_pos_dic["position"]["x"], refresh_pos_dic["position"]["y"])

			map.map_monster_refresh_pos.append(refresh_pos)
	
	map.monster_config_dic = map_monster_config_dic

	return map


func _create_shop_bag(dic, dropthing_manager: DropThingManager) -> DataBag:
	var bag = DataBag.new()
	for tab_name in dic.keys():
		var tab = dic[tab_name]
		for item_dic in tab:
			var id = item_dic["id"]
			var price = item_dic["price"]
			# 生成商店物品
			var item = dropthing_manager.create_item(id)
			item.price = price
			bag.add_item(item)
	return bag


## 添加传送门
##
## 信息体含义:
## portal.11.tm  传送门的目标地图编号，"999999999" 表示没有设置目标地图。
## portal.20.pt  传送门类型 1 隐藏传送点，2 光柱传送点，10 地图内快捷传送点，7 光柱传送点 ，6 暂无  
##
## @param portal_id 传送点id
## @param portal_config 传送点配置信息
## @return 传送门
func _create_portal(portal_id, portal_config):
	var portal = DataPortal.new()
	portal.portal_id = portal_id
	portal.target_map_id = portal_config["target_map_id"]
	if portal_config.has("position"):
		portal.position = Vector2(portal_config["position"]["x"], portal_config["position"]["y"])
	# 传送点的进入条件
	if portal_config.has("enter_condition"):
		var enter_condition = portal_config["enter_condition"]
		if enter_condition.has("need_kill_monster_count"):
			portal.need_kill_monster_count = enter_condition["need_kill_monster_count"]
	return portal


## 在地图的index.json文件中，有些地图id是 10000这种形式，和resrouces中的形式有区别 000010000
## 因此需要做一个补全转换
func _map_id_trans(map_id: String) -> String:
	var result: String = ""
	var num = "000010000".length() - map_id.length()
	while num > 0:
		result += "0"
		num -= 1
	return result + map_id
