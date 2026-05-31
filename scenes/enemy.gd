extends CharacterBody3D

@export var min_flash_size: float
@export var max_flash_size: float
@export var number_of_barrels := 1
@export var damage := 1
@export var rotation_speed := 10.0

@onready var muzzleflash: Node3D = $Model/MuzzleFlash
@onready var shoot_timer: Timer = $ShootTimer
@onready var shoot_shape: ShapeCast3D = $ShootZone

var player: CharacterBody3D

var current_barrel := 0

func _ready() -> void:
	for sprite in muzzleflash.get_children():
		sprite.scale = Vector3.ZERO
		sprite.modulate = Color(0.99, 0.0, 0.05, randf_range(0.6, 0.8))

func _physics_process(delta: float) -> void:
	if player:
		var target_dir = (player.enemy_target.global_position - global_position).normalized()
		var current_dir = -global_transform.basis.z
		var new_dir = current_dir.slerp(target_dir, rotation_speed * delta).normalized()
		look_at(global_transform.origin + new_dir, Vector3.UP)
		rotation.z = 0.0
		rotation.x = clamp(rotation.x, deg_to_rad(-45), deg_to_rad(45))

func get_hit(hit_damage: int):
	print("Enemy hit for: " + str(hit_damage))

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