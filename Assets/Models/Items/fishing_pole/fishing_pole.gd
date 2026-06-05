extends Node3D

signal on_pole_ready
signal on_cast

@onready var Bobber: RigidBody3D = $"../Bobber"
@onready var Mark_Player_Hand: Marker3D = $"../Player/Camera_Pivot/Mark_Player_Hand"

func _ready() -> void:
	on_pole_ready.connect(Bobber.on_pole_ready)

	on_cast.connect(Bobber.on_cast)

	on_pole_ready.emit()

func _process(_delta: float) -> void:
	if Mark_Player_Hand == null:
		return
	global_transform = Mark_Player_Hand.global_transform
	

func on_cast_started():
	on_cast.emit()
