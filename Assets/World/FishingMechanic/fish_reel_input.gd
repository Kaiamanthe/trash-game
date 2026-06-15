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

# Resets all fishing input progress back to default.
func reset_all() -> void:
	fish_tired_meter = 0.0
	reel_progress = 0.0
	total_reel_progress = 0.0
	reel_pattern_index = 0

# Resets only the reel phase progress.
func reset_reel_phase() -> void:
	reel_progress = 0.0
	reel_pattern_index = 0

# Resets progress when the fish recovers and starts swimming again.
func reset_for_swimming_restart() -> void:
	fish_tired_meter = 0.0
	reel_progress = 0.0
	reel_pattern_index = 0

# Returns the next WASD input expected during the reel phase.
func get_expected_reel_action() -> String:
	return reel_pattern[reel_pattern_index]

# Handles A/D input while the fish is swimming.
func handle_swimming_input(action_name: String, fish_swim_direction: int, FishDifficulty) -> String:
	var correct_action := ""

	if fish_swim_direction == -1:
		correct_action = "move_leftw"
	else:
		correct_action = "move_rghtw"

	if action_name == correct_action:
		fish_tired_meter += 1.0
	else:
		fish_tired_meter = max(fish_tired_meter - 1.0, 0.0)
		return "wrong"

	if fish_tired_meter >= FishDifficulty.fish_tired_needed:
		return "tired"

	return ""

# Handles WASD reel sequence input while the fish is tired.
func handle_reel_input(action_name: String, FishDifficulty) -> String:
	var expected_action: String = reel_pattern[reel_pattern_index]

	if action_name == expected_action:
		reel_pattern_index += 1

		if reel_pattern_index >= reel_pattern.size():
			reel_pattern_index = 0
			reel_progress += 1.0
			total_reel_progress += 1.0

			if total_reel_progress >= FishDifficulty.total_reel_needed:
				return "catch"

			if reel_progress >= FishDifficulty.reel_progress_needed:
				return "restart"

			return "pull"

		return "next"

	if action_name in reel_pattern:
		reel_pattern_index = 0
		return "wrong"

	return ""
