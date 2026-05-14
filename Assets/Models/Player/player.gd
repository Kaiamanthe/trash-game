extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5
@onready var PoleAnimation = $AnimationPlayer

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Cast
	if Input.is_action_just_pressed("interact_cast"):
		PoleAnimation.play("Cast_Pole")

	# Test
	if Input.is_action_just_pressed("test_key"):
		print("Test key hit")
		

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
