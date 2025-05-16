class_name DataAttriBuffSkill extends DataBuffSkill

## 属性增益类Buff技能

# 能力值属性增益列表 Array[AttributeAbility] 根据技能等级确定具体增益
var ability_list: Array[AttributeAbility] = []

# 详情属性增益列表 Array[AttributeDetails] 根据技能等级确定具体增益
var details_list: Array[AttributeDetails] = []


func get_ability(level: int) -> AttributeAbility:
	return ability_list[level - 1]


func get_details(level: int) -> AttributeDetails:
	return details_list[level - 1]


func create_buff() -> DataBuff:
	var data_buff = super.create_buff()
	if ability_list.size() > 0:
		data_buff.attribute_ability = get_ability(level)
	if details_list.size() > 0:
		data_buff.attribute_details = get_details(level)
	return data_buff
