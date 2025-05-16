class_name DataDamage

# 伤害类型
enum TYPE {
	PHYSICAL,
	MAGICAL,
	POISON,
	HEAL,
}

# 伤害来源类型
enum SOURCE_TYPE {
	MONSTER,
	PLAYER,
	POISON
}

# 伤害类型
var type : int = TYPE.PHYSICAL
# 伤害来源类型
var source_type : int = SOURCE_TYPE.MONSTER
# 伤害值 0表示未命中
var value : int = 0
# 当前伤害值处在波动范围内的比率 0-1，0表示最小攻击值，1表示最大攻击值，体现伤害的波动
var value_show_rate : float = 1.0
# 方向向量（归一化）
var direction : Vector2 = Vector2.RIGHT

func _init(type: int,source_type: int, value: int) -> void:
	self.type = type
	self.source_type = source_type
	self.value = value
