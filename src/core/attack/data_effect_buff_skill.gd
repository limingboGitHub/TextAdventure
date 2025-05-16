class_name DataEffectBuffSkill extends DataBuffSkill

## 特殊机制类Buff技能

## 特殊机制类型
## 类型见@see DataEffect
var effect_list: Array[DataEffect] = []


func get_effect(level: int) -> DataEffect:
	return effect_list[level - 1]


func create_buff() -> DataBuff:
	var data_buff = super.create_buff()
	if effect_list.size() > 0:
		data_buff.add_effect(get_effect(level))
	return data_buff
