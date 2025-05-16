extends Control

## 伤害值文字显示的容器类
##
## 添加伤害文字场景时，可以将正在显示的伤害文字向上挤

# 文字的移动速度
var move_speed = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# 遍历所有的伤害文字，更新动画
	for damage_text in get_children():
		# 向上移动动画
		damage_text.position.y -= move_speed * delta


func add(damage_text: Control):
	# 查找已经添加的文字，将文字向上挤
	var damage_texts = get_children()
		
	for child in damage_texts:
		child.position.y -= 20
	
	# x坐标在+-10范围内随机偏移
	damage_text.position.x += randi_range(-5, 5)
	add_child(damage_text)
