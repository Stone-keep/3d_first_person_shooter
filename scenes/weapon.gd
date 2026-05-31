extends Node3D

@onready var muzzleflash: Node3D = $MuzzleFlash
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var start_position := position
@onready var start_rotation := rotation

@export var weapon_name := "Weapon"
@export var damage := 1
@export var cooldown := 0.5
@export var continuous_shooting := false
@export var min_flash_size: float
@export var max_flash_size: float
@export var recoil_distance: Vector3
@export var recoil_rotation_degrees: float

var current_barrel := 0
var is_recoiling := false
var is_on_cooldown := false


func _ready() -> void:
	for sprite in muzzleflash.get_children():
		sprite.scale = Vector3.ZERO
		sprite.modulate = Color(1.437, 0.85, 0.31, randf_range(0.6, 0.8))
	cooldown_timer.wait_time = cooldown
	
func muzzle_flash():
	var num_barrels := muzzleflash.get_child_count()
	if not num_barrels:
		return
	var barrel_flash := muzzleflash.get_child(current_barrel)
	barrel_flash.modulate = Color(1.437, 0.85, 0.31, randf_range(0.6, 0.8))
	var flash_size := randf_range(min_flash_size, max_flash_size)
	var tween = create_tween()
	tween.tween_property(barrel_flash, "scale", Vector3(flash_size, flash_size, flash_size), 0.1).from(Vector3.ZERO)
	tween.tween_property(barrel_flash, "scale", Vector3.ZERO, 0.2)
	current_barrel = posmod(current_barrel + 1, num_barrels)

func recoil_animation():
	if not is_recoiling:
		is_recoiling = true
		var tween = create_tween()
		tween.set_parallel(true)

		tween.tween_property(self, "position", start_position + recoil_distance, 0.08)
		tween.tween_property(self, "rotation", start_rotation + Vector3(deg_to_rad(recoil_rotation_degrees), 0, 0), 0.08)
		
		tween.chain()

		tween.tween_property(self, "position", start_position, 0.15)
		tween.tween_property(self, "rotation", start_rotation, 0.15)

		await tween.finished
		is_recoiling = false

func _on_cooldown_timer_timeout() -> void:
	is_on_cooldown = false