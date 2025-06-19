extends Node2D

## 爆炎射线 攻击区域

# 技能信息
var skill: DataBaseSkill

# 怪物检测信号
signal monster_detected(monster: Monster,skill: DataBaseSkill)


# 爆炎射线特效
func _ready():
	$GPUParticles2D.emitting = true


func start(
	_skill: DataBaseSkill,
	_position: Vector2, 
	_direction: Vector2, 
	scale_x: float = 1.0) -> void:
	
	skill = _skill
	var degree = rad_to_deg(_direction.angle())
	position = _position
	rotation_degrees = degree + 90
	
	# 设置场景缩放
	scale.x = scale_x
	scale.y = min(2,scale_x)
	
	# 根据缩放比例调整粒子数量
	var base_amount = $GPUParticles2D.amount
	$GPUParticles2D.amount = int(base_amount * scale_x)
	
	# 自动销毁
	$Timer.start()



func _on_area_2d_area_entered(_area: Area2D) -> void:
	var parent = _area.get_parent()
	if parent is Monster:
		monster_detected.emit(parent,skill)


func _on_timer_timeout() -> void:
	queue_free()
