extends Control

## 技能展示对话框

var data_skill_bag: DataSkillBag

signal skill_used(data_skill: DataBaseSkill)

signal skill_active_toggled(data_skill: DataEffectBuffSkill, active: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 清理所有的技能组
	for child in $TabContainer.get_children():
		child.queue_free()

	# 测试代码
	# data_skill_bag = DataSkillBag.new()
	# var skill_list = [
	# 	data_skill_bag.create(DataSkillBag.STRONG_ATTACK),
	# 	data_skill_bag.create(DataSkillBag.GROUP_ATTACK),
	# ]
	# for skill in skill_list:
	# 	data_skill_bag.add_skill(DataSkillBag.SKILL_PHASE_1, skill)
	# data_skill_bag.skill_point = 10

	# set_data_skill_bag(data_skill_bag)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_button_pressed() -> void:
	hide()


func set_data_skill_bag(_data_skill_bag: DataSkillBag) -> void:
	self.data_skill_bag = _data_skill_bag
	
	# 显示技能组
	for key in _data_skill_bag.data.keys():
		_show_skill_group(key)
	# 监听技能的新增
	_data_skill_bag.skill_added.connect(_on_skill_added)
	
	# 显示技能点
	$SkillPoint/Label.text = str(_data_skill_bag.skill_point)
	# 监听技能点变化
	_data_skill_bag.skill_point_updated.connect(_on_skill_point_updated)


func _on_skill_added(phase: String, data_skill: DataBaseSkill) -> void:
	if not $TabContainer.has_node(phase):
		var skill_group = _create_skill_group(phase)
		skill_group.name = phase
		$TabContainer.add_child(skill_group)
	
	$TabContainer.get_node(phase).add_skill_item(data_skill)


## 显示技能组
## 
## @param _name: 技能组名称
func _show_skill_group(_name: String) -> void:
	var skill_group = _create_skill_group(_name)
	skill_group.name = _name
	$TabContainer.add_child(skill_group)

	var skill_list = data_skill_bag.get_skill_by_phase(_name)
	skill_group.add_skill_group(skill_list)


func _create_skill_group(_name: String) -> Control:
	# 实例化技能组
	var skill_group = SingletonGameScenePre.SkillGroupScene.instantiate()
	# 监听技能组技能添加事件
	skill_group.skill_add_pressed.connect(_on_skill_item_add_pressed)
	# 监听技能组技能使用事件
	skill_group.skill_used.connect(_on_skill_item_used)
	# 监听技能组技能激活事件
	skill_group.skill_active_toggled.connect(_on_skill_item_active_toggled)
	return skill_group


func _on_skill_item_add_pressed(phase: String,data_skill: DataBaseSkill):
	# print("add skill:",data_skill.name)
	if data_skill_bag.skill_point <= 0 or data_skill.is_max_level():
		return
	# 提升技能等级
	data_skill.add_level(1)
	# 消耗技能点
	data_skill_bag.remove_skill_point(1)


func _on_skill_item_used(data_skill: DataBaseSkill) -> void:
	skill_used.emit(data_skill)


func _on_skill_point_updated(skill_point: int) -> void:
	$SkillPoint/Label.text = str(skill_point)


func _on_skill_item_active_toggled(data_skill: DataEffectBuffSkill, active: bool) -> void:
	skill_active_toggled.emit(data_skill, active)
