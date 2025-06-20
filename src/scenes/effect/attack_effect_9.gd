extends Node2D

# 巨人普通攻击区域

# 读条状态 0开始 1结束
var scale_state: int = 0
# 读条动画总时间
var scale_duration: float = 2.0
# 动画已用时间
var elapsed_time: float = 0.0
# 颜色
var skill_color: Color = Color.WHITE


func _ready() -> void:
	start(Vector2(200,200),null,Vector2.UP)

func start(_position: Vector2,_skill: DataBaseSkill,_direction: Vector2) -> void:
	# 朝向
	var degree = rad_to_deg(_direction.angle())
	position = _position
	rotation_degrees = degree + 90
	# 整体位置
	position = _position
	# 隐藏显示
	$Zone/Panel.hide()


func _process(delta: float) -> void:
	if scale_state == 0:
		elapsed_time += delta
		if elapsed_time >= scale_duration:
			scale_state = 1
			elapsed_time = scale_duration
			# 显示
			show_attack_zone()

		queue_redraw()


func _draw():
	if scale_state == 0:
		var scale_factor = elapsed_time / scale_duration
		# 绘制圆弧
		draw_arc(Vector2.ZERO, 10, deg_to_rad(0), deg_to_rad(360 * scale_factor), 32, skill_color, 2)


func show_attack_zone():
	# 区域展示
	$Zone/Panel.show()
	# 持续后消失
	await get_tree().create_timer(0.7).timeout
	start_fade_out_animation()


func start_fade_out_animation() -> void:
	# 开始消失动画：透明度从1变为0，持续0.3秒
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	# 动画完成后释放场景
	tween.tween_callback(queue_free)
