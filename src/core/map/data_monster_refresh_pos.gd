
class_name MonsterRefreshPos
## 地图怪物刷新点类


# 怪物刷新信息
class RefreshInfo:
	var monster_id: String
	# 刷新概率 0-1.0
	var rate: float
	# 刷新间隔时间 单位：秒,0表示最小间隔（最小间隔是地图的整体刷新间隔时间，具体要看怪物刷新定时器的时间，通常为2秒）
	var refresh_interval: int = 0

# 地图怪物刷新点ID，用于区分地图怪物刷新点，比如说用于地图怪物刷新点信息的持久化存储
var id: int
var monster_refresh_list: Array[RefreshInfo] = []
var data_monster: DataMonster
# 怪物刷新点的位置 0-1.0 如果为空，则随机一个位置
var pos: Vector2 = Vector2.INF

func _init(_id: int) -> void:
	id = _id

# 按照概率表随机一个怪物ID
# 1. 先统计所有怪物的刷新概率之和，排除其中刷新间隔时间未达到的怪物。
# 2. 随机一个0-1的数，看命中哪个怪物
func random_monster_id(monster_refresh_time_dic: Dictionary) -> String:
	#print("monster_refresh:", "开始刷新")
	# step1
	var valid_monster_list = []
	var rate_sum = 0
	for refresh_info in monster_refresh_list:
		# 获取当前时间
		var current_time = Time.get_unix_time_from_system()
		# 如果刷新间隔时间大于0，则判断是否到达刷新时间
		if refresh_info.refresh_interval > 0:
			# 获取怪物刷新间隔开始时间
			var start_time = -INF
			if monster_refresh_time_dic.has(refresh_info.monster_id):
				start_time = monster_refresh_time_dic[refresh_info.monster_id]
			#print("monster_refresh:", refresh_info.monster_id, " 有刷新间隔:", refresh_info.refresh_interval, " 当前时间:", current_time, " 刷新开始时间:", start_time)
			# 如果时间差大于刷新间隔，则加入有效列表
			if current_time - start_time >= (refresh_info.refresh_interval / float(SingletonGame.speed)):
				valid_monster_list.append(refresh_info)
				rate_sum += refresh_info.rate
				#print("monster_refresh:", refresh_info.monster_id, " 刷新间隔已到，加入有效列表")
		else:
			valid_monster_list.append(refresh_info)
			rate_sum += refresh_info.rate
	if valid_monster_list.is_empty():
		return ""

	# step2 先随机一个0-1的数，根据怪物的刷新概率之和缩放，保证随机的数落在0-rate_sum之间
	var random_num = randf() * rate_sum
	#print("monster_refresh:"," 总概率", rate_sum, " 随机数:", random_num)
	# 遍历怪物刷新概率，看命中哪个怪物
	var rate = 0
	for refresh_info in valid_monster_list:
		rate += refresh_info.rate
		if random_num < rate:
			return refresh_info.monster_id
	return ""
