extends StaticBody3D

@onready var platform: MeshInstance3D = $"platform-large-grass2"

var grass_meshes = [
	preload("res://models/grass.glb"),
	preload("res://models/grass-small.glb")
]

func _ready() -> void:
	var grass_amount := randi_range(40, 60)
	var aabb := platform.get_aabb()

	var usable_percent := 0.8
	var inset_x := aabb.size.x * (1.0 - usable_percent) * 0.5
	var inset_z := aabb.size.z * (1.0 - usable_percent) * 0.5

	var min_x := aabb.position.x + inset_x
	var max_x := aabb.position.x + aabb.size.x - inset_x
	var min_z := aabb.position.z + inset_z
	var max_z := aabb.position.z + aabb.size.z - inset_z

	for i in range(grass_amount):
		var grass_scene: PackedScene = grass_meshes.pick_random()
		var grass := grass_scene.instantiate()
		add_child(grass)

		var local_x := randf_range(min_x, max_x)
		var local_z := randf_range(min_z, max_z)
		var local_y := aabb.position.y + aabb.size.y

		grass.global_position = platform.to_global(Vector3(local_x, local_y, local_z))
		grass.rotation.y = randf_range(0.0, TAU)

		var s := randf_range(0.8, 1.15)
		grass.scale = Vector3(0.3, 0.3, 0.3) * s
