extends Control
class_name BaseDropThing

## 掉落物的场景基类

# 初始掉落动画时长
const DROP_ANIMATION_DURATION = 0.6
# 剩余动画时长
var drop_animation_duration = DROP_ANIMATION_DURATION

var start_position = Vector2.ZERO

var x_offset = 0

# 拾取动画总时长
var pick_animation_duration = 0
# 拾取动画剩余时长
var pick_animation_rest_time = 0
# 拾取动画的目标位置
var pick_target_position = Vector2.ZERO



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_position = position
	
	# pick_target_position = Vector2(500,500)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 更新掉落动画
	if drop_animation_duration > 0:
		drop_animation_duration -= delta
		# 动画轨迹符合sin函数
		var ani_process = drop_animation_duration/DROP_ANIMATION_DURATION
		position.y = start_position.y -  50 * sin(ani_process * PI)
		position.x = start_position.x + (1-ani_process) * x_offset
	else:
		# 动画结束，再判断是否有拾取动画目标
		if pick_target_position != Vector2.ZERO:
			if pick_animation_duration == 0:
				start_position = position
				# 计算拾取动画时长
				pick_animation_duration = start_position.distance_to(pick_target_position) / 300
				pick_animation_rest_time = pick_animation_duration

			# 拾取动画
			if pick_animation_rest_time > 0:
				pick_animation_rest_time -= delta
				# 位置插值成减速运动
				var weight = 1 - pick_animation_rest_time / pick_animation_duration
				position = start_position.lerp(pick_target_position, sin(weight * PI/2))
				# 透明度变化
				modulate.a = 1 - weight
			else:
				# 拾取动画结束
				queue_free()


func set_pick_target(target_pos: Vector2):
	pick_target_position = target_pos
