extends Node2D

## 扇形攻击特效
## 以当前位置为圆心，向上方画一个30°的扇形，扇形的半径从0-100逐渐增大，动画持续5秒

# 动画总时长（秒）
const ANIMATION_DURATION: float = 1.5

# 扇形最大半径（像素）
const MAX_RADIUS: float = 400.0

# 扇形角度（度）
const SECTOR_ANGLE: float = 30.0

# 扇形方向
var direction: Vector2 = Vector2.UP

# 扇形边缘点数量（用于碰撞多边形）
const EDGE_POINTS: int = 10

# 动画已用时间
var elapsed_time: float = 0.0

# 动画是否激活
var animation_active: bool = true

# 当前半径
var current_radius: float = 0.0

# 碰撞区域节点
var area: Area2D

# 碰撞多边形节点
var collision_polygon: CollisionPolygon2D

# 动画完成信号
signal animation_finished


func _ready() -> void:
	pass
	## 初始化动画
	#elapsed_time = 0.0
	#animation_active = true
	#current_radius = 0.0
	
	## 创建碰撞区域
	#_setup_collision_area()


func _setup_collision_area() -> void:
	# 创建Area2D节点
	area = Area2D.new()
	add_child(area)
	# 碰撞检测mask
	area.collision_mask = 1
	area.collision_layer = 1
	area.monitoring = true
	area.monitorable = true
	
	# 创建CollisionPolygon2D节点
	collision_polygon = CollisionPolygon2D.new()
	area.add_child(collision_polygon)
	
	# 连接信号
	area.area_entered.connect(_on_area_entered)
	
	# 初始化碰撞形状
	_update_collision_shape()


func _process(delta: float) -> void:
	if not animation_active:
		return
		
	# 更新动画时间
	elapsed_time += delta
	
	if elapsed_time >= ANIMATION_DURATION:
		# 动画结束
		animation_active = false
		animation_finished.emit()
		queue_free()
		return
	
	# 计算当前半径（线性增长）
	current_radius = (elapsed_time / ANIMATION_DURATION) * MAX_RADIUS
	$Area2D.position = direction * current_radius
	$Area2D.scale = Vector2.ONE * (elapsed_time / ANIMATION_DURATION)
	# 更新碰撞形状
	#_update_collision_shape()
	
	# 触发重绘
	queue_redraw()


func _draw() -> void:
	if not animation_active:
		return
	
	# 计算扇形起始和结束角度（弧度）
	var half_angle := deg_to_rad(SECTOR_ANGLE) / 2.0
	var direction_rad := direction.angle()
	var start_angle := direction_rad - half_angle
	var end_angle := direction_rad + half_angle
	
	#print("current_radius:",current_radius)
	# 绘制填充扇形
	draw_arc(Vector2.ZERO, current_radius, start_angle, end_angle, EDGE_POINTS, Color(0x34, 0xb4, 0xff, 0xaa), 2.0, true)
	
	# 绘制扇形边缘
	var inner_radius = max(current_radius - 5.0, 0.0)
	draw_arc(Vector2.ZERO, inner_radius, start_angle, end_angle, EDGE_POINTS, Color(0x34, 0xb4, 0xff, 0xff), 2.0, true)
	
	# 绘制半径线
	#draw_line(Vector2.ZERO, Vector2(cos(start_angle), sin(start_angle)) * current_radius, Color(0x34, 0xb4, 0xff, 0xff), 2.0)
	#draw_line(Vector2.ZERO, Vector2(cos(end_angle), sin(end_angle)) * current_radius, Color(0x34, 0xb4, 0xff, 0xff), 2.0)


func _update_collision_shape() -> void:
	# 计算扇形起始和结束角度（弧度）
	var half_angle := deg_to_rad(SECTOR_ANGLE) / 2.0
	var direction_rad := direction.angle()
	var start_angle := direction_rad - half_angle
	var end_angle := direction_rad + half_angle
	
	# 创建多边形点数组
	# 使用显式类型声明避免类型推断警告
	var points: PackedVector2Array
	points = PackedVector2Array()
	
	# 添加中心点
	points.append(Vector2.ZERO)
	
	# 添加扇形边缘点
	for i in range(EDGE_POINTS + 1):
		var angle := start_angle + (end_angle - start_angle) * (i / float(EDGE_POINTS))
		var point := Vector2(cos(angle), sin(angle)) * current_radius
		points.append(point)
	
	# 更新碰撞多边形
	collision_polygon.polygon = points


func _on_area_entered(_area: Area2D) -> void:
	print("area_entered:",_area.name)
	var parent = _area.get_parent()
	if parent is Monster:
		print("area_entered:",parent.name)
		var damage = DataDamage.new(
			DataDamage.TYPE.PHYSICAL, 
			DataDamage.SOURCE_TYPE.PLAYER, 10)
		parent.data_monster.get_hurt(damage)
	#area_detected.emit(area)

func start(_position: Vector2, _direction: Vector2) -> void:
	var degree = rad_to_deg(_direction.angle())
	print("_position:",_position," ",degree)
	position = _position
	direction = _direction
	animation_active = true
	elapsed_time = 0.0
	current_radius = 0.0
	#if degree > 0:
	$Area2D.rotation_degrees = degree + 90
	#else:
	#	$Area2D.rotation = degree + 90
	print("_position: Area2D",$Area2D.rotation)

	#_setup_collision_area()


func stop() -> void:
	animation_active = false
	animation_finished.emit()
	queue_free()
