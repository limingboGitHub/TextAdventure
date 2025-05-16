class_name MonsterManager


# 对外接口 创建怪物
func create_monster(monster_id: String,is_elite: bool,monster_config: Dictionary)-> DataMonster:
	var monster = DataMonster.new()
	monster.monster_id = monster_id
	monster.monster_unique_id = RandomTool.random_num()
	monster.name = monster_config["name"]

	if monster_config.has("type"):
		monster.type = monster_config["type"]
	monster.is_elite = is_elite

	monster.level = int(monster_config["level"])
	monster.exp = int(monster_config["exp"]) * ( 2 if is_elite else 1)

	var base_attr = AttributeDetails.new()
	base_attr.max_hp = int(monster_config["maxHP"]) * (2 if is_elite else 1)
	base_attr.max_mp = int(monster_config["maxMP"])
	base_attr.attack = int(monster_config["attack"])
	base_attr.defense = int(monster_config["defense"])
	if monster_config.has("magic"):
		base_attr.magic = int(monster_config["magic"])
	if monster_config.has("magic_def"):
		base_attr.magic_def = int(monster_config["magic_def"])
	base_attr.accuracy = int(monster_config["acc"])
	base_attr.evasion = int(monster_config["eva"])
	if monster_config.has("move_speed"):
		base_attr.move_speed = int(monster_config["move_speed"])
	else:
		base_attr.move_speed = 100
	monster.set_attribute(base_attr)

	return monster
	
