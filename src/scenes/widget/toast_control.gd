extends Control

## 轻量级提示框容器类

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_toast(msg: String):
	# 将其他toast节点全部上移
	for i in get_children():
		i.position.y -= 35
	# 增加toast场景
	var toast = SingletonGameScenePre.ToastScene.instantiate()
	toast.text = msg
	add_child(toast)
