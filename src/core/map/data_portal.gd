class_name DataPortal

## 地图传送点
##
## 包含传送目标地图，传送目标地图的传送点ID
var portal_id = ""
var target_map_id = ""
var target_portal_id = ""

var target_map_name = ""

var disabled = false
# 传送点位置
var position = Vector2.ZERO

## 地图的深入条件
##
## 需要击杀当前地图怪物个数
var need_kill_monster_count: int = 0
