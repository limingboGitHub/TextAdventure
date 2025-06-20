extends Node2D

## 烈火燎原 攻击区域

# 技能信息
var buff: DataBuff

# 怪物检测信号
signal monster_detected(monster: Monster,skill: DataBaseSkill)


func start(
	_buff: DataBuff,
	_position: Vector2, 
	_scale: float = 1.0,
	_time: float = 5) -> void:
	
	buff = _buff
	position = _position

	scale.x = _scale
	scale.y = _scale

	# 根据缩放比例调整粒子数量
	var base_amount = $Panel/GPUParticles2D.amount
	$Panel/GPUParticles2D.amount = int(base_amount * _scale)
	
	# 自动销毁
	$Timer.wait_time = _time
	$Timer.start()


func _on_timer_timeout() -> void:
	queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	var monster = area.get_parent()
	print("烈焰燎原 攻击区域 进入:",monster.data_monster.monster_unique_id)
	print("烈焰燎原 效果：",buff)
	if monster!= null and monster is Monster:
		monster.data_monster.add_buff(buff.copy())


func _on_area_2d_area_exited(area: Area2D) -> void:
	var monster = area.get_parent()
	print("烈焰燎原 攻击区域 离开:",monster.data_monster.monster_unique_id)
	if monster!= null and monster is Monster:
		monster.data_monster.remove_buff(buff.id)
