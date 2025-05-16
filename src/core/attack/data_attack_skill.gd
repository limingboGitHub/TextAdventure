class_name DataAttackSkill extends DataBaseSkill

## 攻击类技能

## 伤害加成类型 0 攻击力 1 魔法力 2 攻击力+魔法力
var damage_source_type: int = 0
## 最终造成的伤害类型 0 物理 1 魔法
var damage_type: int = 0
## 伤害间隔 单位：秒
var damage_interval: float = 0

## 伤害数值类型 
var damage_value_type = Constants.VALUE_TYPE_PERCENT
# 伤害等级表 size长度对应max_level
var damage_level: Array
# 蓝耗等级表
var mp_cost_level: Array

# 作用坐标 Vector2 可空
var effect_position = null

# 技能弹道移动速度(像素/秒)
var skill_move_speed: int = 100

# 技能伤害判定段数
var damage_array_index = 0


func get_mp_cost():
	if mp_cost_level:
		return mp_cost_level[level - 1]
	else:
		return super.get_mp_cost()


func get_damage_value():
	return damage_level[level - 1][damage_array_index]


func get_damage_array_size():
	return damage_level[level - 1].size()


func is_damage_array_index_end():
	return damage_array_index >= get_damage_array_size()
