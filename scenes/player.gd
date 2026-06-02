extends CharacterBody3D

@export var shot_impact_scene: PackedScene

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var shoot_raycast: RayCast3D = $Head/Camera3D/ShootRay
@onready var weapons: Node3D = $Head/Camera3D/Weapons
@onready var enemy_target: Marker3D = $EnemyTarget
@onready var sounds: Node3D = $Sounds

# Camera Movement
var mouse_sensitivity := 0.002
var joystick_horizontal_sensitivity := 2.5
var joystick_vertical_sensitivity := 1.5
var min_pitch := -1.4
var max_pitch := 1.4

# Movement
const WALK_SPEED := 3.0
const RUN_SPEED := 6.0
const FRICTION := 8.0
var direction := Vector3.ZERO
var is_running := false

# Jumping & Falling
const JUMP_VELOCITY = 5.0
var current_jump := 0
var max_jumps := 2
var gravity_modifier := 0.7

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
var current_weapon_node: Node3D
var is_swapping_weapons := false
signal ammo_changed(current_ammo: int, max_ammo: int)
signal weapon_reload(max_ammo: int, time: float)

# Health
var max_health := 50
var current_health: int
signal health_changed(hp_current: int, hp_max: int)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for weapon in weapons.get_children():
		weapon.hide()
	weapons.get_child(current_weapon).show()
	current_weapon_node = weapons.get_child(current_weapon)
	current_health = max_health

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

	if current_weapon_node.continuous_shooting:
		if Input.is_action_pressed("primary_fire"):
			shoot()
	else:
		if Input.is_action_just_pressed("primary_fire"):
			shoot()
	if Input.is_action_just_pressed("toggle_weapon") and not is_swapping_weapons:
		swap_weapons()
	
	if Input.is_action_pressed("run") and !is_running:
		is_running = true
	elif Input.is_action_just_released("run"):
		is_running = false

	if Input.is_action_just_pressed("reload") and current_weapon_node.current_ammo < current_weapon_node.max_ammo:
		reload()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_from_vector(event.relative * mouse_sensitivity)

func move(delta: float) -> void:
	if direction and is_running:
		velocity.x = direction.x * RUN_SPEED
		velocity.z = direction.z * RUN_SPEED
		if is_on_floor():
			sounds.play_run_sound()
		else:
			sounds.stop_walk_and_run_sound()
	elif direction and not is_running:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
		if is_on_floor():
			sounds.play_walk_sound()
		else:
			sounds.stop_walk_and_run_sound()
	else:
		velocity.x = move_toward(velocity.x, 0, RUN_SPEED * delta * FRICTION)
		velocity.z = move_toward(velocity.z, 0, RUN_SPEED * delta * FRICTION)
		sounds.stop_walk_and_run_sound()

func jump_and_fall(delta: float) -> void:
	if current_jump > 0 and is_on_floor():
		current_jump = 0
	if Input.is_action_just_pressed("jump") and current_jump < max_jumps:
		current_jump += 1
		velocity.y = JUMP_VELOCITY
		sounds.play_jump_sound()
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_modifier

func rotate_from_vector(v: Vector2):
	if v.length() > 0:
		rotation.y -= v.x
		head.rotation.x -= v.y
		head.rotation.x = clamp(head.rotation.x, min_pitch, max_pitch)

func check_for_target() -> Object:
	return shoot_raycast.get_collider()

func shoot() -> void:
	if is_swapping_weapons or current_weapon_node.is_on_cooldown or current_weapon_node.is_reloading:
		return
	
	current_weapon_node.is_on_cooldown = true
	current_weapon_node.cooldown_timer.start()
	current_weapon_node.play_shoot_sound()
	current_weapon_node.recoil_animation()
	current_weapon_node.muzzle_flash()
	var target = check_for_target()
	if target and target.is_in_group("enemies"):
		var impact_position = shoot_raycast.get_collision_point()
		hit_enemy(target, impact_position, current_weapon_node.damage)

	current_weapon_node.current_ammo -= 1
	ammo_changed.emit(current_weapon_node.current_ammo, current_weapon_node.max_ammo)
	if current_weapon_node.current_ammo <= 0:
		reload()

func reload() -> void:
	if current_weapon_node.is_reloading:
		return
	current_weapon_node.is_reloading = true
	weapon_reload.emit(current_weapon_node.max_ammo, current_weapon_node.reload_time)
	await get_tree().create_timer(current_weapon_node.reload_time).timeout
	current_weapon_node.reload()

func continuous_shoot() -> void:
	shoot()

func swap_weapons() -> void:
	if current_weapon_node.is_reloading:
		return
	is_swapping_weapons = true
	current_weapon = posmod(current_weapon + 1, Weapon.size()) as Weapon
	current_weapon_node = weapons.get_child(current_weapon)
	var tween = create_tween()
	tween.tween_property(weapons, "position", weapon_start_position + Vector3(0, -1.2, 0), 0.2)
	tween.tween_callback(sounds.play_change_weapon_sound)
	tween.tween_callback(weapons.get_child(current_weapon).show)
	tween.tween_callback(weapons.get_child(previous_weapon).hide)
	ammo_changed.emit(current_weapon_node.current_ammo, current_weapon_node.max_ammo)
	tween.tween_property(weapons, "position", weapon_start_position, 0.2)

	await tween.finished
	is_swapping_weapons = false

func hit_enemy(enemy: CharacterBody3D, impact_position: Vector3, hit_damage: int):
	var shot_impact = shot_impact_scene.instantiate()
	get_tree().root.add_child(shot_impact)
	shot_impact.global_position = impact_position + shot_impact.random_impact_offset
	shot_impact.look_at(camera.global_transform.origin)
	enemy.get_hit(hit_damage)

func get_hit(hit_damage: int):
	current_health -= hit_damage
	health_changed.emit(current_health, max_health)
	print("Player hit for: " + str(hit_damage))
	if current_health <= 0:
		die()

func heal_up(amount: int):
	current_health += amount
	health_changed.emit(current_health, max_health)
	print("Player health: %s/%s" % [current_health, max_health])

func die():
	print("player dead")
