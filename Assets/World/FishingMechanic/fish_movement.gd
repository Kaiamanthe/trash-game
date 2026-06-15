extends Node

var fish_anchor_position := Vector3.ZERO
var fish_side_offset := 0.0
var fish_away_offset := 0.0
var fish_away_target_offset := 0.0
var fish_swim_direction := 1

var direction_change_timer := 0.0
var reel_pull_pause_timer := 0.0

var reel_in_speed := 10.0
var catch_distance := 1.5

func reset_all() -> void:
	fish_anchor_position = Vector3.ZERO
	fish_side_offset = 0.0
	fish_away_offset = 0.0
	fish_away_target_offset = 0.0
	fish_swim_direction = 1
	direction_change_timer = 0.0
	reel_pull_pause_timer = 0.0

func setup_for_bite(bobber_position: Vector3) -> void:
	fish_anchor_position = bobber_position
	fish_anchor_position.y = sheets_globals.water_level

	fish_side_offset = 0.0
	fish_away_offset = 0.0
	fish_away_target_offset = 0.0

	direction_change_timer = 0.0
	reel_pull_pause_timer = 0.0

func randomize_swim_direction() -> void:
	if randf() > 0.5:
		fish_swim_direction = 1
	else:
		fish_swim_direction = -1

func get_swim_direction() -> int:
	return fish_swim_direction

func begin_side_to_side() -> void:
	direction_change_timer = 0.0

func process_pulling_away(delta: float, Player: CharacterBody3D, Bobber: RigidBody3D, FishingZone: Node3D, FishDifficulty) -> String:
	var current_position := get_fish_world_position(Player)
	var current_distance := Player.global_position.distance_to(current_position)

	if current_distance >= FishDifficulty.fish_start_min_distance:
		setup_for_bite(Bobber.global_position)
		return "side_to_side"

	fish_away_target_offset += FishDifficulty.fish_start_pull_away_speed * delta

	fish_away_offset = lerp(
		fish_away_offset,
		fish_away_target_offset,
		delta * FishDifficulty.reel_pull_smooth_speed
	)

	var new_position := get_fish_world_position(Player)

	if not FishingZone.is_point_inside_any_zone(new_position):
		setup_for_bite(Bobber.global_position)
		return "side_to_side"

	Bobber.set_hooked_position(new_position)
	return ""

func process_swimming(delta: float, Player: CharacterBody3D, Bobber: RigidBody3D, FishingZone: Node3D, FishDifficulty) -> String:
	var result := ""

	direction_change_timer += delta

	if direction_change_timer >= FishDifficulty.direction_change_interval:
		direction_change_timer = 0.0

		if randf() > 0.7:
			fish_swim_direction *= -1
			print("Fish changed direction naturally: ", fish_swim_direction)
			result = "direction_changed"

	fish_side_offset += fish_swim_direction * FishDifficulty.fish_swim_speed * FishDifficulty.fish_pull_speed * delta

	if fish_side_offset > FishDifficulty.fish_swim_range:
		fish_side_offset = FishDifficulty.fish_swim_range
		_bounce_fish_direction()
		result = "direction_changed"
	elif fish_side_offset < -FishDifficulty.fish_swim_range:
		fish_side_offset = -FishDifficulty.fish_swim_range
		_bounce_fish_direction()
		result = "direction_changed"

	var new_position := get_fish_world_position(Player)

	if not FishingZone.is_point_inside_any_zone(new_position):
		return "escaped"

	Bobber.set_hooked_position(new_position)
	return result

func process_tired(delta: float, Player: CharacterBody3D, Bobber: RigidBody3D, FishingZone: Node3D, FishDifficulty) -> String:
	if reel_pull_pause_timer > 0.0:
		reel_pull_pause_timer = max(reel_pull_pause_timer - delta, 0.0)
	else:
		fish_away_target_offset += FishDifficulty.fish_tired_pull_speed * delta

	fish_away_offset = lerp(
		fish_away_offset,
		fish_away_target_offset,
		delta * FishDifficulty.reel_pull_smooth_speed
	)

	var new_position := get_fish_world_position(Player)

	if not FishingZone.is_point_inside_any_zone(new_position):
		return "escaped"

	Bobber.set_hooked_position(new_position)
	return ""

func process_reeling_in(delta: float, Player: CharacterBody3D, Bobber: RigidBody3D) -> String:
	var target_position := Player.global_position
	target_position.y = 15.0

	var current_position := Bobber.global_position
	current_position.y = 15.0

	var new_position := current_position.move_toward(
		target_position,
		reel_in_speed * delta
	)

	new_position.y = 15.0

	Bobber.set_hooked_position(new_position)

	var flat_new_position := new_position
	var flat_target_position := target_position

	flat_new_position.y = 0.0
	flat_target_position.y = 0.0

	if flat_new_position.distance_to(flat_target_position) <= catch_distance:
		return "caught"

	return ""

func start_tired_phase() -> void:
	reel_pull_pause_timer = 0.0
	fish_away_target_offset = fish_away_offset

func pull_fish_closer(FishDifficulty) -> void:
	fish_away_target_offset = max(fish_away_target_offset - FishDifficulty.reel_pull_amount, 0.0)
	reel_pull_pause_timer = FishDifficulty.reel_pull_pause_duration

	print("Fish pulled closer smoothly. Pull pause: ", FishDifficulty.reel_pull_pause_duration)

func restart_swimming(bobber_position: Vector3) -> void:
	setup_for_bite(bobber_position)
	randomize_swim_direction()

func get_fish_world_position(Player: CharacterBody3D) -> Vector3:
	var right_direction := Player.global_basis.x.normalized()
	var away_direction := _get_away_direction(Player)

	var position := (
		fish_anchor_position
		+ right_direction * fish_side_offset
		+ away_direction * fish_away_offset
	)

	position.y = sheets_globals.water_level

	return position

func _get_away_direction(Player: CharacterBody3D) -> Vector3:
	var away_direction := fish_anchor_position - Player.global_position
	away_direction.y = 0.0

	if away_direction.length() <= 0.01:
		return -Player.global_basis.z.normalized()

	return away_direction.normalized()

func _bounce_fish_direction() -> void:
	fish_swim_direction *= -1
	direction_change_timer = 0.0

	print("Fish reached side limit. New direction: ", fish_swim_direction)
