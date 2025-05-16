class_name AttributeAbility

var hp: int = 0
var mp: int = 0
var power: int = 0
var agility: int = 0
var intelligence: int = 0
var luck: int = 0


func is_empty() -> bool:
	return power == 0 and agility == 0 \
		and intelligence == 0 and luck == 0 \
		and hp == 0 and mp == 0


func append(other: AttributeAbility) -> void:
	hp += other.hp
	mp += other.mp
	power += other.power
	agility += other.agility
	intelligence += other.intelligence
	luck += other.luck


# 保存属性(0值不需要保存)
func save() -> Dictionary:
	var json = {}
	if hp != 0:
		json["hp"] = hp
	if mp != 0:
		json["mp"] = mp
	if power != 0:
		json["power"] = power
	if agility != 0:
		json["agility"] = agility
	if intelligence != 0:
		json["intelligence"] = intelligence
	if luck != 0:
		json["luck"] = luck
	return json

func load(json: Dictionary) -> void:
	hp = json.get("hp", 0)
	mp = json.get("mp", 0)
	power = json.get("power", 0)
	agility = json.get("agility", 0)
	intelligence = json.get("intelligence", 0)
	luck = json.get("luck", 0)
