'''
缓存工具的基类
'''
class_name BaseCacheTool

func save_data_player(data_player: DataPlayer,save_id: String):
	pass


func load_data_player(_save_id: String) -> DataPlayer:
	return null


func save(data_world: DataWorld,save_id: String):
	pass


func remove(save_id: String):
	pass


func save_roles(role_json: String):
	pass


func load_roles() -> String:
	return ''


# 将所有配置资源保存到用户目录
func copy_resources_to_user_dir(_is_force: bool = false):
	pass


func copy_file(source_path: String, target_path: String) -> bool:
	return false


# 将配置资源文件夹导入到用户目录
func import_dir_to_user_dir(dir: String) -> String:
	return "方法未实现"


# 将配置资源文件导入到用户目录
func import_file_to_user_dir(file: String) -> String:
	return "方法未实现"
