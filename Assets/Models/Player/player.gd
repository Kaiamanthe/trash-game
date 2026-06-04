extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5

signal on_cast_started

enum PlayerState {
	roaming,
	fishing
}

@onready var Pole_Animation = $Player_AnimationPlayer
@onready var Fishing_Pole = $"../FishingPole"
@onready var Camera_Pivot = $Camera_Pivot
@onready var Hand_Marker: Marker3D = $Camera_Pivot/Mark_Player_Hand

var state: PlayerState = PlayerState.roaming

var mouse_sensitivity := 0.002
var free_cam := false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	on_cast_started.connect(Fishing_Pole.on_cast_started)
	on_cast_started.connect(Pole_Animation.on_cast_started)


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion and not free_cam:
		rotate_y(-event.relative.x * mouse_sensitivity)

		Camera_Pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		Camera_Pivot.rotation.x = clamp(
			Camera_Pivot.rotation.x,
			deg_to_rad(-80),
			deg_to_rad(80)
		)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_close"):
		get_tree().quit()

	if Input.is_action_just_pressed("free_cam"):
		_toggle_free_cam()

	match state:
		PlayerState.roaming:
			_roaming_state(delta)

		PlayerState.fishing:
			_fishing_state(delta)

	move_and_slide()


func _roaming_state(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()

	if Input.is_action_just_pressed("int_cast"):
		_enter_fishing_state()


func _fishing_state(delta: float) -> void:
	_apply_gravity(delta)

	# Lock WASD
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

	# Tempt state exit
	if Input.is_action_just_pressed("int_cast"):
		_exit_fishing_state()


func _enter_fishing_state() -> void:
	state = PlayerState.fishing
	_cast()


func _exit_fishing_state() -> void:
	state = PlayerState.roaming


func _cast() -> void:
	on_cast_started.emit()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func _handle_movement() -> void:
	var input_dir := Input.get_vector("move_leftw", "move_rghtw", "move_forw", "move_bckw")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


func _toggle_free_cam() -> void:
	free_cam = !free_cam

	if free_cam:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
