extends Control

# 显示的buff数量限制
var count_limit : int = 6

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# 清理buff显示
	for child in $BuffContainer.get_children():
		child.queue_free()

	# 测试代码
	# var attribute_ability = AttributeAbility.new()
	# var attribute_details = AttributeDetails.new()
	# attribute_details.max_hp = 1000
	# var buff = DataBuff.new(
	# 	"1",
	# 	0,
	# 	attribute_details,
	# 	attribute_ability,
	# 	5000
	# )
	# add_buff(buff)

	# attribute_ability = AttributeAbility.new()
	# attribute_ability.power = 100
	# attribute_details = AttributeDetails.new()
	# buff = DataBuff.new(
	# 	"1",
	# 	0,
	# 	attribute_details,
	# 	attribute_ability,
	# 	10000
	# )
	# add_buff(buff)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_buff(buff: DataBuff):
	# 创建buff显示
	var buff_item = SingletonGameScenePre.BuffItemScene.instantiate()
	$BuffContainer.add_child(buff_item)
	buff_item.set_buff(buff)
