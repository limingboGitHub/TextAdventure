class_name DataBaseSkill

## 技能的基类
##
## 这里将普通攻击视为技能

# 技能id
var id: String
# 技能类型 attack 攻击 buff 增益 effect_buff 特殊增益 attri_buff 属性增益
var type: String
# 技能名称
var name: String
# 作用目标类型 0玩家 1敌人 2都有作用
var target_type: int
# 作用目标数量
var count: int
# 释放时和目标的距离
var distance: int = 40
# 作用范围半径
var radius: int = distance
# 中心点位置类型 0 技能释放者 1 技能目标
var center_type: int = 0
# 冷却时间(秒)
var cd: float
# 剩余冷却时间(秒)
var cd_rest: float
# 蓝耗
var mp_cost: int
# 最大等级
var max_level: int
# 等级
var level: int
# 描述
var description: String
# 武器类型要求
var weapon_type: int

# 技能是否触发释放后的特效
var is_effect_after_skill_executed: bool = true

# 技能等级变化信号
signal level_changed(data_skill: DataBaseSkill)


func _init(id: String, type: String) -> void:
	self.id = id
	self.type = type


func add_level(num: int) -> void:
	level += num
	level_changed.emit(self)


func is_max_level() -> bool:
	return level >= max_level


func get_mp_cost():
	return mp_cost


func save() -> Dictionary:
	# 技能持久化存储时，只保存技能id和等级，其他信息在通过技能背包重新创建
	return {
		"id": id,
		"level": level,
		"type": type
	}
