extends CharacterBody3D

@onready var camera_yaw_pivot: Node3D = $CameraController/CameraYawPivot

const SPEED := 5.0
const FRICTION := 5.0
const JUMP_VELOCITY = 4.5
var direction := Vector3.ZERO

func _physics_process(delta: float) -> void:
	get_input()
	move(delta)
	jump(delta)
	move_and_slide()

func get_input() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	direction = (camera_yaw_pivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func move(delta: float) -> void:
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * FRICTION)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * FRICTION)

func jump(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta