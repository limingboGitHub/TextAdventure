extends Control

## 玩家的角色场景

var data_player: DataPlayer

var is_selected: bool = false

signal selected

# 攻击目标
var attack_target: Control

signal find_target_started(player_scene: Control)

signal attack_target_changed(attack_target)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if data_player:
		$Name.text = data_player.player_name
		_update_hp()
		_effect_hp_attach_scope_increase(data_player)

		# 监听玩家受伤事件
		data_player.role_hurted.connect(_on_player_get_hurted)
		# 监听玩家hp更新事件
		data_player.hp_updated.connect(_on_player_hp_updated)
		# 监听玩家恢复生命值事件
		data_player.hp_recovered.connect(_on_player_hp_recovered)
		# 监听玩家的无敌状态事件
		data_player.can_not_be_hurt_changed.connect(_on_player_can_not_be_hurt_changed)
		# 监听玩家属性更新事件
		data_player.attribute_updated.connect(_on_player_attribute_updated)
		# 监听玩家休息开始事件
		data_player.rest_started.connect(_on_player_rest_started)
		# 监听“法力涌动”状态变化事件
		data_player.mp_cost_enhance_status_changed.connect(_on_mp_cost_enhance_status_changed)
		# 监听“血气爆发”状态变化事件
		data_player.hp_cost_enhance_status_changed.connect(_on_hp_cost_enhance_status_changed)

		if data_player.role_equip:
			data_player.role_equip.equip_on.connect(_on_role_equip_on)
			data_player.role_equip.equip_off.connect(_on_role_equip_off)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# 当玩家加入地图中时，才处理process事件
	if data_player and get_parent().name == "Players":
		data_player.process(delta)

		if SingletonGame.is_auto:
			if data_player.is_resting:
				pass
			else:
				_process_attack(delta)
				data_player.process_pick()
		else:
			# 监听玩家的attack事件
			if Input.is_action_pressed("attack"):
				_process_attack(delta)
			elif Input.is_action_just_released("attack"):
				pass

			# 拾取
			if Input.is_action_pressed("pick"):
				data_player.process_pick()


func _process_attack(delta: float):
	# 寻找目标，移动到目标身边攻击
	if attack_target:
		if data_player.skill:
			var skill = data_player.skill
			# 如果当前mp不足，则使用普攻的距离判定
			if data_player.mp < data_player.skill.get_mp_cost():
				skill = data_player.normal_attack

			var distance = skill.distance
			# 如果技能有距离增幅，则使用技能的距离
			if data_player.has_skill_enhance(skill.id):
				distance += data_player.get_skill_enhance(skill.id).distance
			# 其他增幅
			distance *= (1 + data_player.attack_range_increase)
			# 如果距离小于等于目标距离，则攻击
			if global_position.distance_to(attack_target.global_position) <= distance:
				data_player.process_attack()
			elif not data_player.has_effect(DataEffect.DragMonster):
				_move_to_attack_target(delta)
	else:
		find_target_started.emit(self)


func _move_to_attack_target(delta: float):
	var move_direction = attack_target.global_position - global_position
	move_direction = move_direction.normalized()
	# 速度
	var speed = data_player.attribute.get_final_details().move_speed * SingletonGame.speed
	position += move_direction * speed * delta
	#print("move_to_attack_target:",move_direction)
	#print("move_to_attack_target:",position)
	

func init_data(data_player: DataPlayer):
	self.data_player = data_player


func clear_data():
	data_player = null
	$Name.text = ""
	$Back/HpBar/ColorBar.set_value(0,0)


func _add_damage_ani(damage: DataDamage):
	var damage_scene = SingletonGameScenePre.DamageTextScene.instantiate()
	damage_scene.set_damage(damage)
	if damage.type == DataDamage.TYPE.POISON:
		$PoisonDamageGroup.add(damage_scene)
	else:
		$DamageGroup.add(damage_scene)


func _update_hp():
	$Back/HpBar/ColorBar.set_value(data_player.attribute.final_details.max_hp, data_player.hp)


func _on_player_get_hurted(_data_role: DataRole, data_damage: DataDamage):
	_update_hp()
	_add_damage_ani(data_damage)


func _on_player_hp_recovered(player: DataPlayer, value: int):
	_update_hp()
	# TODO 这里的伤害来源需要修改
	var data_damage = DataDamage.new(DataDamage.TYPE.HEAL,DataDamage.SOURCE_TYPE.PLAYER, value)
	_add_damage_ani(data_damage)


func _on_player_hp_updated(_data_player: DataPlayer):
	_update_hp()


func _on_player_can_not_be_hurt_changed(player: DataPlayer):
	if player.can_not_be_hurt:
		_player_can_not_be_hurt_effect()


func _on_player_attribute_updated(player: DataPlayer):
	_effect_hp_attach_scope_increase(player)


func _effect_hp_attach_scope_increase(player: DataPlayer):
	if player.has_effect("effect_000007"):
		# 每100点血量增加一定量体型
		var scale_factor = player.attribute.final_details.max_hp / 100.0

		var effect = player.get_effect("effect_000007")
		var scale_add = scale_factor * effect.value / 100.0
		scale = Vector2(1 + scale_add, 1 + scale_add)
		print("【泰坦之魂】增加体型：",scale_add)
	else:
		scale = Vector2(1,1)


func _player_can_not_be_hurt_effect():
	# 展示对象
	var effect_obj = $Back
	# 展示一个0.2秒一个周期的闪烁效果
	var tween = create_tween()
	tween.tween_property(effect_obj, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property(effect_obj, "modulate", Color(1, 1, 1, 1), 0.1).set_delay(0.1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_loops(10)  # 2秒/0.2秒=10次循环


func add_skill_executed_effect(skill: DataBaseSkill,direction: Vector2):
	# 实例化技能名称场景
	#var skill_name_scene = SkillNameScene.instantiate()
	var skill_name_scene = SingletonGameScenePre.SkillNameScene.instantiate()
	skill_name_scene.set_skill(skill)
	# 技能释放的方向是目标的反方向
	skill_name_scene.direction = -direction
	$SkillNameGroup.add_child(skill_name_scene)


# 更新角色装备展示
func update_role_equip(data_equip: DataEquip):
	_on_role_equip_on(data_equip)


func _on_role_equip_on(data_equip: DataEquip):
	if data_equip.equip_type == DataEquip.TYPE_WEAPON:
		# 展示装备标识
		$Back/WeaponPanel.show()
		# 装备只展示最后一个字
		$Back/WeaponPanel/Label.text = data_equip.name[-1]
		# 根据装备品质调整style
		_show_quality(data_equip.quality)


func _on_role_equip_off(_data_equip: DataEquip):
	# 隐藏装备标识
	if _data_equip.equip_type == DataEquip.TYPE_WEAPON:
		$Back/WeaponPanel.hide()


func _show_quality(quality: String) -> void:
	var quality_suffix = "common"
	if quality == DataBagItem.QUALITY_GOOD:
		quality_suffix = "good"
	elif quality == DataBagItem.QUALITY_RARE:
		quality_suffix = "rare"
	elif quality == DataBagItem.QUALITY_EPIC:
		quality_suffix = "epic"
	var stylebox = load("res://theme/quality/quality_" + quality_suffix + ".tres")
	$Back/WeaponPanel.add_theme_stylebox_override("panel", stylebox)


func _on_panel_my_pressed(_ui: Control) -> void:
	select()
	# 测试代码
	#_player_can_not_be_hurt_effect()


func enable_select():
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE


func select():
	if is_selected:
		return
		
	var style_box =  load("res://theme/monster_selected.tres")
	#StyleBoxFlat
	$Back.add_theme_stylebox_override("panel",style_box)
	is_selected = true
	selected.emit()


func unselect():
	if not is_selected:
		return

	$Back.remove_theme_stylebox_override("panel")
	is_selected = false


func set_attack_target(target: Control):
	attack_target = target
	attack_target_changed.emit(attack_target)
	# 监听目标死亡
	if attack_target:
		# 检查信号是否已连接
		if not attack_target.data_monster.role_dead.is_connected(_on_attack_target_dead):
			attack_target.data_monster.role_dead.connect(_on_attack_target_dead)


func _on_attack_target_dead(_data_role: DataRole):
	set_attack_target(null)


func _on_player_rest_started(_player: DataPlayer):
	set_attack_target(null)


func _on_mp_cost_enhance_status_changed(_player: DataPlayer,is_match: bool):
	$MpCostEnhanceLabel.visible = is_match


func _on_hp_cost_enhance_status_changed(_player: DataPlayer,is_match: bool):
	$HpCostEnhanceLabel.visible = is_match
