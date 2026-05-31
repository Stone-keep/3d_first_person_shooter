extends Node3D

@onready var muzzleflash: Node3D = $MuzzleFlash

@export var weapon_name := "Weapon"
@export var number_of_barrels := 1
@export var min_flash_size: float
@export var max_flash_size: float
@export var damage: int

var current_barrel := 0

func _ready() -> void:
	for sprite in muzzleflash.get_children():
		sprite.scale = Vector3.ZERO
		sprite.modulate = Color(1.437, 0.85, 0.31, randf_range(0.6, 0.8))
	
func muzzle_flash():
	if number_of_barrels > 0:
		var barrel_flash := muzzleflash.get_child(current_barrel)
		var flash_size := randf_range(min_flash_size, max_flash_size)
		var tween = create_tween()
		tween.tween_property(barrel_flash, "scale", Vector3(flash_size, flash_size, flash_size), 0.1).from(Vector3.ZERO)
		tween.tween_property(barrel_flash, "scale", Vector3.ZERO, 0.2)
		current_barrel = posmod(current_barrel + 1, number_of_barrels)