extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5

signal on_cast_started

@onready var pole_animation = $Player_AnimationPlayer
@onready var fishing_pole = $"../FishingPole"
@onready var camera_pivot = $Camera_Pivot
@onready var hand_marker: Marker3D = $Camera_Pivot/Mark_Player_Hand

var mouse_sensitivity := 0.002

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	on_cast_started.connect(fishing_pole.on_cast_started)
	on_cast_started.connect(pole_animation.on_cast_started)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(-80),
			deg_to_rad(80)
		)

func get_hand_marker() -> Marker3D:
	return hand_marker

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("int_cast"):
		_cast()

	var input_dir := Input.get_vector("move_leftw", "move_rghtw", "move_forw", "move_bckw")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _cast():
	on_cast_started.emit()
