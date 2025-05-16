extends Label

# toast场景

var dead_time = 4.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	dead_time -= delta
	if dead_time < 0:
		queue_free()
