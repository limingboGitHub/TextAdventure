class_name DataRole

# 玩家和怪物的基类

var hp: int
var mp: int

var attribute = Attribute.new()

## buff字典 
## DataBuff类承载了 属性、特效、时间
## key:buff_id, value:DataBuff
var buff_dic = {}

## 特殊效果字典 
## 角色最终特殊效果的集合，该集合的值由buff_dic中所有的特效叠加而成
## key:effect_id, value:DataEffect
var effect_dic = {}

## 技能增幅效果字典
## 技能增幅类特殊效果单独存储，否则仅通过type无法区分不同技能的增幅
## key:skill_id, value:DataSkillEnhance
var skill_enhance_dic = {}

var is_dead = false

signal role_dead(data_role: DataRole)

signal role_hurted(data_role: DataRole,data_damage: DataDamage)

signal buff_added(data_buff: DataBuff)

signal effect_added(data_effect: DataEffect)

func process(delta: float):

	# buff时间计算
	if is_dead:
		return
	for buff in buff_dic.values():
		for effect in buff.get_all_effects():
			if effect.type == "poison":
				if effect.last_invoke_time == 0:
					get_hurt(DataDamage.new(DataDamage.TYPE.POISON,DataDamage.SOURCE_TYPE.POISON,effect.value))
					effect.last_invoke_time = int(Time.get_ticks_msec() * SingletonGame.speed / 1000.0)
				elif effect.last_invoke_time != int(Time.get_ticks_msec() * SingletonGame.speed / 1000.0):
					get_hurt(DataDamage.new(DataDamage.TYPE.POISON,DataDamage.SOURCE_TYPE.POISON,effect.value))
					effect.last_invoke_time = int(Time.get_ticks_msec() * SingletonGame.speed / 1000.0)
		if not buff.is_permanent():
			buff.reduce_buff_time(delta)


func get_hurt(data_damage: DataDamage):
	# 造成伤害
	hp -= data_damage.value
	hp = max(hp,0)
	# 发送角色受伤信号
	role_hurted.emit(self,data_damage)

	# 角色死亡判定
	if hp <= 0:
		hp = 0
		kill_role()


func kill_role():
	is_dead = true
	# 发送角色死亡信号
	role_dead.emit(self)


func get_max_hp()-> int:
	return attribute.final_details.max_hp


func get_max_mp()-> int:
	return attribute.final_details.max_mp


## 添加buff
func add_buff(data_buff: DataBuff):
	# buff存在，则存在覆盖机制，删除旧buff
	if buff_dic.has(data_buff.id):
		buff_dic[data_buff.id].remove()
	# 添加新buff
	buff_dic[data_buff.id] = data_buff
	buff_added.emit(data_buff)

	if data_buff.attribute_ability != null:
		attribute.add_ability(data_buff.id, data_buff.attribute_ability)
	if data_buff.attribute_details != null:
		attribute.add_details(data_buff.id, data_buff.attribute_details)
	# 相同type的特殊效果覆盖
	for effect in data_buff.get_all_effects():
		add_effect(effect)

		# 巨人之力，增加力量属性
		if effect.id == "effect_000007":
			var scale_factor = attribute.final_details.max_hp / 100.0
			var power = effect.value * scale_factor
			var attribute_ability = AttributeAbility.new()
			attribute_ability.power = power
			attribute.add_ability(data_buff.id, attribute_ability)
	# 监听buff的结束
	data_buff.buff_removed.connect(self._on_buff_removed)


func add_effect(data_effect: DataEffect):
	if data_effect.type == DataEffect.SkillEnhance:
		# 技能增幅类特效单独存储
		var skill_enhance = data_effect.skill_enhance
		if skill_enhance != null:
			if skill_enhance_dic.has(skill_enhance.skill_id):
				skill_enhance_dic[skill_enhance.skill_id].append(skill_enhance)
			else:
				skill_enhance_dic[skill_enhance.skill_id] = skill_enhance.copy()
	else:
		# 其他特效存储
		if effect_dic.has(data_effect.id):
			effect_dic[data_effect.id].append(data_effect)
		else:
			effect_dic[data_effect.id] = data_effect.copy()
	effect_added.emit(data_effect)


func _remove_effect(data_effect: DataEffect):
	if data_effect.type == DataEffect.SkillEnhance:
		# 技能增幅类特效移除
		var skill_enhance = data_effect.skill_enhance
		if skill_enhance != null:
			if skill_enhance_dic.has(skill_enhance.skill_id):
				# 减少特效值
				skill_enhance_dic[skill_enhance.skill_id].remove(skill_enhance)
				# 如果特效值为0，则删除特效
				if skill_enhance_dic[skill_enhance.skill_id].is_empty():
					skill_enhance_dic.erase(skill_enhance.skill_id)
	else:
		# 其他特效移除
		if effect_dic.has(data_effect.id):
			# 减少特效值
			effect_dic[data_effect.id].remove(data_effect)
			# 如果特效值为0，则删除特效
			if effect_dic[data_effect.id].value <= 0:
				effect_dic.erase(data_effect.id)


func remove_buff(buff_id: String):
	# 删除effect
	if buff_dic.has(buff_id):
		# 删除属性
		attribute.remove_ability(buff_id)
		attribute.remove_details(buff_id)
		# 删除特殊效果
		for effect in buff_dic[buff_id].get_all_effects():
			_remove_effect(effect)
		# 删除buff
		buff_dic.erase(buff_id)


func set_buff_active(buff_id: String, active: bool):
	if buff_dic.has(buff_id):
		buff_dic[buff_id].set_active(active)


func _on_buff_removed(data_buff: DataBuff):
	remove_buff(data_buff.id)


func get_buff_by_id(id: String) -> DataBuff:
	if buff_dic.has(id):
		return buff_dic[id]
	else:
		return null


func has_effect(effect_id: String) -> bool:
	return effect_dic.has(effect_id) and effect_dic[effect_id].is_active


func get_effect(effect_id: String) -> DataEffect:
	return effect_dic[effect_id]


func has_skill_enhance(skill_id: String) -> bool:
	return skill_enhance_dic.has(skill_id)


func get_skill_enhance(skill_id: String) -> DataSkillEnhance:
	return skill_enhance_dic[skill_id]


func get_final_details() -> AttributeDetails:
	return attribute.final_details
