extends Node

# 游戏单例 存储需要跨场景的数据

# 开始游戏的角色id
var start_role_id = ""

# 挂机
var is_auto = false
# 统计伤害
var all_damage: int = 0
# 最高秒伤
var dps_max_record: int = 0
# 怪物击杀时间记录 key:怪物id value:击杀时间(毫秒)
var boss_kill_time: Dictionary = {}

#region 需要保存的配置
# 玩家hp值警告线
var hp_warning_line = 30
# 玩家mp值警告线
var mp_warning_line = 30
# 挂机技能(默认普攻)
var auto_skill_id: String = "skill_000000"
#endregion

#region 通用配置
var exp_multiplier = 1.0
var gold_multiplier = 1.0
var drop_rate_multiplier = 1.0
# 游戏速度
var speed = 1
#endregion


func save() -> Dictionary:
	var dic = {
		"hp_warning_line": hp_warning_line,
		"mp_warning_line": mp_warning_line,
		"auto_skill_id": auto_skill_id,
		"all_damage": all_damage,
		"dps_max_record": dps_max_record,
		"boss_kill_time": boss_kill_time
	}
	return dic


func load(dic: Dictionary) -> void:
	hp_warning_line = dic.get("hp_warning_line", 30)
	mp_warning_line = dic.get("mp_warning_line", 30)
	auto_skill_id = dic["auto_skill_id"]
	if dic.has("all_damage"):
		all_damage = dic["all_damage"]
	if dic.has("dps_max_record"):
		dps_max_record = dic["dps_max_record"]
	if dic.has("boss_kill_time"):
		boss_kill_time = dic["boss_kill_time"]
