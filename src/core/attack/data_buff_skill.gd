class_name DataBuffSkill extends DataBaseSkill

## buff类技能
##
## 有持续时间的技能

# 持续时间，-1表示永久，即传统的被动技能
var time: int = -1

# 蓝耗等级表
var mp_cost_level: Array


func update_mp_cost():
    if mp_cost_level:
        mp_cost = mp_cost_level[level]


func get_mp_cost():
    if mp_cost_level:
        return mp_cost_level[level]
    else:
        return super.get_mp_cost()


func is_permanent():
    return time == -1


func create_buff() -> DataBuff:
    var data_buff = DataBuff.new()
    data_buff.id = id
    data_buff.name = name
    data_buff.buff_type = 0
    data_buff.duration = time
    data_buff.remaining_time = time
    data_buff.last_update_time = time
    return data_buff
