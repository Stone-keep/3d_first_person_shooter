extends StaticBody3D


func _process(delta: float) -> void:
	rotate_z(0.3 * delta)