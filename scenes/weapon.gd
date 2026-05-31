extends Node3D

@onready var muzzleflash: Node3D = $MuzzleFlash

@export var weapon_name := "Weapon"
@export var number_of_barrels := 1
@export var min_flash_size: float
@export var max_flash_size: float

var current_barrel := 1

func _ready() -> void:
	for i in range(number_of_barrels):
		muzzleflash.get_child(i).scale = Vector3.ZERO
		muzzleflash.get_child(i).modulate = Color(1.437, 0.85, 0.31, randf_range(0.6, 0.8))
	
func muzzle_flash():
	var flash_size := randf_range(min_flash_size, max_flash_size)
	var tween = create_tween()
	tween.tween_property(muzzleflash.get_child(current_barrel-1), "scale", Vector3(flash_size, flash_size, flash_size), 0.1).from(Vector3.ZERO)
	tween.tween_property(muzzleflash.get_child(current_barrel-1), "scale", Vector3.ZERO, 0.2)
	current_barrel = (current_barrel % number_of_barrels) + 1
