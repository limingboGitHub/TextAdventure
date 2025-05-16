extends Control


var data_monster: DataMonster

var press_pos := Vector2.ZERO

var is_selected = false

const dead_ani_time = 1
var dead_ani_time_rest = dead_ani_time

var attack_target: Control = null


signal pressed()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if data_monster:

		if data_monster.is_elite:
			$Back/Name.text = data_monster.name + "【精英】"
			# 名称调整为绿色
			$Back/Name.add_theme_color_override("font_color",Color.GREEN)
		else:
			$Back/Name.text = data_monster.name
		_update_hp()
		# 监听受伤事件
		data_monster.role_hurted.connect(_on_get_hurted)
		# 监听特效添加事件
		data_monster.effect_added.connect(_on_effect_added)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if data_monster:
		data_monster.process(delta)

		_process_attack(delta)

		if data_monster.is_dead:
			# 更新死亡动画
			if dead_ani_time_rest > 0:
				dead_ani_time_rest -= delta
				# 更新透明度动画
				var alpha = dead_ani_time_rest / dead_ani_time
				modulate.a = alpha
			else:
				clear()
				queue_free()


func clear():
	data_monster.role_hurted.disconnect(_on_get_hurted)
	data_monster.effect_added.disconnect(_on_effect_added)


func _process_attack(delta: float):
	if attack_target:
		var data_player = attack_target.data_player
		if data_player.is_dead:
			return
		# 普通怪物在目标休息时会丢失目标
		if (data_player.is_resting and data_monster.type == "normal"):
			attack_target = null
			return

		if not data_player.can_not_be_hurt:
			# 如果攻击目标是玩家，且已经离开了当前地图，则不进行攻击
			if data_player.map_id != data_monster.current_map_id:
				set_attack_target(null)
				return
			# 如果目标距离大于技能距离，则移动
			if global_position.distance_to(attack_target.global_position) > data_monster.skill.radius:
				_move_to_attack_target(delta)
			else:
				data_monster.process_attack()	


func _move_to_attack_target(delta: float):
	if data_monster.is_dead:
		return
	var move_direction = attack_target.global_position - global_position
	move_direction = move_direction.normalized()
	# 速度
	var speed = data_monster.attribute.get_final_details().move_speed * SingletonGame.speed
	position += move_direction * speed * delta


func set_attack_target(target: Control):
	attack_target = target


func select():
	if is_selected:
		return
		
	var style_box =  load("res://theme/monster_selected.tres")
	#StyleBoxFlat
	$Back.add_theme_stylebox_override("panel",style_box)
	is_selected = true


func unselect():
	if not is_selected:
		return

	$Back.remove_theme_stylebox_override("panel")
	is_selected = false


func _on_get_hurted(_data_role: DataRole,data_damage: DataDamage):
	_update_hp()

	# 添加受伤晃动效果
	if data_damage.value > 0:
		_shake_effect(data_damage.direction)
		
	_add_damage(data_damage)


func _on_effect_added(_data_effect: DataEffect):
	if data_monster and data_monster.has_effect("effect_000023"):
		# 撕裂
		var effect = data_monster.get_effect("effect_000023")
		$DeepDamageLabel.show()
		$DeepDamageLabel.text = "裂" + str(int(effect.value))


func _update_hp():
	$Back/HpBar/ColorBar.set_value(data_monster.attribute.final_details.max_hp,data_monster.hp)
	if $Back/HpBar.has_node("HP"):
		$Back/HpBar/HP.text = str(data_monster.hp) + "/" + str(data_monster.attribute.final_details.max_hp)


func _add_damage(damage: DataDamage):
	var damage_scene = SingletonGameScenePre.DamageTextScene.instantiate()
	damage_scene.set_damage(damage)
	if damage.type == DataDamage.TYPE.POISON:
		$PoisonDamageGroup.add(damage_scene)
	else:
		$DamageGroup.add(damage_scene)


func _on_panel_my_released(_ui: Control) -> void:
	pressed.emit()
	# 测试代码
	#_shake_effect()
	#var skill = DataBaseSkill.new("测试技能","attack")
	#skill.name = "测试技能"
	#add_skill_execute_effect(skill,Vector2.RIGHT)

	
func add_skill_execute_effect(skill: DataBaseSkill,direction: Vector2):
	# 实例化技能名称场景
	var skill_name_scene = SingletonGameScenePre.SkillNameScene.instantiate()
	skill_name_scene.set_skill(skill)
	# 技能名称的跳出方向是目标的方向
	skill_name_scene.direction = -direction
	$SkillNameGroup.add_child(skill_name_scene)


# 新版受伤效果，符合物理击退效果
var current_shake_tween: Tween = null

func _shake_effect(direction: Vector2 = Vector2.RIGHT):
	# BOSS无击退效果
	if data_monster.type == "boss":
		return
	# 如果当前有动画，则跳过
	if current_shake_tween:
		return
	
	# 创建新的Tween动画
	current_shake_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 动画作用对象
	var shake_obj = $Back
	# 参数配置
	var push_distance = 10.0    # 击退距离
	var shake_intensity = 3.0   # 晃动强度
	var push_duration = 0.1    # 击退时间
	var shake_duration = 0.1    # 晃动时间
	var return_duration = 0.2  # 回弹时间
	
	# 标准化方向向量
	direction = direction.normalized()
	
	# 初始位置
	var original_pos = shake_obj.position
	
	# 1. 快速击退阶段
	current_shake_tween.tween_property(shake_obj, "position", 
		original_pos + direction * push_distance, 
		push_duration)
	
	# 2. 击退后4次左右晃动效果
	var shake_pos = original_pos + direction * push_distance
	var shake_duration_part = shake_duration / 4
	
	# 第一次向左晃动
	current_shake_tween.tween_property(shake_obj, "position:x", 
		shake_pos.x - shake_intensity, 
		shake_duration_part)
	# 回到中心
	current_shake_tween.tween_property(shake_obj, "position:x", 
		shake_pos.x, 
		shake_duration_part)
	
	#保持Y轴位置不变
	current_shake_tween.parallel().tween_property(shake_obj, "position:y", 
		shake_pos.y, 
		shake_duration)
	
	# 3. 延迟后回弹
	current_shake_tween.tween_property(shake_obj, "position", 
		original_pos, 
		return_duration).set_delay(0.2)

	current_shake_tween.finished.connect(_on_shake_finished)


func _on_shake_finished():
	current_shake_tween = null
