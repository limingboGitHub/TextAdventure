extends Node2D

## 烈火燎原 攻击区域

# 技能信息
var skill: DataBaseSkill

# 怪物检测信号
signal monster_detected(monster: Monster,skill: DataBaseSkill)


func start(
	_skill: DataBaseSkill,
	_position: Vector2, 
	_scale: float = 1.0,
	_time: float = 5) -> void:
	
	skill = _skill
	position = _position
	
	# 自动销毁
	$Timer.wait_time = _time
	$Timer.start()


func _on_timer_timeout() -> void:
	queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	print("烈焰燎原 攻击区域 进入")


func _on_area_2d_area_exited(area: Area2D) -> void:
	print("烈焰燎原 攻击区域 离开")
