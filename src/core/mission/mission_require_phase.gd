class_name MissionRequirePhase extends MissionRequire

## 要求完成某一个任务阶段

var phase: DataMissionPhase

func is_can_finish() -> bool:
	return phase.is_finish()

