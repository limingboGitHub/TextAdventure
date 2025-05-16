extends Label

## 伤害文字场景
##
## 根据具体的damage信息，显示对应的伤害文字

# 伤害文字的动画时间
var animation_time = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if animation_time > 0:
		animation_time -= delta
		if animation_time <= 0:
			queue_free()


func set_damage(data_damage: DataDamage):
	if data_damage.value == 0:
		text = "MISS"
	else:
		text = str(data_damage.value)
	# 治疗的颜色
	if data_damage.type == DataDamage.TYPE.HEAL:
		add_theme_color_override("font_color", Color.GREEN)
	elif data_damage.source_type == DataDamage.SOURCE_TYPE.MONSTER:
		add_theme_color_override("font_color", Color.PURPLE)
	elif data_damage.type == DataDamage.TYPE.POISON:
		add_theme_color_override("font_color", Color.FOREST_GREEN)
	# 调整字体大小 根据比率
	var font_size = 14 + (data_damage.value_show_rate * 16)
	add_theme_font_size_override("font_size", font_size)
