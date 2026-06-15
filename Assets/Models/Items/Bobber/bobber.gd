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

var state: BobberState = BobberState.home_pos

var buoyancy_time := 0.0
var water_anchor_position := Vector3.ZERO

var nearby_hotspots: Array[Area3D] = []
var closest_hotspot: Area3D = null

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
	Bobber_Area.area_exited.connect(_on_bobber_area_exited)

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

	nearby_hotspots.clear()
	closest_hotspot = null

	bite_roll_timer = 0.0
	bite_active = false

	Bobber_Mesh.visible = true

	global_position = Mark_Bobber_Home.global_position
	global_rotation = Mark_Bobber_Home.global_rotation

func on_cast() -> void:
	state = BobberState.casting

	freeze = false

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	nearby_hotspots.clear()
	closest_hotspot = null

	bite_roll_timer = 0.0
	bite_active = false

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

	if closest_hotspot == null:
		bite_roll_timer = 0.0
		return

	bite_roll_timer += delta

	if bite_roll_timer < bite_roll_interval:
		return

	bite_roll_timer = 0.0

	var distance := global_position.distance_to(closest_hotspot.global_position)
	_try_bite(distance)

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

	if _is_fish_hotspot(area):
		if not nearby_hotspots.has(area):
			nearby_hotspots.append(area)

		if state == BobberState.in_water:
			_update_fish_heat()

func _on_bobber_area_exited(area: Area3D) -> void:
	if _is_fish_hotspot(area):
		nearby_hotspots.erase(area)

		if closest_hotspot == area:
			closest_hotspot = null

		if state == BobberState.in_water:
			_update_fish_heat()

func _update_fish_heat() -> void:
	_refresh_nearby_hotspots()

	closest_hotspot = _get_closest_hotspot()

	if closest_hotspot == null:
		fish_prox_change.emit("Cold", null)
		return

	var distance := global_position.distance_to(closest_hotspot.global_position)

	if distance <= _closest_dis:
		fish_prox_change.emit("Closest", closest_hotspot)
		print("Fish indicator: Closest | closest: ", closest_hotspot.name, " | distance: ", distance)
	elif distance <= _closer_dis:
		fish_prox_change.emit("Closer", closest_hotspot)
		print("Fish indicator: Closer | closest: ", closest_hotspot.name, " | distance: ", distance)
	elif distance <= _close_dis:
		fish_prox_change.emit("Close", closest_hotspot)
		print("Fish indicator: Close | closest: ", closest_hotspot.name, " | distance: ", distance)
	else:
		fish_prox_change.emit("Cold", closest_hotspot)

func _try_bite(distance: float) -> void:
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

func _refresh_nearby_hotspots() -> void:
	nearby_hotspots.clear()

	var overlapping_areas := Bobber_Area.get_overlapping_areas()

	for area in overlapping_areas:
		if _is_fish_hotspot(area):
			nearby_hotspots.append(area)

func _get_closest_hotspot() -> Area3D:
	var closest: Area3D = null
	var closest_distance := INF

	for hotspot in nearby_hotspots:
		if hotspot == null:
			continue

		var distance := global_position.distance_to(hotspot.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest = hotspot

	return closest

func _is_fish_hotspot(area: Area3D) -> bool:
	if area == null:
		return false

	if area.is_in_group("fish_hotspot"):
		return true

	if area.name.begins_with("HotSpot_"):
		return true

	return false

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

	print("Bobber landed on terrain.")

func _is_on_layer(collision_object, layer_number: int) -> bool:
	if collision_object == null:
		return false

	if not "collision_layer" in collision_object:
		return false

	return collision_object.collision_layer & (1 << (layer_number - 1)) != 0
