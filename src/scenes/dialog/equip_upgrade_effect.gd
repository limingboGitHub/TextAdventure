extends Path2D

var upgrade_level: int = 0

func _ready():
	#set_upgrade_level(3)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 根据当前时间戳计算进度
	var time: int = Time.get_ticks_msec()
	$PathFollow2D.progress_ratio = (time % 3000) / 3000.0


func set_upgrade_level(_upgrade_level: int) -> void:
	if _upgrade_level == 0 or _upgrade_level > 3 or _upgrade_level == self.upgrade_level:
		return
	self.upgrade_level = _upgrade_level
	var process_material: ParticleProcessMaterial = \
		load("res://theme/process_material/equip_upgrade_effect" + str(_upgrade_level) + ".tres")
	$PathFollow2D/GPUParticles2D.process_material = process_material
