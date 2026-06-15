extends Node

var fish_tired_meter := 0.0

var reel_progress := 0.0
var total_reel_progress := 0.0
var reel_pattern_index := 0

var reel_pattern: Array[String] = [
	"move_forw",
	"move_rghtw",
	"move_bckw",
	"move_leftw"
]

func reset_all() -> void:
	fish_tired_meter = 0.0
	reel_progress = 0.0
	total_reel_progress = 0.0
	reel_pattern_index = 0

func reset_reel_phase() -> void:
	reel_progress = 0.0
	reel_pattern_index = 0

func reset_for_swimming_restart() -> void:
	fish_tired_meter = 0.0
	reel_progress = 0.0
	reel_pattern_index = 0

func handle_swimming_input(action_name: String, fish_swim_direction: int, FishDifficulty) -> String:
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

	if fish_tired_meter >= FishDifficulty.fish_tired_needed:
		return "tired"

	return ""

func handle_reel_input(action_name: String, FishDifficulty) -> String:
	var expected_action: String = reel_pattern[reel_pattern_index]

	if action_name == expected_action:
		reel_pattern_index += 1

		if reel_pattern_index >= reel_pattern.size():
			reel_pattern_index = 0
			reel_progress += 1.0
			total_reel_progress += 1.0

			print("Reel circle complete. Reel progress: ", reel_progress, " Total: ", total_reel_progress)

			if total_reel_progress >= FishDifficulty.total_reel_needed:
				return "catch"

			if reel_progress >= FishDifficulty.reel_progress_needed:
				return "restart"

			return "pull"
	else:
		if action_name in reel_pattern:
			reel_pattern_index = 0
			print("Wrong reel input. Pattern reset.")

	return ""
