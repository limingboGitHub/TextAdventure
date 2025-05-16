class_name DropThingManager

## 掉落物管理类
##
## 根据怪物掉落表生成掉落物等。


var res_manager: ResManager

var money_id_list = [
	"09000000",
	"09000001",
	"09000002",
	"09000003"
]

func _init(_res_manager: ResManager) -> void:
	self.res_manager = _res_manager


func get_drop_things(monster_id: String,is_elite: bool) -> Array[DataBagItem]:
	var result: Array[DataBagItem] = []
	if not res_manager.monster_drops_rate.has(monster_id):
		return result
		
	var drop_rate = res_manager.monster_drops_rate[monster_id]
	for drop_id in drop_rate.keys():
		if drop_id in money_id_list:
			var data_money = _get_money_drop(monster_id, drop_id)
			if data_money:
				data_money.uuid = RandomTool.random_num()
				result.append(data_money)
		else:
			var drop_rate_info = drop_rate[drop_id]
			# 物品爆率（精英怪10倍爆率）
			var rate = float(drop_rate_info["rate"]) * (10 if is_elite else 1)
			# 随机一个0-1的数字，查看是否命中
			var random_hit = randf()
			if random_hit < rate:
				## 命中
				var data_bag_item = create_item(drop_id)
				if data_bag_item != null:
					result.append(data_bag_item)

	return result


func _get_money_drop(monster_id,money_id: String) -> DataMoney:
	var drop_rate = res_manager.monster_drops_rate[monster_id]
	var money_rate = drop_rate[money_id]
	var rate = float(money_rate["rate"])
	# 随机一个1-10000的数字，查看是否命中
	var random_hit = randi() % 10000
	if random_hit < rate * 100:
		# 命中
		var min = int(money_rate["min"])
		var max = int(money_rate["max"])
		var random_money = randi_range(min, max)

		var data_money = DataMoney.new()
		data_money.type = DataBagItem.TYPE_MONEY
		data_money.id = money_id
		data_money.name = "金币"
		data_money.count = random_money
		return data_money
	
	return null


func create_item(drop_id) -> DataBagItem:
	if DataConsume.is_consume(drop_id):
		var item = DataConsume.new()
		item.id = drop_id
		_load_consume(item)
		return item
	elif DataEtc.is_etc(drop_id):
		var item = DataEtc.new()
		item.id = drop_id
		_load_etc(item)
		return item
	elif DataEquip.is_equip(drop_id):
		var data_equip = DataEquip.new()
		data_equip.id = drop_id
		_load_equip(data_equip)
		return data_equip
	else:
		return null


func _create_scroll(dic: Dictionary) -> DataConsume.Scroll:
	var scroll = DataConsume.Scroll.new()
	
	if dic.has("use_type"):
		scroll.use_type = dic["use_type"]
	if dic.has("success_rate"):
		scroll.success_rate = float(dic["success_rate"])
	# 根据随机池随机属性
	if dic.has("attribute_random_list"):
		var attribute_random_list = dic["attribute_random_list"]
		# 从多套随机搭配中随机一套
		var random_index = randi_range(0, attribute_random_list.size() - 1)
		var attribute_random = attribute_random_list[random_index]

		if attribute_random.has("pool"):
			var pool = attribute_random["pool"]
			var count = attribute_random["count"]

			## 从pool池中随机count个属性
			##
			# 打乱属性池子里的属性
			var pool_index = range(pool.size())
			pool_index.shuffle()
			# 取出count个属性
			for i in range(count):
				var random_attribute = pool[pool_index[i]]
				scroll.attribute_ability.load(random_attribute)
				scroll.attribute_details.load(random_attribute)
			
	
	if dic.has("effect"):
		var effect_id = dic["effect"]
		var effect_info = res_manager.get_effect_info(effect_id)
		var effect_type = effect_info["effect_type"]
		scroll.data_effect = DataEffect.new(effect_id,effect_type)
		if effect_info.has("value"):
			scroll.data_effect.value = effect_info["value"]
		if effect_info.has("value_type"):
			scroll.data_effect.value_type = effect_info["value_type"]
		if effect_info.has("desc"):
			scroll.data_effect.desc = effect_info["desc"]
		# 技能增强类型的特效
		if effect_info.has("skill_enhance"):
			var skill_enhance_dic = effect_info["skill_enhance"]
			var skill_enhance = DataSkillEnhance.new()
			skill_enhance.skill_id = skill_enhance_dic["skill_id"]
			
			for field in skill_enhance.get_fields():
				if skill_enhance_dic.has(field):
					skill_enhance.set_field(field, skill_enhance_dic[field])
	
			# 技能名称从资源管理器中获取
			skill_enhance.name = res_manager.get_skill_name(skill_enhance.skill_id)
			scroll.data_effect.skill_enhance = skill_enhance
	return scroll


func _create_buff(drop_id: String,name: String,dic: Dictionary) -> DataBuff:
	var data_buff = DataBuff.new()
	data_buff.id = drop_id
	data_buff.buff_type = 0
	data_buff.name = name

	# 增益的属性值
	var attribute_ability = AttributeAbility.new()
	if dic.has("ability"):
		var ability_dic = dic["ability"]
		if ability_dic.has("power"):
			attribute_ability.power = ability_dic["power"]
		if ability_dic.has("agility"):
			attribute_ability.agility = ability_dic["agility"]
		if ability_dic.has("intelligence"):
			attribute_ability.intelligence = ability_dic["intelligence"]
		if ability_dic.has("luck"):
			attribute_ability.luck = ability_dic["luck"]
	data_buff.attribute_ability = attribute_ability
	# 增益的能力值
	var attribute_details = AttributeDetails.new()
	if dic.has("details"):
		var details_dic = dic["details"]
		attribute_details.load(details_dic)
	data_buff.attribute_details = attribute_details

	# 特殊效果
	if dic.has("effect_list"):
		var effect_dic_list = dic["effect_list"]
		for effect_dic in effect_dic_list:
			if effect_dic.has("effect_type"):
				var effect_id = effect_dic["id"]
				var effect_type = effect_dic["effect_type"]
				var value = effect_dic["value"]
				var value_type = effect_dic["value_type"]
				var data_effect = DataEffect.new(effect_id,effect_type)
				data_effect.value = value
				data_effect.value_type = value_type
				data_buff.add_effect(data_effect)
	
	# 持续时间
	var duration = dic["duration"] / SingletonGame.speed
	data_buff.duration = duration
	data_buff.remaining_time = duration
	data_buff.last_update_time = duration
	return data_buff


func load_item(data_bag_item: DataBagItem):
	if data_bag_item is DataConsume:
		_load_consume(data_bag_item)
	elif data_bag_item is DataEtc:
		_load_etc(data_bag_item)
	elif data_bag_item is DataEquip:
		_load_equip(data_bag_item)


# 加载消耗品的详细信息
func _load_consume(data_consume: DataConsume):
	var consume_dic = res_manager.consume_dic
	data_consume.name = consume_dic[data_consume.id]["name"]
	data_consume.desc = consume_dic[data_consume.id]["desc"]
	# 价格
	if consume_dic[data_consume.id].has("price"):
		data_consume.price = int(consume_dic[data_consume.id]["price"])
	# 堆叠上限
	if consume_dic[data_consume.id].has("slotMax"):
		data_consume.slot_max = int(consume_dic[data_consume.id]["slotMax"])
	# 物品品质
	if consume_dic[data_consume.id].has("quality"):
		data_consume.quality = consume_dic[data_consume.id]["quality"]

	if consume_dic[data_consume.id].has("type"):
		var type = consume_dic[data_consume.id]["type"]
		if type == "recovery":
			var recovery = DataConsume.Recovery.new()
			# 回复生命值
			if consume_dic[data_consume.id].has("hp"):
				recovery.spec_hp = int(consume_dic[data_consume.id]["hp"])
			# 回复魔法值
			if consume_dic[data_consume.id].has("mp"):
				recovery.spec_mp = int(consume_dic[data_consume.id]["mp"])
			# 回复生命值百分比
			if consume_dic[data_consume.id].has("hpR"):
				recovery.spec_hp_r = consume_dic[data_consume.id]["hpR"]
			# 回复魔法值百分比
			if consume_dic[data_consume.id].has("mpR"):
				recovery.spec_mp_r = consume_dic[data_consume.id]["mpR"]
			data_consume.recovery = recovery
		elif type == "scroll":
			data_consume.scroll = _create_scroll(consume_dic[data_consume.id])
		elif type == "buff":
			if consume_dic[data_consume.id].has("buff"):
				data_consume.data_buff = _create_buff(
					data_consume.id,
					data_consume.name,
					consume_dic[data_consume.id]["buff"])
	# 物品品质
	if consume_dic.has("quality"):
		data_consume.quality = consume_dic["quality"]


# 加载其他物品的详细信息
func _load_etc(data_etc: DataEtc):
	var etc_dic = res_manager.etc_dic
	data_etc.name = etc_dic[data_etc.id]["name"]
	data_etc.desc = etc_dic[data_etc.id]["desc"]
	# 价格
	if etc_dic[data_etc.id].has("price"):
		data_etc.price = int(etc_dic[data_etc.id]["price"])
	# 堆叠上限
	if etc_dic[data_etc.id].has("slotMax"):
		data_etc.slot_max = int(etc_dic[data_etc.id]["slotMax"])
	# 物品品质
	if etc_dic[data_etc.id].has("quality"):
		data_etc.quality = etc_dic[data_etc.id]["quality"]


# 加载装备的详细信息
func _load_equip(data_equip: DataEquip):
	# 装备类型 为物品id的前缀，例如：upper_body_000001，则装备类型为upper_body
	var last_underscore_pos = data_equip.id.rfind("_")
	var equip_type = data_equip.id.substr(0, last_underscore_pos)
	data_equip.equip_type = equip_type
		
	var equip_info = null
	# 读取装备详细信息
	var equip_dic = res_manager.equip_dic
	if equip_dic.has(data_equip.equip_type) and equip_dic[data_equip.equip_type].has(data_equip.id):
		equip_info = equip_dic[data_equip.equip_type][data_equip.id]
		# 基本信息
		data_equip.name = equip_info["name"]
		data_equip.desc = equip_info["desc"]
		data_equip.price = int(equip_info["price"])
		# 装备等级
		data_equip.require_level = int(equip_info["require_level"])
		
		# 装备职业
		if equip_info.has("require_job"):
			data_equip.require_job = equip_info["require_job"]
		# 装备力量
		if equip_info.has("require_power"):
			data_equip.require_power = int(equip_info["require_power"])
		# 装备敏捷
		if equip_info.has("require_agility"):
			data_equip.require_agility = int(equip_info["require_agility"])
		# 装备智力
		if equip_info.has("require_intelligence"):
			data_equip.require_intelligence = int(equip_info["require_intelligence"])
		# 装备幸运
		if equip_info.has("require_luck"):
			data_equip.require_luck = int(equip_info["require_luck"])

		#region 属性信息
		# 基础能力值
		if equip_info.has("attribute_ability"):
			data_equip.init_ability(equip_info["attribute_ability"])
		# 基础详情属性
		if equip_info.has("attribute_details"):
			data_equip.init_details(equip_info["attribute_details"])
		#endregion

		#region 装备特殊效果
		if equip_info.has("effect"):
			var effect_id = equip_info["effect"]["id"]
			var effect_type = equip_info["effect"]["effect_type"]
			var value_type = equip_info["effect"]["value_type"]
			var value = equip_info["effect"]["value"]

			var data_effect = DataEffect.new(effect_id,effect_type)
			data_effect.value = value
			data_effect.value_type = value_type
			data_equip.add_effect(data_effect)
		#endregion

	# 物品品质
	if equip_info.has("quality"):
		data_equip.quality = equip_info["quality"]
	# 强化次数
	if equip_info.has("max_upgrade_times"):
		data_equip.max_upgrade_times = int(equip_info["max_upgrade_times"])
	
	# 更新装备的最终属性
	data_equip.update_final_ability()



## 根据装备属性中的关键字获取随机范围的属性
##
## @param equip_info 装备信息
## @param key 属性名
## @return 属性值
func _get_equip_attribute(equip_info: Dictionary,key: String) -> int:
	if equip_info.has("min_" + key) and equip_info.has("max_" + key):
		var min_value = int(equip_info["min_" + key])
		var max_value = int(equip_info["max_" + key])
		var random_value = randi_range(min_value, max_value)
		return random_value
	else:
		return 0


func get_drop_rate_info(monster_id: String) -> Dictionary:
	return res_manager.monster_drops_rate[monster_id]
