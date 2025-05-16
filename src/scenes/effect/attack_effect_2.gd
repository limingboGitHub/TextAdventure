extends Node2D

# 动画状态枚举
enum State { SCALING, MOVING ,DEAD}

# 目标场景
var target_scene: Control = null
# 技能
var skill_id: String = ""
var skill_radius: int = 0
# 技能追加次数
var skill_add_count: int = 0
# 动画已用时间
var elapsed_time: float = 0.0
# 动画是否激活 (整体控制)
var animation_active: bool = true
# 当前动画状态
var animation_state: State = State.SCALING

# 缩放阶段时长
var scale_duration: float = 2
# 移动速度 (像素/秒)
var move_speed: float = 600.0
# 到达目标的最小距离阈值
const ARRIVAL_THRESHOLD: float = 5.0
# 死亡阶段时长
var dead_duration: float = 0.5

# 动画全部完毕后信号
signal ani_all_finished
# 技能释放动画被打断信号 (例如目标死亡)
signal ani_skill_cast_interrupted
# 技能缩放（释放）动画结束信号
signal ani_skill_cast_finished(scene: Node2D)


func _ready():
	scale = Vector2.ZERO # 确保从0开始缩放
	animation_state = State.SCALING


func _process(delta):
	if not animation_active:
		return

	var actual_delta = delta * SingletonGame.speed
	elapsed_time += actual_delta

	match animation_state:
		State.SCALING:
			_process_scaling(actual_delta)
		State.MOVING:
			_process_moving(actual_delta)
		State.DEAD:
			_process_dead(actual_delta)


func _process_dead(_delta):
	if elapsed_time <= dead_duration:
		modulate.a = 1.0 - elapsed_time / dead_duration
	else:
		animation_active = false
		queue_free()


func _process_scaling(_delta):
	# 为了平衡技能释放时长和cd之间的误差，这里减去0.05秒，否则会导致技能cd已计算完毕，但动画还未结束
	if elapsed_time <= scale_duration - 0.05:
		# 阶段 1: 缩放 (0 -> SCALE_DURATION 秒)
		var scale_factor = elapsed_time / scale_duration
		if skill_id == "skill_000101":
			scale = Vector2.ONE
		else:
			scale = Vector2.ZERO.lerp(Vector2.ONE, clamp(scale_factor, 0.0, 1.0))
		
		queue_redraw()
	else:
		# 缩放完成
		scale = Vector2.ONE
		animation_state = State.MOVING
		# 重置计时器（如果移动逻辑依赖 elapsed_time 的话）
		elapsed_time = 0.0
		# 发出缩放（释放）动画结束信号
		ani_skill_cast_finished.emit(self)


func _process_moving(delta):
	if not is_instance_valid(target_scene):
		# 目标失效
		stop()
		return
	if move_speed == -1:
		global_position = target_scene.global_position
		# 进入死亡状态
		_change_state_dead()
		return

	var current_target_pos = target_scene.global_position
	var direction = (current_target_pos - global_position).normalized()
	var distance_to_target = global_position.distance_to(current_target_pos)
	var move_this_frame = move_speed * delta # 注意这里用原始delta，因为上面已经乘过speed了

	if distance_to_target <= ARRIVAL_THRESHOLD or distance_to_target <= move_this_frame:
		# 到达目标
		global_position = current_target_pos
		# 进入死亡状态
		_change_state_dead()
	else:
		# 向目标移动
		global_position += direction * move_this_frame


func _change_state_dead():
	# 动画完成
	ani_all_finished.emit()
	# 进入死亡状态
	animation_state = State.DEAD
	elapsed_time = 0.0
	queue_redraw()


# 外部调用此函数来中断动画
func stop():
	if animation_state == State.SCALING:
		_interrupt()
	else:
		animation_active = false
		queue_free()


func _interrupt():
	animation_active = false
	ani_skill_cast_interrupted.emit()
	queue_free()


# 外部调用此函数来设置移动目标
func set_target_scene(_target_scene: Control):
	if not is_instance_valid(_target_scene):
		printerr("Attack Effect 2: Invalid target scene provided.")
		# 如果提供了无效目标，中断并清理
		_interrupt()
		return

	self.target_scene = _target_scene
	# 检查信号是否已连接
	if _target_scene and _target_scene.data_monster:
		if not _target_scene.data_monster.role_dead.is_connected(_on_target_dead):
			# 使用 LATED 连接以避免在同一帧内处理信号时可能出现的问题
			_target_scene.data_monster.role_dead.connect(_on_target_dead, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


# 当目标死亡时的回调
func _on_target_dead(_data_role: DataRole):
	# 确保只在释放阶段目标死亡才算中断
	if animation_state == State.SCALING:
		_interrupt()
	elif animation_state == State.MOVING:
		animation_active = false
		queue_free()


func _draw():
	if animation_active:
		if skill_id == "skill_000100":
			draw_circle(Vector2.ZERO, 10.0 * scale.x, Color(0x34b4ffff))
			if skill_add_count > 0:
				draw_circle(Vector2.ZERO + Vector2.RIGHT * 22, 10.0 * scale.x, Color(0x34b4ffff))
		elif skill_id == "skill_000101":
			if animation_state == State.SCALING:
				var scale_factor = elapsed_time / scale_duration
				# 绘制圆弧
				draw_arc(Vector2.ZERO, 10, deg_to_rad(0), deg_to_rad(360 * scale_factor), 32, Color(0x34b4ffff), 2)
			elif animation_state == State.DEAD:
				draw_circle(Vector2.ZERO, skill_radius, Color(0x34b4ffff),false,2,false)
		elif skill_id == "skill_000103":
			draw_circle(Vector2.ZERO - Vector2.RIGHT * 10, 6 * scale.x, Color(0x34b4ffff))
			draw_circle(Vector2.ZERO + Vector2.RIGHT * 10, 6 * scale.x, Color(0x34b4ffff))
