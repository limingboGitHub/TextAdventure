extends GPUParticles2D


func play_effect():
	emitting = true
	finished.connect(queue_free)
