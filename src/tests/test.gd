extends Node2D

## 测试场景

var res_manager = ResManager.new()
var test_res_manager = TestResManager.new()
var test_refresh_pos = TestRefreshPos.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test_refresh_pos.test()

	# 初始化ResManager
	# res_manager.load_res_finished.connect(_on_load_res_finish)
	# res_manager.load()

func _on_load_res_finish():
	# 开始测试加载怪物
	test_res_manager.test(res_manager)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
