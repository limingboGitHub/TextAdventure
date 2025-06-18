class_name DataBlackMonsterManager

## 黑化召唤管理器
## 
## 玩家携带的黑化召唤物可以贯通地图，存在召唤上限

# 召唤物上限
var count_limit = 1

# 召唤物容器
var black_monster_list: Array[DataMonster] = []

# 玩家
var data_player: DataPlayer

# 召唤物数量变化信号
signal count_changed(count: int)


# 初始化数据
func init_data(_data_player: DataPlayer):
	self.data_player = _data_player


# 添加召唤物
func add(data_monster: DataMonster)-> bool:
	if black_monster_list.size() >= count_limit:
		return false
	
	# 技能数值强度
	if not data_player.has_effect("effect_000045"):
		return false
	var effect = data_player.get_effect("effect_000045")
	# 获取玩家魔法力，进行怪物数值增幅
	var magic_value = effect.value * data_player.get_final_details().magic
	# 黑化怪物
	print("黑化--添加怪物:",data_monster.monster_unique_id)
	data_monster.black_monster(magic_value)
	black_monster_list.append(data_monster)
	# 监听黑化怪物死亡事件
	data_monster.role_dead.connect(_on_monster_dead)
	# 触发数量变化信号
	count_changed.emit(black_monster_list.size())
	return true


func _on_monster_dead(data_monster: DataMonster):
	print("黑化--怪物死亡:",data_monster.monster_unique_id)
	data_monster.role_dead.disconnect(_on_monster_dead)
	black_monster_list.erase(data_monster)
	# 触发数量变化信号
	count_changed.emit(black_monster_list.size())


func update_count_limit(count: int):
	count_limit = count
	# 如果召唤物数量大于上限，则移除多余的召唤物
	if black_monster_list.size() > count_limit:
		var remove_count = black_monster_list.size() - count_limit
		for i in range(remove_count):
			var data_monster = black_monster_list.pop_front()
			# 删除怪物
			data_monster.kill_role()
		# 触发数量变化信号
		count_changed.emit(black_monster_list.size())


func clear_all():
	for i in range(black_monster_list.size()):
		var data_monster = black_monster_list.pop_front()
		data_monster.kill_role()
