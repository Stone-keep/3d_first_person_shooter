extends CharacterBody3D

@export var shot_impact_scene: PackedScene

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D

@onready var weapons: Node3D = $Head/Camera3D/Weapons

# Camera Movement

var mouse_sensitivity := 0.002
var joystick_horizontal_sensitivity := 2.5
var joystick_vertical_sensitivity := 1.5
var min_pitch := -1.5
var max_pitch := 1.5

# Movement
const SPEED := 5.0
const FRICTION := 8.0
const JUMP_VELOCITY = 5.0
var direction := Vector3.ZERO

# Weapons & Shooting
enum Weapon {BLASTER, DUAL_SHOOTER}
@onready var weapon_start_position := weapons.position
var previous_weapon: Weapon = Weapon.BLASTER
var current_weapon: Weapon:
	set(value):
		if current_weapon == value:
			return
		previous_weapon = current_weapon
		current_weapon = value
		swap_weapons()

var is_swapping_weapons := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for weapon in weapons.get_children():
		weapon.hide()
	weapons.get_child(current_weapon).show()

func _physics_process(delta: float) -> void:
	get_input(delta)
	move(delta)
	jump_and_fall(delta)
	move_and_slide()

func get_input(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	direction = (basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var joystick_dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	rotate_from_vector(joystick_dir * Vector2(joystick_horizontal_sensitivity, joystick_vertical_sensitivity) * delta)

	if Input.is_action_just_pressed("primary_fire"):
		shoot()

	if Input.is_action_just_pressed("toggle_weapon") and not is_swapping_weapons:
		current_weapon = posmod(current_weapon + 1, Weapon.size()) as Weapon

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_from_vector(event.relative * mouse_sensitivity)

func move(delta: float) -> void:
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * FRICTION)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * FRICTION)

func jump_and_fall(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if not is_on_floor():
		velocity += get_gravity() * delta

func rotate_from_vector(v: Vector2):
	if v.length() > 0:
		rotation.y -= v.x
		head.rotation.x -= v.y
		head.rotation.x = clamp(head.rotation.x, min_pitch, max_pitch)

func check_for_target() -> Object:
	return raycast.get_collider()

func shoot() -> void:
	if not is_swapping_weapons:
		var weapon = weapons.get_child(current_weapon)
		weapon.muzzle_flash()
		var target = check_for_target()
		if target and target.is_in_group("enemies"):
			var impact_position = raycast.get_collision_point()
			hit_enemy(target, impact_position, weapon.damage)

func hit_enemy(enemy: CharacterBody3D, impact_position: Vector3, damage: int):
	var shot_impact = shot_impact_scene.instantiate()
	get_tree().root.add_child(shot_impact)
	shot_impact.global_position = impact_position + shot_impact.random_impact_offset
	shot_impact.look_at(camera.global_transform.origin)
	enemy.get_hit(damage)

func swap_weapons() -> void:
	is_swapping_weapons = true
	var tween = create_tween()
	tween.tween_property(weapons, "position", weapon_start_position + Vector3(0, -1.2, 0), 0.2)
	tween.tween_callback(weapons.get_child(current_weapon).show)
	tween.tween_callback(weapons.get_child(previous_weapon).hide)
	tween.tween_property(weapons, "position", weapon_start_position, 0.2)

	await tween.finished
	is_swapping_weapons = false
