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
@onready var FishingMechanic: Node3D = $"../FishingMechanic"
@onready var Camera_Controller = $Camera_Pivot
@onready var Hand_Marker: Marker3D = $Camera_Pivot/Mark_Player_Hand
@onready var Camera: Camera3D = $Camera_Pivot/Camera3D
@onready var Mark_Line_End: Marker3D = $"../Bobber/Mark_LineEnd"

var state: PlayerState = PlayerState.roaming
var auto_reel := false

# Connects fishing, pole, bobber, camera, and input signals.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	on_cast_started.connect(Fishing_Pole.on_cast_started)
	on_cast_started.connect(Pole_Animation.on_cast_started)

	on_reel_started.connect(Fishing_Pole.on_reel_started)
	on_reel_started.connect(FishingMechanic.release_fish)

	fish_input_pressed.connect(FishingMechanic.on_player_fish_input)

	Bobber.fish_bite_signal.connect(FishingMechanic.start_fish_bite)
	FishingMechanic.fish_caught.connect(_on_fish_caught)
	FishingMechanic.fish_caught_reel.connect(fish_caught_reel)

	Camera_Controller.enter_free_mode()

# Passes mouse movement into the camera controller.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Camera_Controller.handle_mouse_motion(event)

# Runs player behavior based on roaming or fishing state.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_close"):
		get_tree().quit()

	match state:
		PlayerState.roaming:
			_roaming_state(delta)

		PlayerState.fishing:
			_fishing_state(delta)

	move_and_slide()

# Handles normal player movement and casting.
func _roaming_state(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()

	if Input.is_action_just_pressed("int_cast"):
		_enter_fishing_state()

# Handles fishing camera lock, fish input, and manual reel.
func _fishing_state(delta: float) -> void:
	_apply_gravity(delta)

	if not auto_reel:
		Camera_Controller.update_fishing_lock(delta, Mark_Line_End.global_position)

	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

	if not auto_reel:
		_handle_fish_input()

	if Input.is_action_just_pressed("int_reel"):
		_reel()

# Emits fish minigame inputs while fishing.
func _handle_fish_input() -> void:
	if Input.is_action_just_pressed("move_leftw"):
		fish_input_pressed.emit("move_leftw")

	if Input.is_action_just_pressed("move_rghtw"):
		fish_input_pressed.emit("move_rghtw")

	if Input.is_action_just_pressed("move_forw"):
		fish_input_pressed.emit("move_forw")

	if Input.is_action_just_pressed("move_bckw"):
		fish_input_pressed.emit("move_bckw")

# State to fishing
func _enter_fishing_state() -> void:
	state = PlayerState.fishing
	auto_reel = false
	Camera_Controller.enter_fishing_mode()
	_cast()

# State to roaming
func _exit_fishing_state() -> void:
	state = PlayerState.roaming
	auto_reel = false
	Camera_Controller.enter_free_mode()

func _cast() -> void:
	on_cast_started.emit()

# Manually reels in and exits fishing mode.
func _reel() -> void:
	if state != PlayerState.fishing:
		return

	on_reel_started.emit()
	_exit_fishing_state()

# Aurot reel when escape/catch-reel event.
func fish_caught_reel() -> void:
	if auto_reel:
		return

	auto_reel = true
	Camera_Controller.enter_free_mode()

	_reel()

# End fishing on caught.
func _on_fish_caught() -> void:
	auto_reel = true
	Camera_Controller.enter_free_mode()
	_exit_fishing_state()

# Incase other state such as swimming
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
