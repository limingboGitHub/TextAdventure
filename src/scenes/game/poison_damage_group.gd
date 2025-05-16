extends Control

## 伤害值文字显示的容器类
##
## 添加伤害文字场景时，可以将正在显示的伤害文字向上挤

const GRAVITY = 500.0  # 重力加速度 (像素/秒^2)
const INITIAL_UP_SPEED_MIN = -50.0 # 初始最小向上速度 (像素/秒)
const INITIAL_UP_SPEED_MAX = -100.0 # 初始最大向上速度 (像素/秒)
const INITIAL_HORIZONTAL_SPEED_RANGE = 20.0 # 初始水平速度范围 (像素/秒)

# 文字的移动速度 (这个变量不再直接使用，但保留以防其他地方引用)
var move_speed = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 遍历所有的伤害文字，更新动画
	for damage_text in get_children():
		# 获取当前速度，如果不存在则初始化
		var velocity_y = damage_text.get_meta("velocity_y", INITIAL_UP_SPEED_MAX)
		var velocity_x = damage_text.get_meta("velocity_x", 0.0)

		# 更新垂直速度
		velocity_y += GRAVITY * delta
		damage_text.set_meta("velocity_y", velocity_y)

		# 更新位置
		damage_text.position.y += velocity_y * delta
		damage_text.position.x += velocity_x * delta
		


func add(damage_text: Control):
	# 为新的伤害文字设置随机的初始速度
	var initial_vy = randf_range(INITIAL_UP_SPEED_MIN, INITIAL_UP_SPEED_MAX)
	var initial_vx = randf_range(-INITIAL_HORIZONTAL_SPEED_RANGE, INITIAL_HORIZONTAL_SPEED_RANGE)
	
	damage_text.set_meta("velocity_y", initial_vy)
	damage_text.set_meta("velocity_x", initial_vx)
	
	add_child(damage_text)
