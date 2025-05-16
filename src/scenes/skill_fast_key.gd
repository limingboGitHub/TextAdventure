extends Control

# 技能快捷键

# 技能列表
var data_skill_bag: DataSkillBag
# 挂机技能
var auto_skill: DataBaseSkill

signal skill_selected(skill: DataBaseSkill)


func set_data(_data_skill_bag: DataSkillBag, _auto_skill: DataBaseSkill) -> void:
	self.data_skill_bag = _data_skill_bag
	self.auto_skill = _auto_skill
	# 展示技能列表
	_show_skill_list(data_skill_bag)
	# 监听技能等级变化
	data_skill_bag.skill_level_updated.connect(_on_skill_level_updated)


func _on_skill_level_updated(skill: DataBaseSkill):
	# 当技能从0升级到1，且为攻击技能，则添加到技能列表
	if skill.level == 1 and skill.type == "attack":
		var index = $ItemList.add_item(skill.name)
		$ItemList.set_item_metadata(index,skill)


func _show_skill_list(_data_skill_bag: DataSkillBag) -> void:
	$ItemList.clear()
	
	var index = 0
	var selected_index = -1

	# 添加普攻
	$ItemList.add_item('普攻')
	$ItemList.set_item_metadata(index,data_skill_bag.normal_attack)
	# 看当前的挂机技能是不是普攻，是则选中
	if auto_skill!=null and auto_skill.id == data_skill_bag.normal_attack.id:
		selected_index = index
	index += 1

	for skill_list in data_skill_bag.data.values():
		for skill in skill_list:
			# 只展示等级大于0的技能
			if skill.level == 0:
				continue
			# 只展示攻击类技能
			if skill.type != "attack":
				continue
			$ItemList.add_item(skill.name)
			$ItemList.set_item_metadata(index,skill)
			# 记录已经设定的挂机技能位置
			if auto_skill!=null and auto_skill.id == skill.id:
				selected_index = index

			index += 1
	
	$ItemList.select(selected_index)

func _on_item_list_item_selected(index: int) -> void:
	var skill = $ItemList.get_item_metadata(index)
	skill_selected.emit(skill)
