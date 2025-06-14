extends Node2D

# 目标位置
var target_position: Vector2

# 流星陨落速度
var velocity: Vector2 = Vector2(100,100)

signal finished


func _ready():
	play_effect(Vector2(300,300))


func _process(delta: float) -> void:
	if target_position:
		position += velocity * delta

		if position.x > target_position.x and position.y > target_position.y:
			finished.emit()
			queue_free()


func play_effect(_position: Vector2):
	target_position = _position
	# 初始位置
	position = _position + Vector2(-300,-300)
	
