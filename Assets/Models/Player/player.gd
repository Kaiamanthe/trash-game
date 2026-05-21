extends CharacterBody3D

# Const
const SPEED = 5.0
const JUMP_VELOCITY = 6.5

#Signals
signal on_cast_started

# Ref
@onready var PoleAnimation = $Player_AnimationPlayer
@onready var FishingPole = $FishingPole
@onready var CameraPivot = $Camera_Pivot
@onready var Line = $FishingPole/Line
@onready var Bobber = $FishingPole/Bobber

var mouse_senitivity := 0.002

func _ready():
	# Locks and hide mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Connections
	on_cast_started.connect(FishingPole.on_cast_started)
	on_cast_started.connect(PoleAnimation.on_cast_started)
	
	# None key bind actions
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		# Left/Right
		rotate_y(-event.relative.x * mouse_senitivity)
		
		# Up/Down
		CameraPivot.rotate_x(-event.relative.y * mouse_senitivity)
		
		# Vert Bound
		CameraPivot.rotation.x = clamp(
			CameraPivot.rotation.x,
			deg_to_rad(-80),
			deg_to_rad(80)
		)

	# Key bind actions due to interactions with physics
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Cast
	if Input.is_action_just_pressed("int_cast"):
		_cast()

	# Test
	if Input.is_action_just_pressed("test_key"):
		print("Test key hit")
		Line._refresh_line()
		Bobber._reset_bobber_to_pole()
		

	# Get input and direction
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
