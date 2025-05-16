class_name  RandomTool


## 获得一个随机数
static func random_num()-> String:
	return str(rand_from_seed(Time.get_ticks_usec())[0])
