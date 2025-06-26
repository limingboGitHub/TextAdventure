extends Control

# 所有玩家的名字
var names: Array
var spawn_timer: Timer
var spawn_count_per_wave = 2  # 每波生成1个玩家名称
var spawn_interval = 0.8  # 每0.3秒生成一波
var spawn_area_x_min = 0
var spawn_area_x_max = 450
var spawn_area_y = 0
var min_distance_between_names = 200  # 同一波名称之间的最小距离

# 循环选择玩家名称的索引
var current_name_index: int = 0


func _ready():
	# 创建定时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = false
	add_child(spawn_timer)

	# 测试代码
	#show_names(["测试玩家1", "测试玩家2", "测试玩家3", "测试玩家4", "测试玩家5", "测试玩家6", "测试玩家7", "测试玩家8", "测试玩家9", "测试玩家10"])
	# 清理现有的玩家名称效果
	clear_existing_effects()


func _process(delta):
	pass

# 展示所有玩家名称的布局
func show_names(_names: Array):
	names = _names


func start_ani():
	if spawn_timer.is_stopped():
		spawn_timer.start()


# 清理现有的玩家名称效果
func clear_existing_effects():
	# 停止定时器
	spawn_timer.stop()
	# 移除所有现有的玩家名称效果组件
	for child in get_children():
		if child.has_method("setup_name"):  # 检查是否是玩家名称效果组件
			child.queue_free()

# 定时器超时回调
func _on_spawn_timer_timeout():
	if names.size() == 0:
		spawn_timer.stop()
		return
	
	# 生成一波玩家名称
	for i in range(spawn_count_per_wave):
		if names.size() == 0:
			break
		
		# 顺次循环选择玩家名称
		var player_name = names[current_name_index]
		current_name_index = (current_name_index + 1) % names.size()
		
		# 创建玩家名称效果组件
		var player_name_scene = SingletonGameScenePre.PlayerNameScene.instantiate()
		
		# TODO 生成不遮挡的X坐标
		var random_x = 50
		if i == 1:
			random_x = 350
		
		player_name_scene.position = Vector2(random_x, spawn_area_y)
		
		# 添加到场景中
		add_child(player_name_scene)
		
		# 启动动画
		player_name_scene.setup_name(player_name)
		player_name_scene.start_falling_animation()

# 在指定等分区域内生成X坐标
func generate_x_in_segment(segment_index: int) -> float:
	# 计算每个等分区域的宽度
	var total_width = spawn_area_x_max - spawn_area_x_min
	var segment_width = total_width / spawn_count_per_wave
	
	# 计算当前等分区域的起始和结束位置
	var segment_start = spawn_area_x_min + segment_index * segment_width
	var segment_end = segment_start + segment_width
	
	# 在当前等分区域内随机生成X坐标
	return randf_range(segment_start, segment_end)
