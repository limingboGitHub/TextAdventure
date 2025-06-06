class_name DataChargeComponent extends RefCounted

signal charge_started
signal charge_completed(complete_charge_time: float)  # 0表示失败，大于0表示成功

var owner_role  # 引用拥有该组件的角色
var is_charging: bool = false
var charge_time: float = 0.0
var charge_duration: float = 0.0
var charge_last_mp_cost_time: float = 0.0
var mp_cost_per_interval: int = 5  # 每间隔消耗的魔法值
var mp_cost_interval: float = 0.1  # 消耗魔法值的时间间隔

func _init(_owner):
    owner_role = _owner

# 开始蓄力
func start_charge(time: float) -> bool:
    if is_charging:
        return false  # 已经在蓄力中，不重复开始
    
    is_charging = true
    charge_time = 0.0
    charge_duration = time
    charge_last_mp_cost_time = 0.0
    
    # 发出蓄力开始信号
    charge_started.emit()
    print("开始蓄力，持续时间：", time, "秒")
    return true

# 完成蓄力
func complete_charge(complete_charge_time: float):
    if not is_charging:
        return
    
    is_charging = false
    charge_time = 0.0
    charge_duration = 0.0
    
    # 发出蓄力完成信号
    charge_completed.emit(complete_charge_time)
    print("蓄力完成")

# 取消蓄力
func cancel_charge():
    if not is_charging:
        return
    
    is_charging = false
    charge_time = 0.0
    charge_duration = 0.0
    
    # 发出蓄力完成信号，参数为0表示被取消
    charge_completed.emit(0)
    print("蓄力被取消")

# 处理蓄力逻辑
func process(delta: float):
    if is_charging:
        charge_time += delta * SingletonGame.speed
        if charge_time >= charge_duration:
            complete_charge(charge_time)
        else:
            # 计算蓄力蓝耗，每间隔消耗魔法值
            _process_mp_cost(delta)

# 处理魔法值消耗
func _process_mp_cost(delta: float):
    charge_last_mp_cost_time += delta
    if charge_last_mp_cost_time >= mp_cost_interval:
        charge_last_mp_cost_time = 0.0
        var mp_cost = mp_cost_per_interval * SingletonGame.speed
        if owner_role.mp < mp_cost:
            complete_charge(charge_time)
        else:
            owner_role.recover_mp(-mp_cost)

# 获取蓄力状态
func get_charging_status() -> bool:
    return is_charging

# 获取蓄力进度 (0.0 - 1.0)
func get_charge_progress() -> float:
    if not is_charging or charge_duration <= 0:
        return 0.0
    return min(charge_time / charge_duration, 1.0)

# 重置蓄力状态
func reset():
    cancel_charge()

# 配置魔法值消耗
func set_mp_cost(cost: int, interval: float = 0.1):
    mp_cost_per_interval = cost
    mp_cost_interval = interval 