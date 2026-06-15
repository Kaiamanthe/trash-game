extends Node3D

signal fish_bite_started
signal fish_swim_started(direction: int)
signal fish_tired_started
signal fish_caught
signal fish_caught_reel
signal fish_released

enum FishHookedState {
	inactive,
	fish_pulling_away,
	fish_swimming,
	fish_tired,
	fish_reeling_in,
	fish_caught
}

@onready var Player: CharacterBody3D = $"../../Player"
@onready var Bobber: RigidBody3D = $"../../Bobber"
@onready var FishingZone: Node3D = $"../../FishingZone"

@onready var FishDifficulty = $"../FishDifficulty"
@onready var FishMovement = $"../FishMovement"
@onready var FishReelInput = $"../FishReelInput"
@onready var Bobber_Area_Col = $"../../Bobber/Bobber_Area/Bobber_Area_Col"

var state: FishHookedState = FishHookedState.inactive

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	match state:
		FishHookedState.fish_pulling_away:
			_process_fish_pulling_away(delta)

		FishHookedState.fish_swimming:
			_process_fish_swimming(delta)

		FishHookedState.fish_tired:
			_process_fish_tired(delta)

		FishHookedState.fish_reeling_in:
			_process_fish_reeling_in(delta)

# Starts gameplay
func start_fish_bite(difficulty_text: String, closest_hotspot: Area3D = null, bite_distance: float = 999.0) -> void:
	if state != FishHookedState.inactive:
		return

	var player_distance: float = Player.global_position.distance_to(Bobber.global_position)

	FishDifficulty.apply_from_distance(bite_distance, player_distance)
	FishMovement.setup_for_bite(Bobber.global_position)
	FishMovement.randomize_swim_direction()
	FishReelInput.reset_all()

	set_process(true)
	Bobber.start_hooked_mode()

	if player_distance < FishDifficulty.fish_start_min_distance:
		state = FishHookedState.fish_pulling_away
	else:
		_begin_side_to_side()

	fish_bite_started.emit()

# After game resets
func release_fish() -> void:
	state = FishHookedState.inactive
	set_process(false)

	Bobber.end_hooked_mode()

	FishMovement.reset_all()
	FishReelInput.reset_all()
	Bobber_Area_Col.hide_fish_ui()

	fish_released.emit()

# Routes player fishing inputs into swimming or reeling logic
func on_player_fish_input(action_name: String) -> void:
	match state:
		FishHookedState.fish_swimming:
			var swim_result: String = FishReelInput.handle_swimming_input(
				action_name,
				FishMovement.get_swim_direction(),
				FishDifficulty
			)

			if swim_result == "wrong":
				Bobber_Area_Col.show_wrong_direction()

			if swim_result == "tired":
				_start_fish_tired()

		FishHookedState.fish_tired:
			var reel_result: String = FishReelInput.handle_reel_input(
				action_name,
				FishDifficulty
			)

			match reel_result:
				"wrong":
					Bobber_Area_Col.show_wrong_reel(FishReelInput.get_expected_reel_action())

				"next":
					Bobber_Area_Col.show_reel_expected(FishReelInput.get_expected_reel_action())

				"pull":
					FishMovement.pull_fish_closer(FishDifficulty)
					Bobber_Area_Col.show_reel_expected(FishReelInput.get_expected_reel_action())

				"catch":
					FishMovement.pull_fish_closer(FishDifficulty)
					_catch_fish()

				"restart":
					FishMovement.pull_fish_closer(FishDifficulty)
					_restart_fish_swimming()

# Starts movement
func _begin_side_to_side() -> void:
	state = FishHookedState.fish_swimming
	FishMovement.begin_side_to_side()

	Bobber_Area_Col.show_direction_guide(FishMovement.get_swim_direction())

	fish_swim_started.emit(FishMovement.get_swim_direction())

# Updates fish pull when tired
func _process_fish_pulling_away(delta: float) -> void:
	var result: String = FishMovement.process_pulling_away(
		delta,
		Player,
		Bobber,
		FishingZone,
		FishDifficulty
	)

	if result == "side_to_side":
		_begin_side_to_side()

# Update swimming process
func _process_fish_swimming(delta: float) -> void:
	var result: String = FishMovement.process_swimming(
		delta,
		Player,
		Bobber,
		FishingZone,
		FishDifficulty
	)

	match result:
		"escaped":
			state = FishHookedState.inactive
			set_process(false)
			Bobber_Area_Col.hide_fish_ui()
			fish_caught_reel.emit()

		"direction_changed":
			Bobber_Area_Col.show_direction_guide(FishMovement.get_swim_direction())
			fish_swim_started.emit(FishMovement.get_swim_direction())

# Updates fish tired and reelable
func _process_fish_tired(delta: float) -> void:
	var result: String = FishMovement.process_tired(
		delta,
		Player,
		Bobber,
		FishingZone,
		FishDifficulty
	)

	if result == "escaped":
		state = FishHookedState.inactive
		set_process(false)
		Bobber_Area_Col.hide_fish_ui()
		fish_caught_reel.emit()

# Auto reel on caught
func _process_fish_reeling_in(delta: float) -> void:
	var result: String = FishMovement.process_reeling_in(
		delta,
		Player,
		Bobber
	)

	if result == "caught":
		_finish_fish_catch()

# Switch movement to reel
func _start_fish_tired() -> void:
	state = FishHookedState.fish_tired

	FishReelInput.reset_reel_phase()
	FishMovement.start_tired_phase()

	Bobber_Area_Col.show_reel_guide(FishReelInput.get_expected_reel_action())

	fish_tired_started.emit()

# Exit reel to movement
func _restart_fish_swimming() -> void:
	state = FishHookedState.fish_swimming

	FishMovement.restart_swimming(Bobber.global_position)
	FishReelInput.reset_for_swimming_restart()

	Bobber_Area_Col.show_direction_guide(FishMovement.get_swim_direction())

	fish_swim_started.emit(FishMovement.get_swim_direction())

# Fish caught auto reel and reset ui
func _catch_fish() -> void:
	if state == FishHookedState.fish_caught:
		return

	if state == FishHookedState.fish_reeling_in:
		return

	state = FishHookedState.fish_reeling_in
	Bobber_Area_Col.hide_fish_ui()

# Reset after catch
func _finish_fish_catch() -> void:
	if state == FishHookedState.fish_caught:
		return

	state = FishHookedState.fish_caught
	set_process(false)

	Bobber.end_hooked_mode()
	Bobber_Area_Col.hide_fish_ui()

	fish_caught.emit()
