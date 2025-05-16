extends Control

## 展示统计信息
##
## 1. 伤害/秒 
## 2. 血耗/秒
## 3. 蓝耗/秒

## 统计方法：设置一个定时器，每5秒统计一次，统计5秒内玩家造成的总伤害、血耗、蓝耗，然后计算每秒的平均值

# 统计周期（秒）
const STATS_INTERVAL: float = 5.0

# 统计数据
var _total_damage: int = 0
var _total_hp_cost: int = 0
var _total_mp_cost: int = 0

# 计算结果
var dps: float = 0  # 伤害/秒
var hps: float = 0  # 血耗/秒
var mps: float = 0  # 蓝耗/秒

# UI引用
@onready var _dps_label: Label = $VBoxContainer/Damage
@onready var _hps_label: Label = $VBoxContainer/HP
@onready var _mps_label: Label = $VBoxContainer/MP
@onready var _stats_timer: Timer = $StatsTimer
@onready var _total_damage_max_record_label: Label = $VBoxContainer/DamageMaxRecord
@onready var _all_damage_label: Label = $VBoxContainer/AllDamage


func init():
	# 初始化定时器
	_stats_timer = Timer.new()
	_stats_timer.wait_time = STATS_INTERVAL
	_stats_timer.one_shot = false
	_stats_timer.connect("timeout", Callable(self, "_on_stats_timer_timeout"))
	add_child(_stats_timer)
	_stats_timer.start()
	
	# 初始化UI显示
	_update_ui()


## 定时器超时，计算统计数据
func _on_stats_timer_timeout():
	# 计算每秒平均值
	dps = _total_damage / STATS_INTERVAL
	hps = _total_hp_cost / STATS_INTERVAL
	mps = _total_mp_cost / STATS_INTERVAL
	
	# 更新最高DPS记录
	if dps > SingletonGame.dps_max_record:
		SingletonGame.dps_max_record = int(dps)
	
	# 更新UI
	_update_ui()
	
	# 重置统计数据
	_reset_stats()


## 更新UI显示
func _update_ui():
	if _all_damage_label:
		_all_damage_label.text = "总     伤: " + str(SingletonGame.all_damage)
	if _dps_label:
		_dps_label.text = "伤害/秒: %d" % int(dps)
	if _total_damage_max_record_label:
		_total_damage_max_record_label.text = "伤害/秒(最高记录): %d" % SingletonGame.dps_max_record
	if _hps_label:
		_hps_label.text = "血耗/秒: %d" % int(hps)
	if _mps_label:
		_mps_label.text = "蓝耗/秒: %d" % int(mps)


## 重置统计数据
func _reset_stats():
	_total_damage = 0
	_total_hp_cost = 0
	_total_mp_cost = 0


## 玩家造成了伤害
func player_damage_caused(damage: DataDamage):
	_total_damage += damage.value
	SingletonGame.all_damage += damage.value
	$VBoxContainer/AllDamage.text = "总     伤: " + str(SingletonGame.all_damage)


## 玩家HP消耗了
func player_hp_reduce(hp: int):
	_total_hp_cost += hp


## 玩家MP消耗了
func player_mp_reduce(mp: int):
	_total_mp_cost += mp


func _on_button_pressed() -> void:
	## 测试代码，添加伤害
	var damage = DataDamage.new(DataDamage.TYPE.PHYSICAL, DataDamage.SOURCE_TYPE.PLAYER, 100)
	player_damage_caused(damage)
