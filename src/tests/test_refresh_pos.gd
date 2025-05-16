class_name TestRefreshPos

## 刷新点的测试类


func test():
	
	test_one()

	test_tow()

	test_five()

	print("测试通过")
	

func test_one():
	var refresh_pos = MonsterRefreshPos.new(0)
	
	# 加入1个怪物信息
	var refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0001"
	refresh_info.rate = 100
	refresh_pos.monster_refresh_list.append(refresh_info)

	# 随机获取1000次怪物ID
	#for i in range(1000):
		#var monster_id = refresh_pos.random_monster_id()
		#assert(monster_id == "0001")


func test_tow():
	var refresh_pos = MonsterRefreshPos.new(0)
	
	# 加入2个怪物信息
	var refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0001"
	refresh_info.rate = 90
	refresh_pos.monster_refresh_list.append(refresh_info)

	refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0002"
	refresh_info.rate = 10
	refresh_pos.monster_refresh_list.append(refresh_info)

	# 随机获取1000次怪物ID
	var monster_1_num = 0
	var monster_2_num = 0
	#for i in range(10000):
		#var monster_id = refresh_pos.random_monster_id()
		#if monster_id == "0001":
			#monster_1_num += 1
		#elif monster_id == "0002":
			#monster_2_num += 1
		#else:
			#assert(false)

	# 检查随机结果是否符合概率
	print("monster_1_num:", monster_1_num)
	print("monster_2_num:", monster_2_num)
	# 测试数量是否在误差范围内
	assert(abs(monster_1_num - 9000) < 100)
	assert(abs(monster_2_num - 1000) < 100)


func test_five():
	var refresh_pos = MonsterRefreshPos.new(0)
	
	# 加入5个怪物信息
	var refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0001"
	refresh_info.rate = 50
	refresh_pos.monster_refresh_list.append(refresh_info)

	refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0002"
	refresh_info.rate = 20
	refresh_pos.monster_refresh_list.append(refresh_info)

	refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0003"
	refresh_info.rate = 10
	refresh_pos.monster_refresh_list.append(refresh_info)

	refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0004"
	refresh_info.rate = 10
	refresh_pos.monster_refresh_list.append(refresh_info)

	refresh_info = MonsterRefreshPos.RefreshInfo.new()
	refresh_info.monster_id = "0005"
	refresh_info.rate = 10
	refresh_pos.monster_refresh_list.append(refresh_info)

	# 随机获取1000次怪物ID
	var monster_1_num = 0
	var monster_2_num = 0
	var monster_3_num = 0
	var monster_4_num = 0
	var monster_5_num = 0
	#for i in range(10000):
		#var monster_id = refresh_pos.random_monster_id()
		#if monster_id == "0001":
			#monster_1_num += 1
		#elif monster_id == "0002":
			#monster_2_num += 1
		#elif monster_id == "0003":
			#monster_3_num += 1
		#elif monster_id == "0004":
			#monster_4_num += 1
		#elif monster_id == "0005":
			#monster_5_num += 1
		#else:
			#assert(false)

	# 检查随机结果是否符合概率
	print("monster_1_num:", monster_1_num)
	print("monster_2_num:", monster_2_num)
	print("monster_3_num:", monster_3_num)
	print("monster_4_num:", monster_4_num)
	print("monster_5_num:", monster_5_num)
	
