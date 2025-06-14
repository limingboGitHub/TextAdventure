class_name MonsterManager


# 对外接口 创建怪物
func create_monster(
	monster_id: String,
	is_elite: bool,
	monster_config: Dictionary,
	monster_skill_dic: Dictionary,
	effect_config: Dictionary
)-> DataMonster:
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

	# 怪物技能
	if monster_config.has("skills"):
		for monster_skill_id in monster_config["skills"]:
			var monster_skill_info = monster_skill_dic[monster_skill_id]
			var monster_skill = DataMonsterSkill.create_monster_skill(monster_skill_info)
			monster.add_monster_skill(monster_skill)
	# 注入配置信息
	monster.effect_config = effect_config

	if monster_config.has("attack_cd"):
		monster.execute_cd = float(monster_config["attack_cd"])
	if monster_config.has("ignore_rest"):
		monster.is_ignore_rest = monster_config["ignore_rest"]

	if monster_config.has("reset_status"):
		monster.reset_status = monster_config["reset_status"]

	return monster
	
