extends Node3D

signal fish_bite_started
signal fish_swim_started(direction: int)
signal fish_tired_started
signal fish_caught
signal fish_released

enum FishHookedState {
	inactive,
	fish_swimming,
	fish_tired,
	fish_caught
}

enum FishDifficulty {
	easy,
	medium,
	hard
}

@onready var Bobber: RigidBody3D = $"../Bobber"

@onready var FishingZoneMain: CollisionShape3D = $"../FishingZone/FishingZoneMain"
@onready var FishingZoneLeft: CollisionShape3D = $"../FishingZone/FishingZoneLeft"
@onready var FishingZoneRight: CollisionShape3D = $"../FishingZone/FishingZoneRight"

var state: FishHookedState = FishHookedState.inactive
var difficulty: FishDifficulty = FishDifficulty.easy

var fish_swim_direction := 1
var fish_swim_speed := 2.0
var fish_pull_speed := 1.8
var fish_player_push := 0.8

var fish_tired_meter := 0.0
var fish_tired_needed := 5.0

var reel_progress := 0.0
var reel_progress_needed := 6.0

var total_reel_progress := 0.0
var total_reel_needed := 18.0

var reel_pattern: Array[String] = [
	"move_forw",
	"move_rghtw",
	"move_bckw",
	"move_leftw"
]

var reel_pattern_index := 0

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	match state:
		FishHookedState.fish_swimming:
			_process_fish_swimming(delta)

		FishHookedState.fish_tired:
			_process_fish_tired(delta)

func start_fish_bite(difficulty_text: String, closest_hotspot: Area3D = null) -> void:
	if state != FishHookedState.inactive:
		return

	_apply_difficulty(difficulty_text)

	state = FishHookedState.fish_swimming
	set_process(true)

	Bobber.start_hooked_mode()

	fish_tired_meter = 0.0
	reel_progress = 0.0
	total_reel_progress = 0.0
	reel_pattern_index = 0

	if randf() > 0.5:
		fish_swim_direction = 1
	else:
		fish_swim_direction = -1

	print("FishHooked started. Difficulty: ", difficulty_text)
	print("Fish swimming direction: ", fish_swim_direction)

	fish_bite_started.emit()
	fish_swim_started.emit(fish_swim_direction)

func release_fish() -> void:
	state = FishHookedState.inactive
	set_process(false)

	Bobber.end_hooked_mode()

	fish_tired_meter = 0.0
	reel_progress = 0.0
	total_reel_progress = 0.0
	reel_pattern_index = 0

	print("Fish released / fishing reset.")
	fish_released.emit()

func on_player_fish_input(action_name: String) -> void:
	match state:
		FishHookedState.fish_swimming:
			_handle_swimming_input(action_name)

		FishHookedState.fish_tired:
			_handle_reel_input(action_name)

func _apply_difficulty(difficulty_text: String) -> void:
	match difficulty_text:
		"easy":
			difficulty = FishDifficulty.easy
			fish_swim_speed = 1.6
			fish_pull_speed = 1.4
			fish_player_push = 1.1
			fish_tired_needed = 4.0
			reel_progress_needed = 4.0
			total_reel_needed = 12.0

		"medium":
			difficulty = FishDifficulty.medium
			fish_swim_speed = 2.3
			fish_pull_speed = 2.0
			fish_player_push = 0.85
			fish_tired_needed = 6.0
			reel_progress_needed = 6.0
			total_reel_needed = 18.0

		"hard":
			difficulty = FishDifficulty.hard
			fish_swim_speed = 3.0
			fish_pull_speed = 2.7
			fish_player_push = 0.65
			fish_tired_needed = 8.0
			reel_progress_needed = 8.0
			total_reel_needed = 26.0

		_:
			difficulty = FishDifficulty.easy

func _process_fish_swimming(delta: float) -> void:
	var move_direction := global_basis.x.normalized() * fish_swim_direction
	var new_position := Bobber.global_position + move_direction * fish_swim_speed * fish_pull_speed * delta
	new_position.y = sheets_globals.water_level

	if not _is_point_inside_any_zone(new_position):
		new_position = _clamp_point_inside_any_zone(Bobber.global_position)
		Bobber.set_hooked_position(new_position)
		_bounce_fish_direction()
		return

	Bobber.set_hooked_position(new_position)

func _process_fish_tired(delta: float) -> void:
	var center := _get_combined_zone_center()
	center.y = sheets_globals.water_level

	var new_position := Bobber.global_position.lerp(center, delta * 0.75)
	new_position.y = sheets_globals.water_level

	if not _is_point_inside_any_zone(new_position):
		new_position = _clamp_point_inside_any_zone(Bobber.global_position)

	Bobber.set_hooked_position(new_position)

func _handle_swimming_input(action_name: String) -> void:
	var correct_action := ""

	if fish_swim_direction == -1:
		correct_action = "move_leftw"
	else:
		correct_action = "move_rghtw"

	if action_name == correct_action:
		fish_tired_meter += 1.0

		var push_direction := -global_basis.x.normalized() * fish_swim_direction
		var new_position := Bobber.global_position + push_direction * fish_player_push
		new_position.y = sheets_globals.water_level

		if not _is_point_inside_any_zone(new_position):
			new_position = _clamp_point_inside_any_zone(Bobber.global_position)

		Bobber.set_hooked_position(new_position)

		print("Correct direction. Tired meter: ", fish_tired_meter)
	else:
		fish_tired_meter = max(fish_tired_meter - 1.0, 0.0)
		print("Wrong direction. Tired meter: ", fish_tired_meter)

	if fish_tired_meter >= fish_tired_needed:
		_start_fish_tired()

func _start_fish_tired() -> void:
	state = FishHookedState.fish_tired

	reel_progress = 0.0
	reel_pattern_index = 0

	print("Fish is tired. Spin WASD in a circle.")
	fish_tired_started.emit()

func _handle_reel_input(action_name: String) -> void:
	var expected_action: String = reel_pattern[reel_pattern_index]

	if action_name == expected_action:
		reel_pattern_index += 1

		if reel_pattern_index >= reel_pattern.size():
			reel_pattern_index = 0
			reel_progress += 1.0
			total_reel_progress += 1.0

			print("Reel circle complete. Reel progress: ", reel_progress, " Total: ", total_reel_progress)

			if total_reel_progress >= total_reel_needed:
				_catch_fish()
				return

			if reel_progress >= reel_progress_needed:
				_restart_fish_swimming()
				return
	else:
		if action_name in reel_pattern:
			reel_pattern_index = 0
			print("Wrong reel input. Pattern reset.")

func _restart_fish_swimming() -> void:
	state = FishHookedState.fish_swimming

	fish_tired_meter = 0.0
	reel_progress = 0.0
	reel_pattern_index = 0

	if randf() > 0.5:
		fish_swim_direction = 1
	else:
		fish_swim_direction = -1

	print("Fish recovered. Back to left/right movement.")
	fish_swim_started.emit(fish_swim_direction)

func _bounce_fish_direction() -> void:
	fish_swim_direction *= -1

	print("Fish hit outside combined fishing zone. New direction: ", fish_swim_direction)
	fish_swim_started.emit(fish_swim_direction)

func _catch_fish() -> void:
	state = FishHookedState.fish_caught
	set_process(false)

	Bobber.end_hooked_mode()

	print("Fish caught.")
	fish_caught.emit()

func _get_zones() -> Array[CollisionShape3D]:
	return [
		FishingZoneMain,
		FishingZoneLeft,
		FishingZoneRight
	]

func _is_point_inside_any_zone(point: Vector3) -> bool:
	for zone in _get_zones():
		if _is_point_inside_zone(point, zone):
			return true

	return false

func _clamp_point_inside_any_zone(point: Vector3) -> Vector3:
	var best_point := point
	var best_distance := INF

	for zone in _get_zones():
		var clamped := _clamp_point_inside_zone(point, zone)
		var distance := point.distance_to(clamped)

		if distance < best_distance:
			best_distance = distance
			best_point = clamped

	best_point.y = sheets_globals.water_level
	return best_point

func _get_combined_zone_center() -> Vector3:
	var zones := _get_zones()
	var center := Vector3.ZERO
	var count := 0

	for zone in zones:
		if zone == null:
			continue

		center += zone.global_position
		count += 1

	if count == 0:
		return Bobber.global_position

	return center / float(count)

func _is_point_inside_zone(point: Vector3, zone: CollisionShape3D) -> bool:
	if zone == null:
		return false

	var box := zone.shape as BoxShape3D

	if box == null:
		return false

	var local_point := zone.global_transform.affine_inverse() * point
	var half_size := box.size * 0.5

	return (
		abs(local_point.x) <= half_size.x
		and abs(local_point.y) <= half_size.y
		and abs(local_point.z) <= half_size.z
	)

func _clamp_point_inside_zone(point: Vector3, zone: CollisionShape3D) -> Vector3:
	if zone == null:
		return point

	var box := zone.shape as BoxShape3D

	if box == null:
		return point

	var local_point := zone.global_transform.affine_inverse() * point
	var half_size := box.size * 0.5

	local_point.x = clamp(local_point.x, -half_size.x, half_size.x)
	local_point.y = clamp(local_point.y, -half_size.y, half_size.y)
	local_point.z = clamp(local_point.z, -half_size.z, half_size.z)

	var world_point := zone.global_transform * local_point
	world_point.y = sheets_globals.water_level

	return world_point
