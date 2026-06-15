extends Node3D

signal fish_bite_started
signal fish_swim_started(direction: int)
signal fish_tired_started
signal fish_caught
signal fish_caught_reel
signal fish_released

@onready var FishHooked = $FishHooked

func _ready() -> void:
	FishHooked.fish_bite_started.connect(_on_fish_bite_started)
	FishHooked.fish_swim_started.connect(_on_fish_swim_started)
	FishHooked.fish_tired_started.connect(_on_fish_tired_started)
	FishHooked.fish_caught.connect(_on_fish_caught)
	FishHooked.fish_caught_reel.connect(_on_fish_caught_reel)
	FishHooked.fish_released.connect(_on_fish_released)

func start_fish_bite(difficulty_text: String, closest_hotspot: Area3D = null, bite_distance: float = 999.0) -> void:
	FishHooked.start_fish_bite(difficulty_text, closest_hotspot, bite_distance)

func release_fish() -> void:
	FishHooked.release_fish()

func on_player_fish_input(action_name: String) -> void:
	FishHooked.on_player_fish_input(action_name)

func _on_fish_bite_started() -> void:
	fish_bite_started.emit()

func _on_fish_swim_started(direction: int) -> void:
	fish_swim_started.emit(direction)

func _on_fish_tired_started() -> void:
	fish_tired_started.emit()

func _on_fish_caught() -> void:
	fish_caught.emit()

func _on_fish_caught_reel() -> void:
	fish_caught_reel.emit()

func _on_fish_released() -> void:
	fish_released.emit()
