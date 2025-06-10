extends Control

## 挂机设置对话框

# HP警戒线
var hp_warning_line: int
# MP警戒线
var mp_warning_line: int
# 自动连续使用炼金药剂
var auto_use_alchemy: bool
# 技能列表
var data_skill_bag: DataSkillBag

signal setting_saved(
	hp_warning_line: int, 
	mp_warning_line: int,
	auto_use_alchemy: bool
)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_data(
	hp_warning_line: int, 
	mp_warning_line: int,
	auto_use_alchemy: bool
) -> void:
	self.hp_warning_line = hp_warning_line
	self.mp_warning_line = mp_warning_line
	self.auto_use_alchemy = auto_use_alchemy
	
	$HpWarningLine/LineEdit.text = str(hp_warning_line)
	$MpWarningLine/LineEdit.text = str(mp_warning_line)
	$CheckButton.button_pressed = auto_use_alchemy


func _on_close_button_pressed() -> void:
	hide()


func _on_ok_button_pressed() -> void:
	# 旧的值
	var old_hp_warning_line = hp_warning_line
	var old_mp_warning_line = mp_warning_line
	# 获取输入值
	var hp_input = $HpWarningLine/LineEdit.text
	var mp_input = $MpWarningLine/LineEdit.text
	
	# 验证输入是否为有效数字
	if not hp_input.is_valid_int():
		$HpWarningLine/LineEdit.text = str(old_hp_warning_line)
		return
	if  not mp_input.is_valid_int():
		$MpWarningLine/LineEdit.text = str(old_mp_warning_line)
		return
	
	var hp_value = int(hp_input)
	var mp_value = int(mp_input)
	
	# 验证数值范围（0-99）
	if hp_value < 1 or hp_value > 99:
		$HpWarningLine/LineEdit.text = str(old_hp_warning_line)
		return
	
	if mp_value < 1 or mp_value > 99:
		$MpWarningLine/LineEdit.text = str(old_mp_warning_line)
		return
	
	# 保存设置
	hp_warning_line = hp_value
	mp_warning_line = mp_value
	print('挂机设置保存:', hp_warning_line, mp_warning_line)
	setting_saved.emit(hp_warning_line, mp_warning_line, auto_use_alchemy)


func _on_check_button_toggled(toggled_on: bool) -> void:
	auto_use_alchemy = toggled_on
