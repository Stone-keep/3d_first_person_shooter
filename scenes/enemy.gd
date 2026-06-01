extends CharacterBody3D

@export var min_flash_size: float
@export var max_flash_size: float
@export var number_of_barrels := 1
@export var damage := 1
@export var health := 20
@export var rotation_speed := 10.0

@onready var muzzleflash: Node3D = $Model/MuzzleFlash
@onready var shoot_timer: Timer = $ShootTimer
@onready var shoot_shape: ShapeCast3D = $ShootZone
@onready var model: Node3D = $Model

var enemy_name: String
var enemy_names := ["Robo", "Robo #2", "Robo #3"]

var player: CharacterBody3D

var current_barrel := 0
var is_dying := false

func _ready() -> void:
	for sprite in muzzleflash.get_children():
		sprite.scale = Vector3.ZERO
		sprite.modulate = Color(0.99, 0.0, 0.05, randf_range(0.6, 0.8))
	enemy_name = enemy_names.pick_random()

func _physics_process(delta: float) -> void:
	if not player or is_dying:
		return
	var target_dir = (player.enemy_target.global_position - global_position).normalized()
	var current_dir = -global_transform.basis.z
	var new_dir = current_dir.slerp(target_dir, rotation_speed * delta).normalized()
	look_at(global_transform.origin + new_dir, Vector3.UP)
	rotation.z = 0.0
	rotation.x = clamp(rotation.x, deg_to_rad(-45), deg_to_rad(45))

func get_hit(hit_damage: int):
	if is_dying:
		return
	flash()
	health -= hit_damage
	print(health)
	if health <= 0:
		die()

func shoot():
	muzzle_flash()
	shoot_shape.force_shapecast_update()
	if shoot_shape.is_colliding():
		var collider := shoot_shape.get_collider(0)
		
		if collider.is_in_group("player"):
			collider.get_hit(damage)

func muzzle_flash():
	var barrel_flash := muzzleflash.get_child(current_barrel)
	barrel_flash.modulate = Color(0.99, 0.0, 0.05, randf_range(0.6, 0.8))
	var flash_size := randf_range(min_flash_size, max_flash_size)
	var tween = create_tween()
	tween.tween_property(barrel_flash, "scale", Vector3(flash_size, flash_size, flash_size), 0.1).from(Vector3.ZERO)
	tween.tween_property(barrel_flash, "scale", Vector3.ZERO, 0.2)
	current_barrel = posmod(current_barrel + 1, number_of_barrels)

func flash():
	var tween = create_tween()
	tween.set_parallel(true)
	for mesh in model.get_children():
		if mesh is MeshInstance3D:
			tween.tween_property(mesh.material_overlay, "shader_parameter/Progress", 1.0, 0.1)
	tween.set_parallel(false)
	tween.tween_interval(0.1)
	tween.set_parallel(true)
	for mesh in model.get_children():
		if mesh is MeshInstance3D:
			tween.tween_property(mesh.material_overlay, "shader_parameter/Progress", 0.0, 0.1)
	

func die():
	player = null
	is_dying = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector3(0, -6, 0), 3.0)
	tween.tween_property(self, "rotation", rotation + Vector3(randf_range(TAU, 2 * TAU), randf_range(TAU, 2 * TAU), randf_range(TAU, 2 * TAU)), 3.0)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 1.0).set_delay(2.0)
	tween.chain()
	tween.tween_callback(queue_free)

func _on_detection_range_body_entered(body: CharacterBody3D) -> void:
	if body.is_in_group("player"):
		player = body
		shoot_timer.start()

func _on_detection_range_body_exited(body: CharacterBody3D) -> void:
	if body == player:
		player = null
		shoot_timer.stop()

func _on_shoot_timer_timeout() -> void:
	if player:
		shoot()