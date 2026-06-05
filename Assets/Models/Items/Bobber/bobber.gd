extends RigidBody3D

enum BobberState {
	home_pos,
	casting,
	in_water,
	on_land
}

@onready var Mark_Line_Start: Marker3D = $"../FishingPole/Mark_LineStart"
@onready var Mark_Bobber_Home: Marker3D = $"../FishingPole/Mark_Bobber_Home"
@onready var Bobber_Area: Area3D = $Bobber_Area

var state: BobberState = BobberState.home_pos

var buoyancy_time := 0.0
var water_anchor_position := Vector3.ZERO

const _cast_force := 18.0
const _cast_up_force := 5.0
const _water_drag := 0.25
const _home_follow_speed := 8.0
const _home_rotation_speed := 10.0
const _water_settle_speed := 3.0
const _water_damping := 2.5
const _water_bob_speed := 2.0
const _water_bob_amount := 0.15

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

	body_entered.connect(_on_body_entered)
	Bobber_Area.area_entered.connect(_on_area_entered)

	on_pole_ready()

func _physics_process(delta: float) -> void:
	match state:
		BobberState.home_pos:
			_follow_home_pos(delta)

		BobberState.casting:
			pass

		BobberState.in_water:
			_float_in_water(delta)

		BobberState.on_land:
			pass

func on_pole_ready() -> void:
	state = BobberState.home_pos

	freeze = true
	set_physics_process(true)

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	global_position = Mark_Bobber_Home.global_position
	global_rotation = Mark_Bobber_Home.global_rotation

func on_cast() -> void:
	state = BobberState.casting

	freeze = false

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	global_position = Mark_Line_Start.global_position

	var cast_direction := -Mark_Line_Start.global_basis.z.normalized()

	linear_velocity = (
		cast_direction * _cast_force
		+ Vector3.UP * _cast_up_force
	)

func _follow_home_pos(delta: float) -> void:
	global_position = global_position.lerp(
		Mark_Bobber_Home.global_position,
		delta * _home_follow_speed
	)

	global_basis = global_basis.slerp(
		Mark_Bobber_Home.global_basis,
		delta * _home_rotation_speed
	)

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _float_in_water(delta: float) -> void:
	buoyancy_time += delta

	var target_position := water_anchor_position
	target_position.y = (
		sheets_globals.water_level
		+ sin(buoyancy_time * _water_bob_speed) * _water_bob_amount
	)

	global_position = global_position.lerp(
		target_position,
		delta * _water_settle_speed
	)

	linear_velocity = linear_velocity.lerp(
		Vector3.ZERO,
		delta * _water_damping
	)

	linear_velocity.y = 0.0

func _on_body_entered(body) -> void:
	if state != BobberState.casting:
		return

	if _is_on_layer(body, sheets_globals.terrain_layer):
		_land_on_terrain()
		return

func _on_area_entered(area: Area3D) -> void:
	if state != BobberState.casting:
		return

	if _is_on_layer(area, sheets_globals.water_layer):
		_enter_water()
		return

func _enter_water() -> void:
	state = BobberState.in_water

	freeze = true
	buoyancy_time = 0.0

	water_anchor_position = global_position
	water_anchor_position.y = sheets_globals.water_level

	linear_velocity *= _water_drag

func _land_on_terrain() -> void:
	state = BobberState.on_land

	freeze = true

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _is_on_layer(collision_object, layer_number: int) -> bool:
	if collision_object == null:
		return false

	if not "collision_layer" in collision_object:
		return false

	return collision_object.collision_layer & (1 << (layer_number - 1)) != 0
