class_name DataEtc extends DataBagItem

## 背包物品的其他类

func _init() -> void:
	super._init()
	type = TYPE_ETC


static func is_etc(_id: String) -> bool:
	return _id.begins_with("etc")


func copy() -> DataEtc:
	var dic = save()
	var new_item = DataEtc.new()
	new_item.load(dic)
	# 物品的uuid需要重新生成
	new_item.uuid = RandomTool.random_num()
	return new_item
