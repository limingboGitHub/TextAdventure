class_name DataAlchemyBag

## 炼金配方背包

## 炼金配方信息
var alchemy_list: Array[DataAlchemy] = []

## 炼金配方的配置信息（从资源管理器注入） key: alchemy_id value: Dictionary
var alchemy_config_dic: Dictionary = {}
## 物品ID和名称的映射
var item_id_name_map: Dictionary = {}

signal alchemy_added(data_alchemy: DataAlchemy)


func init_config_dic(_alchemy_config_dic: Dictionary, _item_id_name_map: Dictionary):
	alchemy_config_dic = _alchemy_config_dic
	item_id_name_map = _item_id_name_map

	# 初始数据，从配置文件中获取物品名称
	for data_alchemy in alchemy_list:
		for require in data_alchemy.requires:
			require.item_name = item_id_name_map[require.item_id]



## 添加炼金配方
func add_alchemy(_alchemy_id: String):
	if not alchemy_list.has(_alchemy_id):
		var config_dic = alchemy_config_dic[_alchemy_id]

		var data_alchemy = DataAlchemy.new()
		data_alchemy.name = config_dic["name"]
		for require_dic in config_dic["requires"]:
			var require: MissionRequireCollect = MissionRequireCollect.new()
			require.item_id = require_dic["id"]
			require.target_count = require_dic["count"]
			data_alchemy.requires.append(require)
		for reward_dic in config_dic["rewards"]:
			var reward: MissionRewardItem = MissionRewardItem.new()
			reward.item_id = reward_dic["id"]
			reward.count = reward_dic["count"]
			data_alchemy.rewards.append(reward)

		# 加载消耗品信息
		for require in data_alchemy.requires:
			require.item_name = item_id_name_map[require.item_id]
		
		alchemy_list.append(data_alchemy)
		alchemy_added.emit(data_alchemy)


## 更新任务中的物品要求信息
func update_mission_require_collect(callback: Callable):
	for data_alchemy in alchemy_list:
		for require in data_alchemy.requires:
			require.update_collect_count(callback.call(require.item_id),true)


## 背包物品变化
func item_count_changed(item_id: String, item_count: int):
	for data_alchemy in alchemy_list:
		for require in data_alchemy.requires:
			if require.item_id == item_id:
				require.update_collect_count(item_count,true)


func save() -> Dictionary:
	var list: Array[Dictionary] = []
	for data_alchemy in alchemy_list:
		list.append(data_alchemy.save())
	return {
		"alchemy_list": list
	}


func load(_data: Dictionary) -> void:
	alchemy_list.clear()
	for data_alchemy_dic in _data["alchemy_list"]:
		var data_alchemy: DataAlchemy = DataAlchemy.new()
		data_alchemy.load(data_alchemy_dic)
		alchemy_list.append(data_alchemy)
