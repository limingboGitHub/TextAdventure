class_name DataDamage

# 伤害类型
enum TYPE {
	PHYSICAL,
	MAGICAL,
	POISON,
	FIRE,
	HEAL,
	REAL
}

# 伤害来源类型
enum SOURCE_TYPE {
	MONSTER,
	PLAYER,
	POISON,
	FIRE
}


# 伤害详情类
class DamageDetail:
	# 伤害名称
	var name: String
	# 伤害数值
	var value: int
	# 伤害比例
	var rate: float = 0.0

	func _init(_name: String, _value: int, _rate: float) -> void:
		self.name = _name
		self.value = _value
		self.rate = _rate


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

# 伤害统计名称（仅用于统计展示）
var damage_info_name: String = ""

#region 伤害详情
var attack_value: int = 0
var damage_details:Array[DamageDetail]
#endregion

func _init(type: int,source_type: int, value: int) -> void:
	self.type = type
	self.source_type = source_type
	self.value = value
