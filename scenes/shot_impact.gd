extends AnimatedSprite3D

var random_impact_offset = Vector3(
	randf_range(-0.2, 0.2),
	randf_range(-0.2, 0.2),
	randf_range(-0.2, 0.2)
	)

func _ready() -> void:
	var random_size_modifier = randf_range(-0.2, 0.2)
	scale += Vector3(random_size_modifier, random_size_modifier, random_size_modifier)
	modulate = Color(0.91, 0.9, 0.0, randf_range(0.6, 0.8))

func _on_animation_finished() -> void:
	call_deferred("queue_free")