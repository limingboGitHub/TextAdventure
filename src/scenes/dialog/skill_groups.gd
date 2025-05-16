extends "res://src/scenes/widget/my_scroll_container.gd"


signal skill_used(data_skill: DataBaseSkill)

signal skill_add_pressed(phase: String,data_skill: DataBaseSkill)

signal skill_active_toggled(data_skill: DataEffectBuffSkill, active: bool)


func _ready() -> void:
	# 清理所有的技能组
	for child in $GridContainer.get_children():
		child.queue_free()


## 添加技能组
## 
## @param _skill_list: 技能列表
func add_skill_group(_skill_list: Array) -> void:
	for skill in _skill_list:
		add_skill_item(skill)


func add_skill_item(data_skill: DataBaseSkill) -> void:
	var skill_item = SingletonGameScenePre.SkillItemScene.instantiate()
	skill_item.name = data_skill.id
	skill_item.set_data(data_skill)
	skill_item.skill_add_pressed.connect(_on_skill_item_add_pressed)
	skill_item.skill_used.connect(_on_skill_item_used)
	skill_item.skill_active_toggled.connect(_on_skill_item_active_toggled)
	$GridContainer.add_child(skill_item)


func _on_skill_item_add_pressed(data_skill: DataBaseSkill):
	skill_add_pressed.emit(name,data_skill)


func _on_skill_item_used(data_skill: DataBaseSkill) -> void:
	skill_used.emit(data_skill)


func _on_skill_item_active_toggled(data_skill: DataEffectBuffSkill, active: bool) -> void:
	skill_active_toggled.emit(data_skill, active)
