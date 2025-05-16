extends Control

## 挂机设置对话框

# HP警戒线
var hp_warning_line: int
# MP警戒线
var mp_warning_line: int
# 技能列表
var data_skill_bag: DataSkillBag

signal setting_saved(
	hp_warning_line: int, 
	mp_warning_line: int
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
) -> void:
	self.hp_warning_line = hp_warning_line
	self.mp_warning_line = mp_warning_line
	
	$HpWarningLine/LineEdit.text = str(hp_warning_line)
	$MpWarningLine/LineEdit.text = str(mp_warning_line)


func _on_close_button_pressed() -> void:
	hide()


func _on_ok_button_pressed() -> void:
	# 保存设置
	hp_warning_line = int($HpWarningLine/LineEdit.text)
	mp_warning_line = int($MpWarningLine/LineEdit.text)
	print('挂机设置保存:', hp_warning_line, mp_warning_line)
	setting_saved.emit(hp_warning_line, mp_warning_line)
