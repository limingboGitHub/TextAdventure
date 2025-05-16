class_name TestResManager

## 资源管理器的测试类
##
## 需要先注入一个res_manager的实例，才能正常运行

var log = LogTool.new()

func test(res_manager):
	log.init("test_res_manager")
	log.print_time_cost("test start")

	test_load_monster_config(res_manager)

	test_load_drop_thing_config(res_manager)

	log.print_time_cost("test finish")

func test_load_monster_config(res_manager):
	var monster_config = res_manager.get_monster_config("0001")
	assert(monster_config!= null)

	monster_config = res_manager.get_monster_config("0210100")
	assert(monster_config!= null)
	log.print_time("test_load_monster_config passed")

func test_load_drop_thing_config(res_manager):
	var drop_thing_config = res_manager.get_item_config("01004192")
	assert(drop_thing_config['info.islot'] == "Cp")

	# drop_thing_config = res_manager.get_item_config("01102005")
	# assert(drop_thing_config['info.islot'] == "Sr")

	drop_thing_config = res_manager.get_item_config("01050038")
	assert(drop_thing_config['info.islot'] == "MaPn")

	drop_thing_config = res_manager.get_item_config("01071001")
	assert(drop_thing_config['info.islot'] == "So")

	drop_thing_config = res_manager.get_item_config("01302000")
	assert(drop_thing_config['info.islot'] == "Wp")

	log.print_time("test_load_drop_thing_config passed")
