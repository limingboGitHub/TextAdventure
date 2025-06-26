extends PanelContainer

# 玩家名字组件
var fall_speed = 50.0  # 下降速度
var swing_amplitude = 3.0  # 左右摆动幅度
var swing_frequency = 0.5  # 摆动频率
var lifetime = 13.0  # 生存时间（秒）
var elapsed_time: float = 0.0
var start_x: float
var label: Label
var is_falling: bool = false

func _ready():
	label = $Label

func _process(delta):
	if not is_falling:
		return
	
	# 累计经过的时间
	elapsed_time += delta
	
	# 检查是否超过生存时间
	if elapsed_time >= lifetime:
		queue_free()
		return
	
	# 向下掉落
	position.y += fall_speed * delta
	
	# 左右摆动（正弦波运动）
	var swing_offset = sin(elapsed_time * swing_frequency * PI * 2) * swing_amplitude
	position.x = start_x + swing_offset
	
	# 渐隐效果（最后1秒开始渐隐）
	if elapsed_time > lifetime - 1.0:
		var fade_progress = (lifetime - elapsed_time) / 1.0
		modulate.a = fade_progress

# 设置玩家名称
func setup_name(player_name: String):
	if label:
		label.text = player_name

func start_falling_animation():
	# 重置状态
	elapsed_time = 0.0
	start_x = position.x
	modulate.a = 1.0  # 确保完全不透明
	is_falling = true
