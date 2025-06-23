extends Node2D

## 战争践踏 攻击区域

# 技能信息
var skill: DataBaseSkill

# 怪物检测信号
signal monster_detected(monster: Monster,skill: DataBaseSkill)


func start(
	_skill: DataBaseSkill,
	_position: Vector2, 
	_scale: float = 1.0) -> void:
	
	skill = _skill

	position = _position
	
	# 设置场景缩放
	scale.x = _scale
	scale.y = _scale
	
	# 根据缩放比例调整粒子数量
	var base_amount = $GPUParticles2D.amount
	$GPUParticles2D.amount = int(base_amount * _scale)
	$GPUParticles2D.emitting = true
	
	# 自动销毁
	$Timer.start()



func _on_area_2d_area_entered(_area: Area2D) -> void:
	var parent = _area.get_parent()
	if parent is Monster:
		monster_detected.emit(parent,skill)


func _on_timer_timeout() -> void:
	queue_free()
