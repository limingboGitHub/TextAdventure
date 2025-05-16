class_name DataAlchemy

## 炼金配方

var name: String = ""

# 配方要求
var requires: Array[MissionRequireCollect] = []

# 配方奖励
var rewards: Array[MissionRewardItem] = []


func save() -> Dictionary:
	var data: Dictionary = {}
	data["name"] = name
	data["requires"] = []
	data["rewards"] = []
	for require in requires:
		data["requires"].append(require.save())
	for reward in rewards:
		data["rewards"].append(reward.save())
	return data


func load(_data: Dictionary) -> void:
	requires.clear()
	rewards.clear()
	name = _data["name"]
	for require_dic in _data["requires"]:
		var require: MissionRequireCollect = MissionRequireCollect.new()
		require.load(require_dic)
		requires.append(require)
	for reward_dic in _data["rewards"]:
		var reward: MissionRewardItem = MissionRewardItem.new()
		reward.load(reward_dic)
		rewards.append(reward)
