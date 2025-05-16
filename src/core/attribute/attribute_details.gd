class_name AttributeDetails
'''
详细属性
'''
var max_hp: int = 0
var max_mp: int = 0

var attack: int = 0
var defense: int = 0
var magic: int = 0
var magic_def: int = 0
var accuracy: int = 0
var evasion: int = 0
var hand_technology: int = 0
var move_speed: int = 0
var jump_power: int = 0
var recover_hp: int = 0
var recover_mp: int = 0
var attack_speed: int = 0
var exp_gain: float = 0.0
# 攻击力波动上下限
var attack_min_rate: float = 0.0
var attack_max_rate: float = 0.0
# 魔法力波动上下限
var magic_min_rate: float = 0.0
var magic_max_rate: float = 0.0


func is_empty() -> bool:
	return max_hp == 0 and max_mp == 0 \
		and attack == 0 and magic == 0 \
		and defense == 0 and magic_def == 0 \
		and accuracy == 0 and evasion == 0 \
		and hand_technology == 0 and move_speed == 0 \
		and jump_power == 0 and recover_hp == 0 and recover_mp == 0 \
		and attack_speed == 0 and exp_gain == 0.0 \
		and attack_min_rate == 0.0 and attack_max_rate == 0.0 \
		and magic_min_rate == 0.0 and magic_max_rate == 0.0


func append(attribute: AttributeDetails):
	max_hp += attribute.max_hp
	max_mp += attribute.max_mp
	attack += attribute.attack
	defense += attribute.defense
	magic += attribute.magic
	magic_def += attribute.magic_def
	accuracy += attribute.accuracy
	evasion += attribute.evasion
	hand_technology += attribute.hand_technology
	move_speed += attribute.move_speed
	jump_power += attribute.jump_power
	recover_hp += attribute.recover_hp
	recover_mp += attribute.recover_mp
	attack_speed += attribute.attack_speed
	exp_gain += attribute.exp_gain
	attack_min_rate += attribute.attack_min_rate
	attack_max_rate += attribute.attack_max_rate
	magic_min_rate += attribute.magic_min_rate
	magic_max_rate += attribute.magic_max_rate


func save() -> Dictionary:
	var json = {}
	if max_hp != 0:
		json["max_hp"] = max_hp
	if max_mp != 0:
		json["max_mp"] = max_mp
	if attack != 0:
		json["attack"] = attack
	if defense != 0:
		json["defense"] = defense
	if magic != 0:
		json["magic"] = magic
	if magic_def != 0:
		json["magic_def"] = magic_def
	if accuracy != 0:
		json["accuracy"] = accuracy
	if evasion != 0:
		json["evasion"] = evasion
	if hand_technology != 0:
		json["hand_technology"] = hand_technology
	if move_speed != 0:
		json["move_speed"] = move_speed
	if jump_power != 0:
		json["jump_power"] = jump_power
	if recover_hp != 0:
		json["recover_hp"] = recover_hp	
	if recover_mp != 0:
		json["recover_mp"] = recover_mp
	if attack_speed != 0:
		json["attack_speed"] = attack_speed
	if exp_gain != 0.0:
		json["exp_gain"] = exp_gain
	if attack_min_rate != 0.0:
		json["attack_min_rate"] = attack_min_rate
	if attack_max_rate != 0.0:
		json["attack_max_rate"] = attack_max_rate
	if magic_min_rate != 0.0:
		json["magic_min_rate"] = magic_min_rate
	if magic_max_rate != 0.0:
		json["magic_max_rate"] = magic_max_rate
	return json


func load(json: Dictionary):
	if json.has("max_hp"):
		max_hp = json.get("max_hp", 0)
	if json.has("max_mp"):
		max_mp = json.get("max_mp", 0)
	if json.has("attack"):
		attack = json.get("attack", 0)
	if json.has("defense"):
		defense = json.get("defense", 0)
	if json.has("magic"):
		magic = json.get("magic", 0)
	if json.has("magic_def"):
		magic_def = json.get("magic_def", 0)
	if json.has("accuracy"):
		accuracy = json.get("accuracy", 0)
	if json.has("evasion"):
		evasion = json.get("evasion", 0)
	if json.has("hand_technology"):
		hand_technology = json.get("hand_technology", 0)
	if json.has("move_speed"):
		move_speed = json.get("move_speed", 0)
	if json.has("jump_power"):
		jump_power = json.get("jump_power", 0)
	if json.has("recover_hp"):
		recover_hp = json.get("recover_hp", 0)
	if json.has("recover_mp"):
		recover_mp = json.get("recover_mp", 0)
	if json.has("attack_speed"):
		attack_speed = json.get("attack_speed", 0)
	if json.has("exp_gain"):
		exp_gain = json.get("exp_gain", 0.0)
	if json.has("attack_min_rate"):
		attack_min_rate = json.get("attack_min_rate", 0.0)
	if json.has("attack_max_rate"):
		attack_max_rate = json.get("attack_max_rate", 0.0)
	if json.has("magic_min_rate"):
		magic_min_rate = json.get("magic_min_rate", 0.0)
	if json.has("magic_max_rate"):
		magic_max_rate = json.get("magic_max_rate", 0.0)
