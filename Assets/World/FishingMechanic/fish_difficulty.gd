extends Node

enum FishDifficultyLevel {
	easy,
	medium,
	hard
}

var difficulty: FishDifficultyLevel = FishDifficultyLevel.easy
var difficulty_name := "easy"

var fish_swim_speed := 1.0
var fish_pull_speed := 1.5
var fish_swim_range := 5.0

var fish_start_min_distance := 7.0
var fish_start_pull_away_speed := 2.5

var fish_tired_needed := 5.0
var reel_progress_needed := 6.0
var total_reel_needed := 18.0

var fish_tired_pull_speed := 0.35
var reel_pull_amount := 1.25
var reel_pull_pause_duration := 1.0
var reel_pull_smooth_speed := 3.0

var direction_change_interval := 2.0

# Chooses fish difficulty based on bite distance and player distance.
func apply_from_distance(bite_distance: float, player_distance: float) -> void:
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
		set_easy_fish()
	elif difficulty_roll < easy_chance + medium_chance:
		set_medium_fish()
	else:
		set_hard_fish()

# Applies easy fish movement and reel values.
func set_easy_fish() -> void:
	difficulty = FishDifficultyLevel.easy
	difficulty_name = "easy"

	fish_swim_speed = 1.5
	fish_pull_speed = 1.5
	fish_swim_range = 8.0

	fish_start_min_distance = 7.0
	fish_start_pull_away_speed = 2.0

	fish_tired_needed = 4.0
	reel_progress_needed = 4.0
	total_reel_needed = 12.0

	fish_tired_pull_speed = 0.8
	reel_pull_amount = 1.5
	reel_pull_pause_duration = 1.2
	reel_pull_smooth_speed = 3.0

	direction_change_interval = 2.8

# Applies medium fish movement and reel values.
func set_medium_fish() -> void:
	difficulty = FishDifficultyLevel.medium
	difficulty_name = "medium"

	fish_swim_speed = 1.8
	fish_pull_speed = 1.7
	fish_swim_range = 10.0

	fish_start_min_distance = 8.0
	fish_start_pull_away_speed = 2.5

	fish_tired_needed = 6.0
	reel_progress_needed = 6.0
	total_reel_needed = 18.0

	fish_tired_pull_speed = 1.0
	reel_pull_amount = 1.25
	reel_pull_pause_duration = 0.85
	reel_pull_smooth_speed = 3.5

	direction_change_interval = 2.2

# Applies hard fish movement and reel values.
func set_hard_fish() -> void:
	difficulty = FishDifficultyLevel.hard
	difficulty_name = "hard"

	fish_swim_speed = 2.0
	fish_pull_speed = 1.9
	fish_swim_range = 12.0

	fish_start_min_distance = 9.0
	fish_start_pull_away_speed = 3.0

	fish_tired_needed = 8.0
	reel_progress_needed = 8.0
	total_reel_needed = 26.0

	fish_tired_pull_speed = 1.2
	reel_pull_amount = 1.0
	reel_pull_pause_duration = 0.5
	reel_pull_smooth_speed = 4.0

	direction_change_interval = 1.7
