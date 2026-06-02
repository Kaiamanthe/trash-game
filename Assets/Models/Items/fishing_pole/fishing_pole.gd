extends Node3D

signal on_pole_ready
signal on_cast

@onready var player: CharacterBody3D = $"../Player"
@onready var bobber: RigidBody3D = $"../Bobber"
@onready var line: MeshInstance3D = $"../Line"
@onready var mark_line_start: Marker3D = $Mark_LineStart
@onready var mark_player_hand: Marker3D = $"../Player/Camera_Pivot/Mark_Player_Hand"

func _ready() -> void:
	on_pole_ready.connect(bobber.on_pole_ready)

	on_cast.connect(bobber.on_cast)

	on_pole_ready.emit()

func _process(_delta: float) -> void:
	if mark_player_hand == null:
		return
	global_transform = mark_player_hand.global_transform
	

func on_cast_started():
	on_cast.emit()
