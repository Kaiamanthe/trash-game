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

@onready var Player: CharacterBody3D = $"../Player"
@onready var Bobber: RigidBody3D = $"../Bobber"
@onready var FishingZone: Node3D = $"../FishingZone"

var state: FishHookedState = FishHookedState.inactive
var difficulty: FishDifficulty = FishDifficulty.easy

var fish_anchor_position := Vector3.ZERO
var fish_side_offset := 0.0
var fish_away_offset := 0.0
var fish_away_target_offset := 0.0
var fish_swim_direction := 1

var fish_swim_speed := 1.0
var fish_pull_speed := 1.5
var fish_swim_range := 5.0

var fish_tired_meter := 0.0
var fish_tired_needed := 5.0

var reel_progress := 0.0
var reel_progress_needed := 6.0

var total_reel_progress := 0.0
var total_reel_needed := 18.0

var fish_tired_pull_speed := 0.35
var reel_pull_amount := 1.25
var reel_pull_pause_timer := 0.0
var reel_pull_pause_duration := 1.0
var reel_pull_smooth_speed := 3.0

var direction_change_timer := 0.0
var direction_change_interval := 2.0

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

func start_fish_bite(difficulty_text: String, closest_hotspot: Area3D = null, bite_distance: float = 999.0) -> void:
	if state != FishHookedState.inactive:
		return

	_apply_difficulty_from_distance(bite_distance)

	state = FishHookedState.fish_swimming
	set_process(true)

	Bobber.start_hooked_mode()

	fish_anchor_position = Bobber.global_position
	fish_anchor_position.y = sheets_globals.water_level
	fish_side_offset = 0.0
	fish_away_offset = 0.0
	fish_away_target_offset = 0.0

	fish_tired_meter = 0.0
	reel_progress = 0.0
	total_reel_progress = 0.0
	reel_pattern_index = 0
	direction_change_timer = 0.0
	reel_pull_pause_timer = 0.0

	if randf() > 0.5:
		fish_swim_direction = 1
	else:
		fish_swim_direction = -1

	print("FishHooked started. Bite distance: ", bite_distance, " | Difficulty: ", FishDifficulty.keys()[difficulty])
	print("Fish swimming direction: ", fish_swim_direction)

	fish_bite_started.emit()
	fish_swim_started.emit(fish_swim_direction)

func release_fish() -> void:
	state = FishHookedState.inactive
	set_process(false)

	Bobber.end_hooked_mode()

	fish_anchor_position = Vector3.ZERO
	fish_side_offset = 0.0
	fish_away_offset = 0.0
	fish_away_target_offset = 0.0
	fish_tired_meter = 0.0
	reel_progress = 0.0
	total_reel_progress = 0.0
	reel_pattern_index = 0
	direction_change_timer = 0.0
	reel_pull_pause_timer = 0.0

	print("Fish released / fishing reset.")
	fish_released.emit()

func on_player_fish_input(action_name: String) -> void:
	match state:
		FishHookedState.fish_swimming:
			_handle_swimming_input(action_name)

		FishHookedState.fish_tired:
			_handle_reel_input(action_name)

func _apply_difficulty_from_distance(bite_distance: float) -> void:
	var player_distance := Player.global_position.distance_to(Bobber.global_position)

	var easy_chance := 0.65
	var medium_chance := 0.30
	var hard_chance := 0.05

	if bite_distance <= 5.0:
		easy_chance = 0.35
		medium_chance = 0.40
		hard_chance = 0.25
	elif bite_distance <= 10.0:
		easy_chance = 0.50
		medium_chance = 0.40
		hard_chance = 0.10

	if player_distance >= 25.0:
		easy_chance -= 0.20
		medium_chance += 0.05
		hard_chance += 0.15
	elif player_distance >= 15.0:
		easy_chance -= 0.10
		medium_chance += 0.05
		hard_chance += 0.05

	easy_chance = max(easy_chance, 0.05)
	medium_chance = max(medium_chance, 0.05)
	hard_chance = max(hard_chance, 0.05)

	var total := easy_chance + medium_chance + hard_chance
	easy_chance /= total
	medium_chance /= total

	var difficulty_roll := randf()

	if difficulty_roll < easy_chance:
		_set_easy_fish()
	elif difficulty_roll < easy_chance + medium_chance:
		_set_medium_fish()
	else:
		_set_hard_fish()

	print("Difficulty roll: ", difficulty_roll, " | Player distance: ", player_distance)

func _set_easy_fish() -> void:
	difficulty = FishDifficulty.easy
	fish_swim_speed = 1.5
	fish_pull_speed = 1.5
	fish_swim_range = 8.0

	fish_tired_needed = 4.0
	reel_progress_needed = 4.0
	total_reel_needed = 12.0

	fish_tired_pull_speed = 0.25
	reel_pull_amount = 1.5
	reel_pull_pause_duration = 1.2
	reel_pull_smooth_speed = 2.5

	direction_change_interval = 2.8

func _set_medium_fish() -> void:
	difficulty = FishDifficulty.medium
	fish_swim_speed = 1.8
	fish_pull_speed = 1.7
	fish_swim_range = 10.0

	fish_tired_needed = 6.0
	reel_progress_needed = 6.0
	total_reel_needed = 18.0

	fish_tired_pull_speed = 0.4
	reel_pull_amount = 1.25
	reel_pull_pause_duration = 0.85
	reel_pull_smooth_speed = 3.0

	direction_change_interval = 2.2

func _set_hard_fish() -> void:
	difficulty = FishDifficulty.hard
	fish_swim_speed = 2.0
	fish_pull_speed = 1.9
	fish_swim_range = 12.0

	fish_tired_needed = 8.0
	reel_progress_needed = 8.0
	total_reel_needed = 26.0

	fish_tired_pull_speed = 0.6
	reel_pull_amount = 1.0
	reel_pull_pause_duration = 0.5
	reel_pull_smooth_speed = 3.5

	direction_change_interval = 1.7

func _process_fish_swimming(delta: float) -> void:
	direction_change_timer += delta

	if direction_change_timer >= direction_change_interval:
		direction_change_timer = 0.0

		if randf() > 0.7:
			fish_swim_direction *= -1
			print("Fish changed direction naturally: ", fish_swim_direction)
			fish_swim_started.emit(fish_swim_direction)

	fish_side_offset += fish_swim_direction * fish_swim_speed * fish_pull_speed * delta

	if fish_side_offset > fish_swim_range:
		fish_side_offset = fish_swim_range
		_bounce_fish_direction()
	elif fish_side_offset < -fish_swim_range:
		fish_side_offset = -fish_swim_range
		_bounce_fish_direction()

	var new_position := _get_fish_world_position()

	if not FishingZone.is_point_inside_any_zone(new_position):
		_catch_fish()
		return

	Bobber.set_hooked_position(new_position)

func _process_fish_tired(delta: float) -> void:
	if reel_pull_pause_timer > 0.0:
		reel_pull_pause_timer = max(reel_pull_pause_timer - delta, 0.0)
	else:
		fish_away_target_offset += fish_tired_pull_speed * delta

	fish_away_offset = lerp(
		fish_away_offset,
		fish_away_target_offset,
		delta * reel_pull_smooth_speed
	)

	var new_position := _get_fish_world_position()

	if not FishingZone.is_point_inside_any_zone(new_position):
		_catch_fish()
		return

	Bobber.set_hooked_position(new_position)

func _handle_swimming_input(action_name: String) -> void:
	var correct_action := ""

	if fish_swim_direction == -1:
		correct_action = "move_leftw"
	else:
		correct_action = "move_rghtw"

	if action_name == correct_action:
		fish_tired_meter += 1.0
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
	reel_pull_pause_timer = 0.0
	fish_away_target_offset = fish_away_offset

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

			_pull_fish_closer()

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

func _pull_fish_closer() -> void:
	fish_away_target_offset = max(fish_away_target_offset - reel_pull_amount, 0.0)
	reel_pull_pause_timer = reel_pull_pause_duration

	print("Fish pulled closer smoothly. Pull pause: ", reel_pull_pause_duration)

func _restart_fish_swimming() -> void:
	state = FishHookedState.fish_swimming

	fish_anchor_position = Bobber.global_position
	fish_anchor_position.y = sheets_globals.water_level
	fish_side_offset = 0.0
	fish_away_offset = 0.0
	fish_away_target_offset = 0.0

	fish_tired_meter = 0.0
	reel_progress = 0.0
	reel_pattern_index = 0
	direction_change_timer = 0.0
	reel_pull_pause_timer = 0.0

	if randf() > 0.5:
		fish_swim_direction = 1
	else:
		fish_swim_direction = -1

	print("Fish recovered. Back to parallel side-to-side movement.")
	fish_swim_started.emit(fish_swim_direction)

func _bounce_fish_direction() -> void:
	fish_swim_direction *= -1
	direction_change_timer = 0.0

	print("Fish reached side limit. New direction: ", fish_swim_direction)
	fish_swim_started.emit(fish_swim_direction)

func _catch_fish() -> void:
	if state == FishHookedState.fish_caught:
		return

	state = FishHookedState.fish_caught
	set_process(false)

	Bobber.end_hooked_mode()

	print("Fish caught.")
	fish_caught.emit()

func _get_fish_world_position() -> Vector3:
	var right_direction := Player.global_basis.x.normalized()
	var away_direction := _get_away_direction()

	var position := (
		fish_anchor_position
		+ right_direction * fish_side_offset
		+ away_direction * fish_away_offset
	)

	position.y = sheets_globals.water_level

	return position

func _get_away_direction() -> Vector3:
	var away_direction := fish_anchor_position - Player.global_position
	away_direction.y = 0.0

	if away_direction.length() <= 0.01:
		return -Player.global_basis.z.normalized()

	return away_direction.normalized()
