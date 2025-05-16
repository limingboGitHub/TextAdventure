extends Control

# 缓存工具
var cache_tool: BaseCacheTool = FileCacheTool.new()

# 选中的待导出文件列表
var selected_export_files: Array[String] = []
# 选中的待导出文件夹
var selected_export_dir: String = ""


func _enter_tree() -> void:
	# 子节点注入依赖
	$RoleSelectEnter.init_cache_tool(cache_tool)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() == "Android":
		# 请求权限
		OS.request_permissions()
	# 将资源从应用目录复制到用户目录
	cache_tool.copy_resources_to_user_dir()

	ToastManager.toast_added.connect(_on_toast_added)
	# 监听开始游戏信号
	$RoleSelectEnter.game_started.connect(_on_game_started)
	# 监听角色创建返回信号
	$RoleSelectEnter.go_back.connect(_on_role_select_enter_go_back)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_bt_pressed() -> void:
	get_tree().quit()


func _on_custom_bt_pressed() -> void:
	# 隐藏开始界面
	_hide_start_ui()
	# 展示自定义界面
	_show_custom_ui()


func _on_start_game_bt_pressed() -> void:
	# 隐藏开始界面
	_hide_start_ui()
	# 展示角色选择界面
	_show_select_ui()


func _show_start_ui() -> void:
	$VBoxContainer.show()
	$GameName.show()


func _hide_start_ui() -> void:
	$VBoxContainer.hide()
	$GameName.hide()
	

func _show_select_ui() -> void:
	$RoleSelectEnter.show()


func _show_custom_ui() -> void:
	$CustomControl.show()


func _on_toast_added(msg: String) -> void:
	$ToastControl.add_toast(msg)


func _on_game_started(role_id: String) -> void:
	# 隐藏角色选择界面
	$RoleSelectEnter.hide()
	# 展示loading界面
	$LoadingUI.show()
	# 保存开始游戏的角色id
	SingletonGame.start_role_id = role_id
	# 0.5秒后场景跳转
	$StartGameTimer.start()


func _on_start_game_timeout() -> void:
	# 场景跳转
	get_tree().change_scene_to_file("res://src/scenes/game/world.tscn")


func _on_import_file_bt_pressed() -> void:
	$CustomControl/ImportFileBt/ImportFileDialog.current_dir = _get_export_dir()
	$CustomControl/ImportFileBt/ImportFileDialog.show()


func _on_export_file_bt_pressed() -> void:
	$CustomControl/ExportFileBt/SelectExportFileDialog.show()


func _on_select_target_dir_dialog_dir_selected(dir: String) -> void:
	print("导出目标目录: ", dir)
	
	if selected_export_files.size() > 0:
		# 导出文件到指定目录
		for file_path in selected_export_files:
			var file_name = file_path.get_file()
			var target_path = dir.path_join(file_name)
			if cache_tool.copy_file(file_path, target_path):
				_show_tip_label("导出成功: " + target_path)
			else:
				_show_tip_label("文件导出失败: " + file_name)
	
	if selected_export_dir != "":
		# 导出文件夹到指定目录
		var dir_name = selected_export_dir.get_file()
		var target_dir = dir.path_join(dir_name)
		# 创建目标目录
		if not DirAccess.dir_exists_absolute(target_dir):
			DirAccess.make_dir_recursive_absolute(target_dir)
		# 使用缓存工具中的复制目录方法
		cache_tool.copy_directory(selected_export_dir, target_dir)
		_show_tip_label("导出成功: " + target_dir)
	# 清空选择
	selected_export_files.clear()
	selected_export_dir = ""


func _on_select_export_file_dialog_dir_selected(dir: String) -> void:
	selected_export_dir = dir
	print("选中的导出文件夹: ", selected_export_dir)
	_export_download()


func _on_select_export_file_dialog_file_selected(path: String) -> void:
	selected_export_files.clear()
	selected_export_files.append(path)
	print("选中的导出文件: ", selected_export_files)
	_export_download()


func _on_select_export_file_dialog_files_selected(paths: PackedStringArray) -> void:
	selected_export_files.clear()
	for path in paths:
		selected_export_files.append(path)
	print("选中的导出文件: ", selected_export_files)
	_export_download()


func _export_download() -> void:
	_on_select_target_dir_dialog_dir_selected(_get_export_dir())


func _get_export_dir() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)


func _on_reset_config_bt_pressed() -> void:
	# 将配置资源复制到用户目录
	cache_tool.copy_resources_to_user_dir(true)
	_show_tip_label("配置重置成功")


func _on_back_bt_pressed() -> void:
	# 隐藏自定义界面
	$CustomControl.hide()
	# 展示开始界面
	_show_start_ui()


func _on_import_file_dialog_dir_selected(dir: String) -> void:
	# 遍历匹配导入的文件夹名称
	var reason = cache_tool.import_dir_to_user_dir(dir)
	if reason != "":
		_show_tip_label(reason)
	else:
		_show_tip_label("导入成功")


func _on_import_file_dialog_file_selected(path: String) -> void:
	var reason = cache_tool.import_file_to_user_dir(path)
	if reason != "":
		_show_tip_label(reason)
	else:
		_show_tip_label("导入成功")


func _on_import_file_dialog_files_selected(paths: PackedStringArray) -> void:
	var reason = ""	
	for path in paths:
		var _reason = cache_tool.import_file_to_user_dir(path)
		if _reason != "":
			reason += _reason + "\n"
	if reason != "":
		_show_tip_label(reason)
	else:
		_show_tip_label("导入成功")


func _show_tip_label(text: String) -> void:
	$CustomControl/TipLabel.text = text


func _on_role_select_enter_go_back() -> void:
	# 展示开始界面
	_show_start_ui()
