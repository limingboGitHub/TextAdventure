extends Control

## 网格控件
##
## 用于显示背包、商店等列表的网格控件

var grid_count: int = 0

var grid_width: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if grid_count == 0:
		grid_count = 3

	# 根据网格数量计算单元格大小
	grid_width = size.x / grid_count


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_item(item: Control):
	pass
