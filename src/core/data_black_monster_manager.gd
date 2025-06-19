class_name DataBlackMonsterManager

## 黑化召唤管理器
## 
## 玩家携带的黑化召唤物可以贯通地图，存在召唤上限


# 等级数量限制
var level_count_limit: int = 1
# 特效数量限制
var effect_count_limit: int = 0

# 召唤物容器 怪物唯一id: 怪物数据
var black_monster_dic: Dictionary[String, DataMonster] = {}

# 玩家
var data_player: DataPlayer

# 召唤物数量变化信号
signal count_changed(count: int)


# 初始化数据
func init_data(_data_player: DataPlayer):
	self.data_player = _data_player
	# 初始化 “掌控之力”数量加成
	if data_player.has_effect("effect_000048"):
		var effect = data_player.get_effect("effect_000048")
		effect_count_limit = effect.value


# 添加召唤物
func add(data_monster: DataMonster)-> bool:
	if black_monster_dic.size() >= level_count_limit + effect_count_limit:
		return false
	if data_player == null:
		return false
	
	# 技能数值强度
	if not data_player.has_effect("effect_000045"):
		return false
	var effect = data_player.get_effect("effect_000045")
	# 获取玩家魔法力，进行怪物数值增幅
	var magic_value = effect.value * data_player.get_final_details().magic

	# 黑化召唤物持续时长
	var black_monster_rest_time = 20.0
	if data_player.has_effect("effect_000047"):
		var time_effect = data_player.get_effect("effect_000047")
		black_monster_rest_time += time_effect.value
	
	# 黑化怪物
	data_monster.black_monster(
		magic_value,
		data_player.get_final_details().accuracy,
		black_monster_rest_time
		)
	black_monster_dic[data_monster.monster_unique_id] = data_monster
	# 监听黑化怪物死亡事件
	data_monster.role_dead.connect(_on_monster_dead)
	# 触发数量变化信号
	count_changed.emit(black_monster_dic.size())
	return true


func _on_monster_dead(data_monster: DataMonster):
	print("黑化--怪物死亡:",data_monster.monster_unique_id)
	data_monster.role_dead.disconnect(_on_monster_dead)
	black_monster_dic.erase(data_monster.monster_unique_id)
	print("黑化--怪物死亡，删除数据:",black_monster_dic.size())
	# 触发数量变化信号
	count_changed.emit(black_monster_dic.size())


func update_level_count_limit(count: int):
	level_count_limit = count
	# 如果召唤物数量大于上限，则移除多余的召唤物
	_update_monster_count(level_count_limit + effect_count_limit)


func update_effect_count_limit(count: int):
	effect_count_limit = count
	# 如果召唤物数量大于上限，则移除多余的召唤物
	_update_monster_count(level_count_limit + effect_count_limit)


# 根据召唤物数量限制，移除多余的召唤物
func _update_monster_count(limit: int):
	if black_monster_dic.size() > limit:
		var remove_count = black_monster_dic.size() - limit
		for i in range(remove_count):
			var data_monster = black_monster_dic.values()[0]
			# 删除怪物
			data_monster.kill_role()
		# 触发数量变化信号
		count_changed.emit(black_monster_dic.size())


func clear_all():
	for data_monster in black_monster_dic.values():
		data_monster.kill_role()


func get_all_black_monster()-> Array[DataMonster]:
	return black_monster_dic.values()
