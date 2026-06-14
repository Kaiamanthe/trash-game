extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5

signal on_cast_started
signal on_reel_started
signal fish_input_pressed(action_name: String)

enum PlayerState {
	roaming,
	fishing
}

@onready var Pole_Animation = $Player_AnimationPlayer
@onready var Fishing_Pole = $"../FishingPole"
@onready var Bobber: RigidBody3D = $"../Bobber"
@onready var FishHooked: Node3D = $"../FishHooked"
@onready var Camera_Pivot = $Camera_Pivot
@onready var Hand_Marker: Marker3D = $Camera_Pivot/Mark_Player_Hand
@onready var Camera: Camera3D = $Camera_Pivot/Camera3D
@onready var Mark_Line_End: Marker3D = $"../Bobber/Mark_LineEnd"

var state: PlayerState = PlayerState.roaming

var mouse_sensitivity := 0.002
var free_cam := true

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	on_cast_started.connect(Fishing_Pole.on_cast_started)
	on_cast_started.connect(Pole_Animation.on_cast_started)

	on_reel_started.connect(Fishing_Pole.on_reel_started)
	on_reel_started.connect(FishHooked.release_fish)

	fish_input_pressed.connect(FishHooked.on_player_fish_input)

	Bobber.fish_bite_requested.connect(FishHooked.start_fish_bite)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion and free_cam:
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
	_free_cam_off()

	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

	_handle_fish_input()

	if Input.is_action_just_pressed("int_reel"):
		_reel()

func _handle_fish_input() -> void:
	if Input.is_action_just_pressed("move_leftw"):
		fish_input_pressed.emit("move_leftw")

	if Input.is_action_just_pressed("move_rghtw"):
		fish_input_pressed.emit("move_rghtw")

	if Input.is_action_just_pressed("move_forw"):
		fish_input_pressed.emit("move_forw")

	if Input.is_action_just_pressed("move_bckw"):
		fish_input_pressed.emit("move_bckw")

func _enter_fishing_state() -> void:
	state = PlayerState.fishing
	_cast()

func _exit_fishing_state() -> void:
	state = PlayerState.roaming
	free_cam = true

func _cast() -> void:
	on_cast_started.emit()

func _reel() -> void:
	on_reel_started.emit()
	_exit_fishing_state()

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

func _free_cam_off() -> void:
	free_cam = false

	var look_target := Mark_Line_End.global_position
	look_target.y = global_position.y

	var direction := look_target - global_position

	if direction.length() <= 0.01:
		return

	var target_basis := Transform3D().looking_at(direction.normalized(), Vector3.UP).basis

	global_basis = global_basis.orthonormalized().slerp(
		target_basis.orthonormalized(),
		0.15
	).orthonormalized()

	Camera_Pivot.rotation.x = lerp(Camera_Pivot.rotation.x, 0.0, 0.15)
