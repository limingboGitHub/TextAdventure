extends Node2D

# 巨人普通攻击区域

# 读条状态 0开始 1结束
var scale_state: int = 0
# 读条动画总时间
var scale_duration: float = 1.0
# 动画已用时间
var elapsed_time: float = 0.0
# 颜色
var skill_color: Color = Color.WHITE

var skill: DataBaseSkill

signal monster_detected(monster: Monster,skill: DataBaseSkill)

#func _ready() -> void:
#	start(Vector2(200,200),null,Vector2.UP)

# 刺击特效
func start_stick(_position: Vector2,_skill: DataBaseSkill,_direction: Vector2) -> void:
	print("巨人姿态：",_direction)
	skill = _skill
	# 朝向
	var degree = rad_to_deg(_direction.angle())
	position = _position
	rotation_degrees = degree + 90
	# 整体位置
	position = _position
	# 开始攻击
	show_stick_attack_zone()


# 扫击特效
func start_swipe(_position: Vector2,_skill: DataBaseSkill,_direction: Vector2) -> void:
	skill = _skill
	# 朝向
	var degree = rad_to_deg(_direction.angle())
	position = _position
	rotation_degrees = degree + 90
	# 整体位置
	position = _position
	# 开始攻击
	show_swipe_attack_zone()

#func _process(delta: float) -> void:
#	if scale_state == 0:
#		elapsed_time += delta
#		if elapsed_time >= scale_duration:
#			scale_state = 1
#			elapsed_time = scale_duration
#			# 显示
#			show_stick_attack_zone()

#		queue_redraw()


func show_stick_attack_zone():
	var panel = $Zone/Panel
	# 设置初始状态
	panel.modulate.a = 0.0
	panel.position.y = 30
	# 区域展示
	panel.show()

	# 创建并行动画
	var tween = create_tween().set_parallel(true)
	# 0.3秒内透明度从0到1
	tween.tween_property(panel, "modulate:a", 1.0, 1)
	# 0.3秒内y坐标从-30到0
	tween.tween_property(panel, "position:y", 0, 1)
	
	# 等待动画完成
	await tween.finished
	
	# 持续后消失
	await get_tree().create_timer(0.5).timeout
	start_fade_out_animation()


# 横扫特效
func show_swipe_attack_zone():
	var panel = $Zone/Panel
	var zone = $Zone
	
	# 设置初始状态
	panel.modulate.a = 0.0
	zone.rotation_degrees = -90
	# 区域展示
	panel.show()

	# 创建并行动画
	var tween = create_tween()
	# 0.3秒内透明度从0到1
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	
	var rotate_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	rotate_tween.set_ease(Tween.EASE_IN)
	rotate_tween.tween_property(zone, "rotation_degrees", 270, 1)
	rotate_tween.set_ease(Tween.EASE_OUT)
	rotate_tween.tween_property(zone, "rotation_degrees", 630, 1)
	
	await rotate_tween.finished
	
	start_fade_out_animation()



func start_fade_out_animation() -> void:
	# 开始消失动画：透明度从1变为0，持续0.3秒
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	# 动画完成后释放场景
	tween.tween_callback(queue_free)


func _on_area_2d_area_entered(_area: Area2D) -> void:
	var parent = _area.get_parent()
	if parent is Monster:
		monster_detected.emit(parent,skill)
