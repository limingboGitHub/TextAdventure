extends Control

## NPC聊天对话框

# 每个字符对应的动画时长
const CHAR_DURATION = 0.01
var next_char_time = 0.0


var message: String

var player_name: String


signal mission_accept_pressed(mission: DataMission)

signal mission_phase_selection_pressed(phase: DataMissionPhase)

signal bag_selection_pressed(bag: DataBag)

signal teleport_selection_pressed(data_teleport: DataTeleport)

signal ok_bt_pressed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set_message("这是一段测试文本这是一段测试文本这是一段测试文本这是一段测试文本")

	# 测试代码：任务要求展示
	# var require = MissionRequire.new()
	# require.items.append(MissionItem.new("1001", 10))
	# require.items.append(MissionItem.new("1002", 10))
	# _show_mission_require(require)

	# 测试代码：任务奖励展示
	# var reward = MissionReward.new()
	# reward.money = 100
	# reward.exp = 100
	# reward.items.append(MissionItem.new("1001", 10))
	# reward.items.append(MissionItem.new("1002", 10))
	# reward.items.append(MissionItem.new("1003", 10))
	# _show_mission_reward(reward)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# 判断当前字符显示的长度
	if $BackContainer/VBoxContainer/Message.text.length() > $BackContainer/VBoxContainer/Message.visible_characters:
		if next_char_time <= 0.0:
			$BackContainer/VBoxContainer/Message.visible_characters += 1
			next_char_time = CHAR_DURATION
		else:
			next_char_time -= delta


func _on_close_button_pressed() -> void:
	hide()


func set_player_name(player_name: String) -> void:
	self.player_name = player_name


func set_title(title: String) -> void:
	$Label.text = title


func set_message(input_message: String) -> void:
	message = input_message

	$BackContainer/VBoxContainer/Message.text = message
	$BackContainer/VBoxContainer/Message.visible_characters = 0


## 设置选项
##
## @param selections 类型为Array[DataMissionPhase/DataBag]，可空类型
func set_selections(selections):
	# 显示选项
	if selections != null and selections.size() > 0:
		# 删除所有选项
		for child in $BackContainer/VBoxContainer/SelectionContainer.get_children():
			$BackContainer/VBoxContainer/SelectionContainer.remove_child(child)
			child.queue_free()
		# 隐藏按钮
		$BackContainer/VBoxContainer/HBoxContainer/OKBt.hide()
		# 新增高度
		for selection in selections:
			var bt = Button.new()
			bt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			bt.custom_minimum_size.x = 430
			bt.custom_minimum_size.y = 40
			if selection is DataMissionPhase:
				bt.text = selection.data_mission.name + "(" + selection.name + ")"
				bt.pressed.connect(_on_mission_selection_pressed.bind(selection))
			elif selection is DataBag:
				bt.text = "商店"
				bt.pressed.connect(_on_bag_selection_pressed.bind(selection))
			elif selection is DataTeleport:
				bt.text = "传送"
				bt.pressed.connect(_on_teleport_selection_pressed.bind(selection))
			$BackContainer/VBoxContainer/SelectionContainer.add_child(bt)
			
		$BackContainer/VBoxContainer/SelectionContainer.show()
	else:
		$BackContainer/VBoxContainer/SelectionContainer.hide()


func set_mission_requires(requires: Array[MissionRequire]) -> void:
	$BackContainer/VBoxContainer/RequireOrReward.set_mission_requires(requires)


func set_mission_rewards(rewards: Array[MissionReward]) -> void:
	$BackContainer/VBoxContainer/RequireOrReward.set_mission_rewards(rewards)	


func show_ok_bt(text: String) -> void:
	if text == "":
		$BackContainer/VBoxContainer/HBoxContainer/OKBt.hide()
		return
	$BackContainer/VBoxContainer/HBoxContainer/OKBt.text = text
	$BackContainer/VBoxContainer/HBoxContainer/OKBt.show()

 
func _on_mission_selection_pressed(phase: DataMissionPhase) -> void:
	# print("mission selected: ",mission.name)
	mission_phase_selection_pressed.emit(phase)


func _on_bag_selection_pressed(bag: DataBag) -> void:
	bag_selection_pressed.emit(bag)


func _on_teleport_selection_pressed(data_teleport: DataTeleport) -> void:
	teleport_selection_pressed.emit(data_teleport)


func _on_ok_bt_pressed() -> void:
	ok_bt_pressed.emit()
	

func hide_require_or_reward() -> void:
	$BackContainer/VBoxContainer/RequireOrReward.hide()
