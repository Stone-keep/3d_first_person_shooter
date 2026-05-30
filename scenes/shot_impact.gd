extends AnimatedSprite3D

func _on_animation_finished() -> void:
	call_deferred("queue_free")