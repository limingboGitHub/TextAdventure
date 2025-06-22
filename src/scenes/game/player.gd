extends Control
class_name Player

## 玩家的角色场景

var data_player: DataPlayer

var is_selected: bool = false

# 旋转特效比例
var rotate_scale: float = 1.0
# 旋转方向
var rotate_direction: int = 1


signal selected

# 攻击目标
var attack_target: Control

# 瞬移目标位置
var flash_target: Vector2
# 瞬移伤害碰撞体
@onready var flash_area: Area2D = $Area2D

# 巨人冲锋相关
# 冲锋时攻击判定的碰撞体
@onready var gaint_attack_area: Area2D = $GaintAttackArea2D
# 冲锋目标
var gaint_move_target_pos: Vector2 = Vector2.ZERO
var is_gaint_moving: bool = false
# 冲锋时攻击到的目标
var gaint_attack_targets: Dictionary = {}


signal find_target_started(player_scene: Control)

signal find_far_target_started(player_scene: Control)

signal attack_target_changed(attack_target)

signal mock_monster_invoked(player_scene: Control,count: int)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if data_player:
		$Name.text = data_player.player_name
		_update_hp()
		_effect_hp_attach_scope_increase(data_player)
		# 特效添加
		for effect in data_player.effect_dic.values():
			_effect_added(effect)

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
		# 监听"法力涌动"状态变化事件
		data_player.mp_cost_enhance_status_changed.connect(_on_mp_cost_enhance_status_changed)
		# 监听"血气爆发"状态变化事件
		data_player.hp_cost_enhance_status_changed.connect(_on_hp_cost_enhance_status_changed)
		# 监听蓄力开始事件
		data_player.charge_started.connect(_on_charge_started)
		# 监听蓄力完成事件
		data_player.charge_completed.connect(_on_charge_completed)
		# 监听特效添加
		data_player.effect_added.connect(_effect_added)
		# 监听特效删除
		data_player.effect_removed.connect(_effect_removed)

		if data_player.role_equip:
			data_player.role_equip.equip_on.connect(_on_role_equip_on)
			data_player.role_equip.equip_off.connect(_on_role_equip_off)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 当玩家加入地图中时，才处理process事件
	if data_player and get_parent().name == "Players":
		data_player.process(delta)

		# 调试分身角色
		if data_player.is_copy:
			pass

		if SingletonGame.is_auto:
			if data_player.is_resting:
				pass
			else:
				# 蓄力时不进行攻击
				if not data_player.get_charging_status():
					if data_player.has_effect("effect_000054"):
						_process_gaint_attack(delta)
					else:
						_process_attack(delta)
		else:
			# 监听玩家的attack事件
			if Input.is_action_pressed("attack"):
				# 蓄力时不进行攻击
				if not data_player.get_charging_status():
					if data_player.has_effect("effect_000054"):
						_process_gaint_attack(delta)
					else:
						_process_attack(delta)
			elif Input.is_action_just_released("attack"):
				pass

		# 拾取
		data_player.process_pick()

		# 处理旋转
		_process_rotate(data_player,delta)


# 巨人冲锋的攻击逻辑处理
func _process_gaint_attack(delta: float):
	if attack_target and is_instance_valid(attack_target):
		# 如果没有冲锋目标点，就计算一个
		if not is_gaint_moving:
			# 1.获取冲锋目标位置pos，确定移动方向向量a
			var move_direction = (attack_target.global_position - global_position).normalized()
			# 2.确定最终移动目标的位置为pos位置朝着方向a增加长40
			gaint_move_target_pos = attack_target.global_position + move_direction * 40
			is_gaint_moving = true
			# 如果冲锋碰撞体未启动，则启动
			if not gaint_attack_area.monitoring:
				gaint_attack_area.monitoring = true

		# 冲锋过程中，攻击范围内存在敌人时，发出data_player.process_attack()
		if not gaint_attack_targets.is_empty():
			data_player.process_attack()
		
		# 3.朝着目标移动只到到达目标位置
		if global_position.distance_to(gaint_move_target_pos) > 1:
			var move_direction = (gaint_move_target_pos - global_position).normalized()
			var speed = data_player.attribute.get_final_details().move_speed \
				* (1 + data_player.move_speed_add) \
				* SingletonGame.speed
			position += move_direction * speed * delta
		else:
			# 到达目的地，重置冲锋目标点
			is_gaint_moving = false
			# 取消选中的目标
			set_attack_target(null)
	else:
		# 没有攻击目标，重置冲锋目标点
		is_gaint_moving = false
		# 发出寻找最远敌人的信号
		find_far_target_started.emit(self)


func _process_attack(delta: float, special_target:Control = null):
	var target = attack_target
	if special_target:
		target = special_target

	# 寻找目标，移动到目标身边攻击
	if target:
		if data_player.skill:
			var skill = data_player.skill
			# 如果当前mp不足，则使用普攻的距离判定
			if data_player.mp < data_player.skill.get_mp_cost():
				skill = data_player.normal_attack

			var distance = _skill_distance(skill,data_player)
			# 如果距离小于等于目标距离，则攻击
			if global_position.distance_to(target.global_position) <= distance:
				data_player.process_attack()
			else:
				# 未达到释放距离时，移动到目标位置
				_move_to_attack_target(delta, target)
	else:
		find_target_started.emit(self)


# 计算技能的释放距离（可能有各种加成）
func _skill_distance(_skill: DataBaseSkill,_data_player: DataPlayer)-> int:
	var distance = _skill.distance
	# 如果技能有距离增幅，则使用技能的距离
	if _data_player.has_skill_enhance(_skill.id):
		distance += _data_player.get_skill_enhance(_skill.id).distance
	# 其他增幅
	distance *= (1 + _data_player.attack_range_increase)
	return distance


func _move_to_attack_target(delta: float, target: Control):
	if not data_player or data_player.is_dead:
		return
	var move_direction = target.global_position - global_position
	move_direction = move_direction.normalized()
	# 速度
	var speed = data_player.attribute.get_final_details().move_speed \
		* (1 + data_player.move_speed_add) \
		* SingletonGame.speed
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


func show_build_strength_effect(is_show: bool):
	$AttackEffect3.visible = is_show
	

## 蓄力开始时的回调
func _on_charge_started():
	$AttackEffect3.start()


## 蓄力完成时的回调
func _on_charge_completed(complete_charge_time: float):
	$AttackEffect3.visible = false
	if complete_charge_time > 0:
		print("玩家场景：蓄力正常完成，隐藏蓄力特效")
	else:
		print("玩家场景：蓄力被取消，隐藏蓄力特效")


func _effect_added(data_effect: DataEffect):
	if data_effect.type == "dizziness":
		$DizzinessLabel.show()
	elif data_effect.type == "mock_monster":
		$MockMonsterTimer.start()


func _effect_removed(data_effect: DataEffect):
	if data_effect.type == "dizziness":
		$DizzinessLabel.hide()
	elif data_effect.type == "mock_monster":
		$MockMonsterTimer.stop()


func _process_rotate(_data_player: DataPlayer,delta: float):
	# 未挂机时
	if !SingletonGame.is_auto \
		# 玩家休息时
		or _data_player.is_resting \
		# 没有攻击目标
		or !attack_target \
		# 没有"毫无章法"技能
		or !_data_player.has_effect("effect_000037"):
		rotate_scale = 1.0
		$Back.scale.x = rotate_scale
		return

	if rotate_scale > 1.0:
		rotate_direction = -1
	elif rotate_scale < -1.0:
		rotate_direction = 1
	
	rotate_scale += rotate_direction * delta * 5

	$Back.scale.x = rotate_scale
	

func _reset_rotate():
	if rotate_scale != 1.0:
		rotate_scale = 1.0
		$Back.scale.x = rotate_scale


func _on_mock_monster_timer_timeout() -> void:
	if data_player:
		var effect = data_player.get_effect("effect_000031")
		mock_monster_invoked.emit(self,effect.value)


func flash_to_target(target: Control):
	# 目标位置 偏移50像素
	var direction = (target.global_position - global_position)
	var target_position = target.position + direction.normalized() * 30
	# "电光火石"
	if data_player.has_effect("effect_000042"):
		_set_flash_damage_area(direction)
	
	# 设置攻击目标
	await get_tree().process_frame
	set_attack_target(null)
	position = target_position
	# 华丽登场
	_flash_add_damage(data_player)


func _flash_add_damage(_data_player: DataPlayer):
	if _data_player and _data_player.has_effect("effect_000044"):
		var effect = _data_player.get_effect("effect_000044")
		var skill = effect.get_special_skill()
		if skill:
			_data_player.execute_skill_no_cd(skill)


func _set_flash_damage_area(direction: Vector2):
	# 计算player到target的距离和方向
	var distance = direction.length()
	var angle = direction.angle()
	
	# 创建矩形形状，长度为距离，高度为50
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(distance, 80)
	
	# 确保flash_area有一个CollisionShape2D子节点
	var collision_shape: CollisionShape2D
	if flash_area.get_child_count() == 0 or not flash_area.get_child(0) is CollisionShape2D:
		collision_shape = CollisionShape2D.new()
		flash_area.add_child(collision_shape)
	else:
		collision_shape = flash_area.get_child(0) as CollisionShape2D
	
	# 设置碰撞形状
	collision_shape.shape = rect_shape
	
	# 设置碰撞体的位置和旋转
	# 位置设置为player和target之间的中点
	var center_position = position + direction / 2
	flash_area.position = center_position - position  # 相对于player的位置
	flash_area.rotation = angle
	
	# 启用碰撞检测
	flash_area.monitoring = true
	
	# 等待让碰撞检测生效
	await get_tree().create_timer(0.1).timeout
	
	# 禁用碰撞检测
	flash_area.monitoring = false


func _on_area_2d_area_entered(area: Area2D) -> void:
	# 检查是否是怪物
	if area.get_parent():
		if not data_player.has_effect("effect_000042"):
			return
		var effect = data_player.get_effect("effect_000042")
		var monster = area.get_parent()
		print("电光火石检测目标:", monster.name)
		var damage_details: Array[DataDamage.DamageDetail] = []
		# 攻击力
		var attack_value = data_player.get_final_details().attack
		# 伤害值
		var damage_value = attack_value * effect.value
		damage_details.append(DataDamage.DamageDetail.new("电光火石",damage_value,effect.value))
		var damage = DataDamage.new(
			DataDamage.TYPE.PHYSICAL, 
			DataDamage.SOURCE_TYPE.PLAYER, 
			damage_value)
		damage.attack_value = attack_value
		damage.damage_details = damage_details
		monster.data_monster.get_hurt(damage)
		# 玩家造成伤害行为，需要记录伤害信息
		data_player.cause_damage(damage)
		# 如果怪物没有死亡，则设置攻击目标
		if not monster.data_monster.is_dead:
			monster.set_attack_target(self)


func set_black():
	# 设置黑色
	modulate = Color(0.3,0.3,0.3,1)


func _on_gaint_attack_area_2d_area_entered(area: Area2D) -> void:
	# 检查是否是怪物
	var parent = area.get_parent()
	if parent is Monster:
		print("_on_gaint_attack_area_2d_area_entered ",parent.data_monster.monster_unique_id)
		gaint_attack_targets[parent.data_monster.monster_unique_id] = parent


func _on_gaint_attack_area_2d_area_exited(area: Area2D) -> void:
	# 检查是否是怪物
	var parent = area.get_parent()
	if parent is Monster:
		print("_on_gaint_attack_area_2d_area_exited ",parent.data_monster.monster_unique_id)
		gaint_attack_targets.erase(parent.data_monster.monster_unique_id)
