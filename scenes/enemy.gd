extends CharacterBody3D

@export var min_flash_size: float
@export var max_flash_size: float
@export var number_of_barrels := 1

@onready var muzzleflash: Node3D = $MuzzleFlash
@onready var shoot_timer = $ShootTimer

var player: CharacterBody3D

var current_barrel := 0

func _ready() -> void:
	for sprite in muzzleflash.get_children():
		sprite.scale = Vector3.ZERO
		sprite.modulate = Color(1.437, 0.85, 0.31, randf_range(0.6, 0.8))

func get_hit(damage: int):
	print(damage)

func shoot():
	var barrel_flash := muzzleflash.get_child(current_barrel)
	barrel_flash.modulate = Color(1.437, 0.85, 0.31, randf_range(0.6, 0.8))
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

func _on_shoot_timer_timeout() -> void:
	shoot()