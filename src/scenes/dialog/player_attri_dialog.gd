extends Panel

## 角色属性面板

var data_player: DataPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_player(player: DataPlayer):
	data_player = player
	$Name/Label.text = player.player_name
	$Job/Label.text = player.job_name
	$Hp/Label.text = str(player.attribute.final_details.max_hp) + "/" + str(player.hp)
	$Mp/Label.text = str(player.attribute.final_details.max_mp) + "/" + str(player.mp)


	_update_attribute(player)

	# 监听玩家属性变化
	player.role_hurted.connect(_on_role_hurted)
	player.level_updated.connect(_on_level_updated)
	player.attribute_updated.connect(_on_attribute_updated)
	player.hp_updated.connect(_on_hp_updated)
	player.mp_updated.connect(_on_mp_updated)


func _update_attribute(player: DataPlayer) -> void:
	$AllocPoint/Label.text = str(player.allot_point)
	# 力量的展示组成 = 基础力量+加点力量（其他额外附加的力量）
	var base_attr = player.attribute.get_ability(Attribute.ATTRIBUTE_BASE)
	var alloc_attr = player.attribute.get_ability(DataPlayer.ATTRIBUTE_ALLOC)
	var all_attr = player.attribute.all_ability
	
	var base_and_alloc_power = base_attr.power + alloc_attr.power
	$Power/Label.text = str(base_and_alloc_power) + "(" + str(all_attr.power - base_and_alloc_power) + ")"
	var base_and_alloc_agility = base_attr.agility + alloc_attr.agility
	$Agility/Label.text = str(base_and_alloc_agility) + "(" + str(all_attr.agility - base_and_alloc_agility) + ")"
	var base_and_alloc_intelligence = base_attr.intelligence + alloc_attr.intelligence
	$Intelligence/Label.text = str(base_and_alloc_intelligence) + "(" + str(all_attr.intelligence - base_and_alloc_intelligence) + ")"
	var base_and_alloc_luck = base_attr.luck + alloc_attr.luck
	$Luck/Label.text = str(base_and_alloc_luck) + "(" + str(all_attr.luck - base_and_alloc_luck) + ")"

	$Details/Attack/Label.text = str(player.get_final_min_attack()) + "~" + str(player.get_final_max_attack())
	$Details/Magic/Label.text = str(player.get_final_min_magic()) + "~" + str(player.get_final_max_magic())
	$Details/Defense/Label.text = str(player.attribute.final_details.defense)
	$Details/MagicDef/Label.text = str(player.attribute.final_details.magic_def)
	$Details/Accuracy/Label.text = str(player.attribute.final_details.accuracy)
	$Details/Evasion/Label.text = str(player.attribute.final_details.evasion)
	$Details/HandTechnology/Label.text = str(player.attribute.final_details.hand_technology)
	$Details/MoveSpeed/Label.text = str(player.attribute.final_details.move_speed)
	$Details/RecoverHP/Label.text = str(player.attribute.final_details.recover_hp)
	$Details/RecoverMP/Label.text = str(player.attribute.final_details.recover_mp)
	$Details/ExpGain/Label.text = str(int(player.attribute.final_details.exp_gain * 100)) + "%"


func _on_level_updated(data_role: DataRole) -> void:
	if data_role is DataPlayer:
		$AllocPoint/Label.text = str(data_role.allot_point)


func _on_role_hurted(data_role: DataRole,data_damage: DataDamage) -> void:
	if data_role is DataPlayer:
		$Hp/Label.text = str(data_role.attribute.final_details.max_hp) + "/" + str(data_role.hp)


func _on_attribute_updated(data_role: DataRole) -> void:
	if data_role is DataPlayer:
		_update_attribute(data_role)


func _on_close_button_pressed() -> void:
	hide()


func _on_hp_button_pressed() -> void:
	data_player.alloc_ability(0,1)


func _on_mp_button_pressed() -> void:
	data_player.alloc_ability(1,1)


func _on_auto_alloc_button_pressed() -> void:
	# 根据当前职业自动分配属性点
	if data_player.job_id == "job_000000":
		data_player.alloc_ability(2,data_player.allot_point)
	elif data_player.job_id == "job_000001":
		# 4/5 力量 1/5 敏捷
		var power_point = int(data_player.allot_point * 4 / 5.0)
		var agility_point = int(data_player.allot_point * 1 / 5.0)
		data_player.alloc_ability(2,power_point)
		data_player.alloc_ability(3,agility_point)
	elif data_player.job_id == "job_000101":
		# 4/5 智力 1/5 运气
		var intel_point = int(data_player.allot_point * 4 / 5.0)
		var luck_point = int(data_player.allot_point * 1 / 5.0)
		data_player.alloc_ability(4,intel_point)
		data_player.alloc_ability(5,luck_point)
	elif data_player.job_id == "job_000201":
		# 3/5 运气 2/5 敏捷
		var luck_point = int(data_player.allot_point * 3 / 5.0)
		var agility_point = int(data_player.allot_point * 2 / 5.0)
		data_player.alloc_ability(5,luck_point)
		data_player.alloc_ability(3,agility_point)


func _on_power_button_pressed() -> void:
	data_player.alloc_ability(2,1)


func _on_agility_button_pressed() -> void:
	data_player.alloc_ability(3,1)


func _on_intelligence_button_pressed() -> void:
	data_player.alloc_ability(4,1)


func _on_luck_button_pressed() -> void:
	data_player.alloc_ability(5,1)


func _on_hp_updated(data_role: DataRole) -> void:
	if data_role is DataPlayer:
		$Hp/Label.text = str(data_role.hp) + "/" + str(data_role.attribute.final_details.max_hp)


func _on_mp_updated(data_role: DataRole) -> void:
	if data_role is DataPlayer:
		$Mp/Label.text = str(data_role.mp) + "/" + str(data_role.attribute.final_details.max_mp)


func _on_reset_bt_pressed() -> void:
	data_player.reset_ability_alloc()


func _on_power_all_bt_pressed() -> void:
	data_player.alloc_ability(2,data_player.allot_point)


func _on_agility_all_bt_pressed() -> void:
	data_player.alloc_ability(3,data_player.allot_point)


func _on_intel_all_bt_pressed() -> void:
	data_player.alloc_ability(4,data_player.allot_point)


func _on_luck_all_bt_pressed() -> void:
	data_player.alloc_ability(5,data_player.allot_point)
