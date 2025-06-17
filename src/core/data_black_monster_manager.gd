class_name DataBlackMonsterManager

## 黑化召唤管理器
## 
## 玩家携带的黑化召唤物可以贯通地图，存在召唤上限

# 召唤物上限
var count_limit = 1

# 召唤物容器
var black_monster_list: Array[DataMonster] = []


# 添加召唤物
func add(data_monster: DataMonster)-> bool:
	if black_monster_list.size() >= count_limit:
		return false
	# 黑化怪物
	print("黑化--添加怪物:",data_monster.monster_unique_id)
	data_monster.black_monster()
	black_monster_list.append(data_monster)
	# 监听黑化怪物死亡事件
	data_monster.role_dead.connect(_on_monster_dead)
	return true


func _on_monster_dead(data_monster: DataMonster):
	print("黑化--怪物死亡:",data_monster.monster_unique_id)
	data_monster.role_dead.disconnect(_on_monster_dead)
	black_monster_list.erase(data_monster)
