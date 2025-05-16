'''
背包物品的基础类
'''
class_name DataBagItem

@export var id: String = ""
# 物品的唯一标识，作为掉落物存放在map时，需要一个uuid来区分
@export var uuid: String = ""
@export var name: String = ""

## 物品类型
##
# 类型枚举
const TYPE_EQUIP = "装备"
const TYPE_CONSUME = "消耗"
const TYPE_ETC = "其他"
const TYPE_MONEY = "金币"
# 当前类型
var type: String = ""

@export var count: int = 1
# 堆叠上限
var slot_max: int = 1
# 描述
var desc: String = ""
# 价格
var price: int = 0

## 在地图中存在时的相关属性
# 拾取权
var picker: DataPlayer
# 归属
var owner: DataPlayer

## 在背包中存在时的相关属性
# 是否被选中
var is_selected = false
# 是否会回收
var is_recycle = false

## 物品品质
##
# 品质枚举
const QUALITY_COMMON = "普通"
const QUALITY_GOOD = "优秀"
const QUALITY_RARE = "稀有"
const QUALITY_EPIC = "史诗"
# 当前品质
var quality: String = QUALITY_COMMON


func _init() -> void:
	self.uuid = RandomTool.random_num()


func is_empty() -> bool:
	return id == ""


func clear() -> void:
	id = ""
	name = ""
	count = 0


static func equip_name(item_id: String) -> String:
	var equip_str = "unknow"
	
	if item_id >= '01000000' and item_id <= '01040000':
		equip_str = "Cap"
	elif item_id >= '01050000' and item_id <= '01060000':
		equip_str = "Longcoat"
	elif item_id >= '01070000' and item_id <= '01079999':
		equip_str = "Shoes"
	elif item_id >= '01210000' and item_id <= '01720000':
		equip_str = "Weapon"
		
	return equip_str


# 保存需要额外存储的信息
# 这里将类中的信息分为两类：
# 1. 需要额外存储的信息，这些信息需要保存到持久化存储中
# 2. 可以通过资源配置获取的信息，不需要额外存储
func save() -> Dictionary:
	var dict = {}
	dict['id'] = id
	dict['uuid'] = uuid
	dict['name'] = name
	dict['count'] = count
	return dict


func load(dict: Dictionary) -> void:
	id = dict['id']
	uuid = dict['uuid']
	name = dict['name']
	count = dict['count']


# 子类重写
func copy() -> DataBagItem:
	return null


# 复制其他非额外存储属性
func copy_other_info(new_item: DataBagItem) -> void:
	new_item.type = self.type
	new_item.slot_max = self.slot_max
	new_item.desc = self.desc
	new_item.price = self.price
	new_item.quality = self.quality
	new_item.is_selected = self.is_selected
	new_item.is_recycle = self.is_recycle
