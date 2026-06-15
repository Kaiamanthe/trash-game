extends RigidBody3D

enum BobberState {
	home_pos,
	casting,
	in_water,
	on_land,
	hooked
}

signal fish_prox_change(prox_text: String, closest_hotspot: Area3D)
signal fish_bite_requested(difficulty_text: String, closest_hotspot: Area3D, bite_distance: float)

@onready var Mark_Line_Start: Marker3D = $"../FishingPole/Mark_LineStart"
@onready var Mark_Bobber_Home: Marker3D = $"../FishingPole/Mark_Bobber_Home"
@onready var Bobber_Area: Area3D = $Bobber_Area
@onready var Bobber_Mesh: Node3D = $Bobber_Mesh
@onready var Bobber_Area_Col = $Bobber_Area/Bobber_Area_Col
@onready var FishingZone: Node3D = $"../FishingZone"

var state: BobberState = BobberState.home_pos

var buoyancy_time := 0.0
var water_anchor_position := Vector3.ZERO

var bite_roll_timer := 0.0
var bite_roll_interval := 3.0
var bite_active := false

const _cast_force := 18.0
const _cast_up_force := 5.0
const _water_drag := 0.25
const _home_follow_speed := 8.0
const _home_rotation_speed := 10.0
const _water_settle_speed := 3.0
const _water_damping := 2.5
const _water_bob_speed := 2.0
const _water_bob_amount := 0.15

const _closest_dis := 5.0
const _closer_dis := 10.0
const _close_dis := 15.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

	body_entered.connect(_on_body_entered)

	Bobber_Area.monitoring = true
	Bobber_Area.monitorable = true
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
			_update_fish_heat()
			_process_bite_roll(delta)

		BobberState.on_land:
			pass

		BobberState.hooked:
			pass

func on_pole_ready() -> void:
	state = BobberState.home_pos

	freeze = true
	set_physics_process(true)

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	bite_roll_timer = 0.0
	bite_active = false

	Bobber_Area_Col.reset_hotspots()
	Bobber_Area_Col.hide_fish_ui()

	Bobber_Mesh.visible = true

	global_position = Mark_Bobber_Home.global_position
	global_rotation = Mark_Bobber_Home.global_rotation

func on_cast() -> void:
	state = BobberState.casting

	freeze = false

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	bite_roll_timer = 0.0
	bite_active = false

	Bobber_Area_Col.reset_hotspots()
	Bobber_Area_Col.hide_fish_ui()

	Bobber_Mesh.visible = true

	global_position = Mark_Line_Start.global_position

	var cast_direction := -Mark_Line_Start.global_basis.z.normalized()

	linear_velocity = (
		cast_direction * _cast_force
		+ Vector3.UP * _cast_up_force
	)

func start_hooked_mode() -> void:
	state = BobberState.hooked

	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	bite_active = true
	Bobber_Mesh.visible = false

	print("Bobber entered hooked mode.")

func end_hooked_mode() -> void:
	Bobber_Mesh.visible = true
	Bobber_Area_Col.hide_fish_ui()
	on_pole_ready()

func set_hooked_position(new_position: Vector3) -> void:
	if state != BobberState.hooked:
		return

	global_position = new_position

func _follow_home_pos(delta: float) -> void:
	var current_basis := global_basis.orthonormalized()
	var target_basis := Mark_Bobber_Home.global_basis.orthonormalized()

	global_position = global_position.lerp(
		Mark_Bobber_Home.global_position,
		delta * _home_follow_speed
	)

	global_basis = current_basis.slerp(
		target_basis,
		delta * _home_rotation_speed
	).orthonormalized()

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

func _process_bite_roll(delta: float) -> void:
	if bite_active:
		return

	if not _is_inside_fishing_zone():
		bite_roll_timer = 0.0
		return

	var closest_hotspot: Area3D = Bobber_Area_Col.get_closest_hotspot()

	if closest_hotspot == null:
		bite_roll_timer = 0.0
		return

	bite_roll_timer += delta

	if bite_roll_timer < bite_roll_interval:
		return

	bite_roll_timer = 0.0

	var distance: float = Bobber_Area_Col.get_distance_to_closest_hotspot()

	Bobber_Area_Col.play_bite_check_visual()

	_try_bite(distance, closest_hotspot)

func _on_body_entered(body) -> void:
	if state != BobberState.casting:
		return

	if _is_on_layer(body, sheets_globals.terrain_layer):
		_land_on_terrain()
		return

func _on_area_entered(area: Area3D) -> void:
	if state == BobberState.casting:
		if _is_on_layer(area, sheets_globals.water_layer):
			print("Bobber entered water area.")
			_enter_water()
			return

func _update_fish_heat() -> void:
	if not _is_inside_fishing_zone():
		Bobber_Area_Col.hide_fish_ui()
		fish_prox_change.emit("Cold", null)
		return

	Bobber_Area_Col.refresh_nearby_hotspots()

	var closest_hotspot: Area3D = Bobber_Area_Col.get_closest_hotspot()

	if closest_hotspot == null:
		Bobber_Area_Col.set_proximity_visual("Cold")
		fish_prox_change.emit("Cold", null)
		return

	var distance: float = Bobber_Area_Col.get_distance_to_closest_hotspot()

	if distance <= _closest_dis:
		Bobber_Area_Col.set_proximity_visual("Closest")
		fish_prox_change.emit("Closest", closest_hotspot)
	elif distance <= _closer_dis:
		Bobber_Area_Col.set_proximity_visual("Closer")
		fish_prox_change.emit("Closer", closest_hotspot)
	elif distance <= _close_dis:
		Bobber_Area_Col.set_proximity_visual("Close")
		fish_prox_change.emit("Close", closest_hotspot)
	else:
		Bobber_Area_Col.set_proximity_visual("Cold")
		fish_prox_change.emit("Cold", closest_hotspot)

func _try_bite(distance: float, closest_hotspot: Area3D) -> void:
	var bite_chance := 0.0

	if distance <= _closest_dis:
		bite_chance = 0.80
	elif distance <= _closer_dis:
		bite_chance = 0.50
	elif distance <= _close_dis:
		bite_chance = 0.25
	else:
		return

	var bite_roll := randf()
	print("Bite roll: ", bite_roll, " | needed <= ", bite_chance)

	if bite_roll > bite_chance:
		print("No bite.")
		return

	bite_active = true

	print("Fish bite! Distance from hotspot: ", distance)
	fish_bite_requested.emit("", closest_hotspot, distance)

func _enter_water() -> void:
	state = BobberState.in_water

	freeze = true
	buoyancy_time = 0.0

	water_anchor_position = global_position
	water_anchor_position.y = sheets_globals.water_level

	linear_velocity *= _water_drag

	print("Bobber is now in water.")
	_update_fish_heat()

func _land_on_terrain() -> void:
	state = BobberState.on_land

	freeze = true

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	Bobber_Area_Col.hide_fish_ui()

	print("Bobber landed on terrain.")

func _is_inside_fishing_zone() -> bool:
	if FishingZone == null:
		return false

	if not FishingZone.has_method("is_point_inside_any_zone"):
		return false

	return FishingZone.is_point_inside_any_zone(global_position)

func _is_on_layer(collision_object, layer_number: int) -> bool:
	if collision_object == null:
		return false

	if not "collision_layer" in collision_object:
		return false

	return collision_object.collision_layer & (1 << (layer_number - 1)) != 0
