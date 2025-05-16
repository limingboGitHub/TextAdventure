class_name PlayerManager

## 管理人物、背包、装备

var data_player : DataPlayer
var data_bag : DataBag
var role_equip : DataRoleEquip
var data_skill_bag : DataSkillBag
var data_alchemy_bag : DataAlchemyBag


## 对外接口：根据人物id创建人物角色
func create_player(id: String,exp_dic: Dictionary):
	var _data_player = DataPlayer.new()
	_data_player.player_id = id
	_data_player.exp_dic = exp_dic
	_data_player.init_base_ability(12,6,5,1)

	_data_player.init_base_details()
	
	_data_player.attribute.update()

	_data_player.hp = _data_player.final_details.max_hp
	_data_player.mp = _data_player.final_details.max_mp

	_data_player.max_exp = _data_player.exp_dic[str(1)]
	return _data_player


func load_player(_data_player: DataPlayer):
	data_player = _data_player
	# 监听人物升级
	data_player.level_updated.connect(_on_level_up)


# 初始化背包，如果背包为空，则创建新的背包
func init_data_bag(_data_bag: DataBag):
	if _data_bag == null:
		data_bag = DataBag.new()
		data_bag.money = 0
	else:
		data_bag = _data_bag
	# 监听背包的物品使用
	data_bag.item_used.connect(_on_item_used)


func init_data_alchemy_bag(
	_data_alchemy_bag: DataAlchemyBag,
	alchemy_config_dic: Dictionary,
	item_id_name_map: Dictionary
):
	if _data_alchemy_bag == null:
		data_alchemy_bag = DataAlchemyBag.new()
	else:
		data_alchemy_bag = _data_alchemy_bag
	data_alchemy_bag.init_config_dic(alchemy_config_dic,item_id_name_map)


func init_role_equip(_data_role_equip: DataRoleEquip):
	if _data_role_equip == null:
		role_equip = DataRoleEquip.new()
	else:
		role_equip = _data_role_equip
	
	# 监听装备栏的装备添加
	role_equip.equip_on.connect(_on_equip_on)
	# 监听装备栏的装备移除
	role_equip.equip_off.connect(_on_equip_off)
	return role_equip


func create_data_skill_bag(skill_dic: Dictionary, effect_dic: Dictionary, _data_skill_bag: DataSkillBag):
	if _data_skill_bag == null:
		data_skill_bag = DataSkillBag.new()
		data_skill_bag.init_dic(skill_dic, effect_dic)
		# 增加测试技能
		#var skill_list = [
		#	data_skill_bag.create("skill_000001"),
		#	data_skill_bag.create("skill_000002"),
		#	data_skill_bag.create("skill_000003"),
		#	data_skill_bag.create("skill_000004"),
		#	data_skill_bag.create("skill_000005"),
		#	data_skill_bag.create("skill_000006"),
		#	data_skill_bag.create("skill_000007"),
		#	data_skill_bag.create("skill_000008"),
		#	data_skill_bag.create("skill_000009"),
			
		#	data_skill_bag.create("skill_000101"),
		#	data_skill_bag.create("skill_000102"),
		#	data_skill_bag.create("skill_000103"),

		#	data_skill_bag.create("skill_000201"),
		#	data_skill_bag.create("skill_000202"),
		#	data_skill_bag.create("skill_000203"),
		#]
		#for skill in skill_list:
		#	data_skill_bag.add_skill("测试", skill)
		#data_skill_bag.skill_point = 100
	else:
		data_skill_bag = _data_skill_bag
		data_skill_bag.init_dic(skill_dic, effect_dic)
	return data_skill_bag


# 加载永久被动技能的属性
func load_attribute_buff_skill():
	if data_player == null || data_skill_bag == null:
		return

	for phase in data_skill_bag.data.keys():
		for skill in data_skill_bag.data[phase]:
			# 技能类型为buff类，并且是永久被动技能
			if (skill is DataAttriBuffSkill or skill is DataEffectBuffSkill) and skill.is_permanent():
				if skill.level > 0:
					data_player.add_buff(skill.create_buff())
	# 监听技能等级变化
	data_skill_bag.skill_level_updated.connect(_on_skill_level_changed)


func load_role_equip():
	if role_equip == null:
		return

	for item in role_equip.items.values():
		if item is DataEquip and not item.data_effects.is_empty():
			_on_equip_on(item)


func _on_skill_level_changed(data_skill: DataBaseSkill):
	print('技能等级变化', data_skill.name, data_skill.level)
	# 如果技能等级大于1，则删除旧的buff
	if data_skill.level > 1:
		data_player.remove_buff(data_skill.id)
	# 技能类型为buff类，并且是永久被动技能，则在技能等级变化时就为玩家添加buff
	if data_skill is DataBuffSkill and data_skill.is_permanent():
		data_player.add_buff(data_skill.create_buff())


func _on_item_used(item: DataBagItem):
	if item is DataConsume:
		print('使用了消耗品', item.name)
		if item.recovery != null:
			if item.recovery.spec_hp > 0:
				data_player.recover_hp(item.recovery.spec_hp)
			if item.recovery.spec_mp > 0:
				data_player.recover_mp(item.recovery.spec_mp)
			if item.recovery.spec_hp_r > 0:
				data_player.recover_hp_rate(item.recovery.spec_hp_r)
			if item.recovery.spec_mp_r > 0:
				data_player.recover_mp_rate(item.recovery.spec_mp_r)

		if item.data_buff != null:
			# 这里的buff类需要copy一个新实例，否则重复使用时会有问题
			data_player.add_buff(item.data_buff.copy())

		if item.scroll != null:
			# 使用卷轴
			data_bag.ready_use_scroll(item)
		else:
			data_bag.remove_item(item,1)
	elif item is DataEquip:
		print('装备了装备', item.name)
		
		# 判断玩家属性是否满足装备要求
		if not is_match_equip_require(item):
			ToastManager.add_toast("不满足装备要求")
			return

		# 从装备栏中移除同位置的装备（会自动监听装备栏装备的卸载，并加入背包）
		role_equip.remove_by_type(item.equip_type)
		# 从背包中移除装备
		data_bag.remove_item(item,1)
		# 加入装备栏
		role_equip.add(item)

	elif item is DataEtc:
		return
	else:
		print('未知物品类型')


# 判断玩家属性是否满足装备要求
func is_match_equip_require(item: DataEquip) -> bool:
	# 等级
	if data_player.level < item.require_level:
		return false
	# TODO 其他要求
	return true


## 监听装备栏装备的添加
func _on_equip_on(item: DataEquip):
	# 更新人物的装备属性
	if item.has_ability():
		data_player.attribute.add_ability(item.equip_type, item.get_all_ability())

	if item.has_details():
		data_player.attribute.add_details(item.equip_type, item.get_all_details())

	# 添加装备特殊效果
	var all_effects = item.get_all_effects()
	if all_effects.size() > 0:
		var buff = DataBuff.new()
		buff.id = item.id
		buff.name = item.name
		for data_effect in all_effects:
			buff.add_effect(data_effect)
		data_player.add_buff(buff)

	# 更新人物属性
	if item.has_ability() or item.has_details() or all_effects.size() > 0:
		data_player.update_attribute()


## 技能增幅
func _skill_enhance(skill_enhance: DataSkillEnhance,is_add: bool):
	# 找到背包的横扫攻击技能
	var skill = data_skill_bag.get_skill_by_id(skill_enhance.skill_id)
	if skill != null:
		if is_add:
			skill.distance += skill_enhance.distance
			skill.radius += skill_enhance.radius
			skill.count += skill_enhance.count
			skill.cd += skill_enhance.cd
		else:
			skill.distance -= skill_enhance.distance
			skill.radius -= skill_enhance.radius
			skill.count -= skill_enhance.count
			skill.cd -= skill_enhance.cd


## 监听装备栏装备的移除
func _on_equip_off(item: DataEquip):
	data_bag.add_item(item)

	# 移除装备属性
	data_player.attribute.ability_dic.erase(item.equip_type)
	data_player.attribute.details.erase(item.equip_type)

	# 移除装备特殊效果
	for data_effect in item.get_all_effects():
		data_player.remove_buff(item.id)

		#if data_effect.skill_enhance:
		#	# 技能增强去除
		#	_skill_enhance(data_effect.skill_enhance,false)
			
	data_player.update_attribute()


func get_data_bag() -> DataBag:
	return data_bag


func _on_level_up(_data_player: DataPlayer):
	# 大于等于10级时，增加技能点
	if _data_player.level >= 10:
		data_skill_bag.add_skill_point(2)


func get_data_alchemy_bag() -> DataAlchemyBag:
	return data_alchemy_bag
