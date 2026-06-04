extends CharacterBody3D

@export var health: int
@export var min_damage: int
@export var max_damage: int
@export var min_flash_size: float
@export var max_flash_size: float
@export var number_of_barrels := 1
@export var rotation_speed := 10.0

@onready var muzzleflash: Node3D = $Model/MuzzleFlash
@onready var shoot_timer: Timer = $ShootTimer
@onready var shoot_shape: ShapeCast3D = $ShootZone
@onready var model: Node3D = $Model
@onready var shoot_sound_player: AudioStreamPlayer3D = $ShootSound

signal died(enemy: CharacterBody3D)

enum EnemyState {
	IDLE,
	ATTACKING,
	DYING
}

var state: EnemyState = EnemyState.IDLE
var player: CharacterBody3D
var starting_position: Vector3
var starting_rotation: Vector3
var max_health: int
var current_health: int

var enemy_names := [
	"Scrapjaw",
	"Boltface",
	"Clank",
	"Redcap",
	"Iron Grin",
	"Buzzbox",
	"Rivet",
	"Snarlbot",
	"Chrome Dome",
	"Angry Toaster"
]
var enemy_name: String

var current_barrel := 0

var idle_tween: Tween
var idle_start_id := 0

func _ready() -> void:
	for sprite in muzzleflash.get_children():
		sprite.scale = Vector3.ZERO
		sprite.modulate = Color(0.99, 0.0, 0.05, randf_range(0.6, 0.8))
	
	enemy_name = enemy_names.pick_random()
	max_health = health
	current_health = max_health
	starting_position = position
	starting_rotation = rotation_degrees

	enter_state(EnemyState.IDLE)

func _physics_process(delta: float) -> void:
	match state:
		EnemyState.IDLE:
			pass

		EnemyState.ATTACKING:
			if player:
				rotate_toward_player(delta)
			else:
				set_state(EnemyState.IDLE)
		
		EnemyState.DYING:
			pass

func set_state(new_state: EnemyState) -> void:
	if state == new_state:
		return
	
	exit_state(state)
	state = new_state
	enter_state(state)

func enter_state(new_state: EnemyState) -> void:
	match new_state:
		EnemyState.IDLE:
			start_idle_animation()

		EnemyState.ATTACKING:
			shoot_timer.start()

		EnemyState.DYING:
			player.enemies_killed += 1
			died.emit(self)
			player = null
			shoot_timer.stop()
			die_animation()

func exit_state(old_state: EnemyState) -> void:
	match old_state:
		EnemyState.IDLE:
			stop_idle_animation()

		EnemyState.ATTACKING:
			shoot_timer.stop()

		EnemyState.DYING:
			pass

func start_idle_animation() -> void:
	idle_start_id += 1
	var this_idle_id := idle_start_id

	var random_delay := randf_range(0.0, 2.5)
	var random_distance := randf_range(0.5, 0.8)
	var random_rotation := randf_range(25.0, 45.0)

	await get_tree().create_timer(random_delay).timeout

	if state != EnemyState.IDLE:
		return

	if this_idle_id != idle_start_id:
		return

	idle_tween = create_tween()
	idle_tween.set_loops()
	idle_tween.set_parallel(true)

	idle_tween.tween_property(self, "position:y", starting_position.y + random_distance, 3.0)
	idle_tween.tween_property(self, "rotation_degrees:y", starting_rotation.y + random_rotation, 3.0)

	idle_tween.chain()

	idle_tween.tween_property(self, "position:y", starting_position.y - random_distance, 3.0)
	idle_tween.tween_property(self, "rotation_degrees:y", starting_rotation.y - random_rotation, 3.0)
		
func stop_idle_animation() -> void:
	idle_start_id += 1

	if idle_tween:
		idle_tween.kill()
		idle_tween = null

func rotate_toward_player(delta: float) -> void:
	var target_dir = (player.enemy_target.global_position - global_position).normalized()
	var current_dir = -global_transform.basis.z
	var new_dir = current_dir.slerp(target_dir, rotation_speed * delta).normalized()
	look_at(global_transform.origin + new_dir, Vector3.UP)
	rotation.z = 0.0
	rotation.x = clamp(rotation.x, deg_to_rad(-45), deg_to_rad(45))

func get_hit(hit_damage: int) -> void:
	if state == EnemyState.DYING:
		return
	flash()
	current_health -= hit_damage
	if current_health <= 0:
		set_state(EnemyState.DYING)

func can_show_target_info() -> bool:
	return state != EnemyState.DYING

func get_target_info() -> Dictionary:
	return {
		"name": enemy_name,
		"current_health": current_health,
		"max_health": max_health
	}

func shoot() -> void:
	muzzle_flash()
	shoot_sound_player.play()
	shoot_shape.force_shapecast_update()
	if shoot_shape.is_colliding():
		var damage := randi_range(min_damage, max_damage)
		var collider := shoot_shape.get_collider(0)
		
		if collider.is_in_group("player"):
			collider.get_hit(damage)

func muzzle_flash() -> void:
	var barrel_flash := muzzleflash.get_child(current_barrel)
	barrel_flash.modulate = Color(0.99, 0.0, 0.05, randf_range(0.6, 0.8))
	var flash_size := randf_range(min_flash_size, max_flash_size)
	var tween = create_tween()
	tween.tween_property(barrel_flash, "scale", Vector3(flash_size, flash_size, flash_size), 0.1).from(Vector3.ZERO)
	tween.tween_property(barrel_flash, "scale", Vector3.ZERO, 0.2)
	current_barrel = posmod(current_barrel + 1, number_of_barrels)

func flash() -> void:
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

func die_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector3(0, -5, 0), 3.0)
	tween.tween_property(self, "rotation", rotation + Vector3(randf_range(TAU, 2 * TAU), randf_range(TAU, 2 * TAU), randf_range(TAU, 2 * TAU)), 3.0)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 1.0).set_delay(2.0)
	tween.chain()
	tween.tween_callback(queue_free)

func _on_detection_range_body_entered(body: CharacterBody3D) -> void:
	if state == EnemyState.DYING:
		return
	
	if body.is_in_group("player"):
		player = body
		set_state(EnemyState.ATTACKING)

func _on_detection_range_body_exited(body: CharacterBody3D) -> void:
	if body == player:
		player = null
		set_state(EnemyState.IDLE)

func _on_shoot_timer_timeout() -> void:
	if state != EnemyState.ATTACKING:
		return
	
	if not player:
		set_state(EnemyState.IDLE)
		return

	shoot()
