extends Control

## 技能名称展示场景

var radius = 0
# 文字的动画总时间
var animation_time = 1
# 文字的动画剩余时间
var rest_animation_time = 0
# 文字的移动速度
var x_speed = 50
var y_speed = -30
# 垂直方向加速度
var acceleration = 300

var direction: Vector2 = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 设置动画时间
	rest_animation_time = animation_time
	y_speed = -50
	position.x -= size.x / 2
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 根据剩余时间更新动画
	if rest_animation_time > 0:
		rest_animation_time -= delta
		if rest_animation_time <= 0:
			# 动画结束，移除文字
			queue_free()
		else:
			# 垂直方向加速下落，水平方向匀速向右
			$Name.position.y += y_speed * delta + 0.5 * acceleration * delta * delta
			y_speed += acceleration * delta

			$Name.position.x += x_speed * direction.x * delta


func set_skill(skill: DataBaseSkill):
	$Name.text = skill.name


func _draw():
	# 如果有半径属性，绘制圆形范围
	if radius > 0:
		# 绘制蓝色空心圆，线宽2像素
		draw_arc(
			Vector2(size.x / 2, size.y / 2),  # 圆心位置
			radius,                            # 半径
			0,                                # 起始角度
			TAU,                              # 结束角度(TAU=2*PI，完整圆)
			32,                               # 分段数(圆滑度)
			Color(0, 0, 1, 0.5),              # 蓝色，80%透明度
			2.0                               # 线宽2像素
		)
