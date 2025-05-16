extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## 展示任务要求
func set_mission_requires(requires: Array[MissionRequire]) -> void:
	show()
	$Title.text = "任务要求："

	# VBoxContainer没有clear方法，需要手动删除所有子节点
	for child in $Items.get_children():
		$Items.remove_child(child)
		child.queue_free()
	# 添加新的要求
	for require in requires:
		if require is MissionRequireCollect:
			var label = _create_item_label(
				"物品：" + require.item_name + " " + \
				str(require.collect_count) + "/" + str(require.target_count)
			)
			$Items.add_child(label)
		elif require is MissionRequireKill:
			var label = _create_item_label(
				"击杀：" + require.monster_name + " " + \
				str(require.kill_count) + "/" + str(require.target_count)
			)
			$Items.add_child(label)
		else:
			pass


## 展示任务奖励
func set_mission_rewards(rewards: Array[MissionReward]) -> void:
	show()
	$Title.text = "任务奖励："

	# 清除现有的奖励项
	for child in $Items.get_children():
		$Items.remove_child(child)
		child.queue_free()
	
	# 添加新的奖励项
	for reward in rewards:
		if reward is MissionRewardMoney:
			# 金钱
			if reward.count > 0:
				var money_label = _create_item_label("金钱：" + str(reward.count))
				$Items.add_child(money_label)
		elif reward is MissionRewardExp:
			# 经验
			if reward.count > 0:
				var exp_label = _create_item_label("经验：" + str(reward.count))
				$Items.add_child(exp_label)
		elif reward is MissionRewardItem:
			# 物品
			if reward.count > 0:
				var item_label = _create_item_label("物品：" + reward.item_name + " × " + str(reward.count))
				$Items.add_child(item_label)
		elif reward is MissionRewardJob:
			# 职业
			if reward.job_name != "":
				var job_label = _create_item_label("转职：" + reward.job_name)
				$Items.add_child(job_label)
		elif reward is MissionRewardAlchemy:
			# 炼金
			if reward.alchemy_name != "":
				var alchemy_label = _create_item_label("炼金配方：" + reward.alchemy_name)
				$Items.add_child(alchemy_label)
		elif reward is MissionRewardSkill:
			# 技能
			if reward.skill_name != "":
				var skill_label = _create_item_label("技能：" + reward.skill_name)
				$Items.add_child(skill_label)


## 创建一个item的label
##
## @param text 文本内容
func _create_item_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 25)
	return label
