extends Node3D

@onready var bobber: CharacterBody3D = $Bobber
@onready var line: MeshInstance3D = $Line
@onready var mark_line_end: Marker3D = $Pole/Mark_LineStart
@onready var mark_line_start: Marker3D = $Bobber/Mark_LineEnd

# Inicialize the overloaded _physics_process
func _ready() -> void:
	bobber.set_physics_process(false)
	line.hide()

# Overides the Phycis process of bobber
func _physics_process(_delta: float) -> void:
	line._refresh_line()


func _fishing_Starts():
	line.show()
	_throw_Bobber()

func _throw_Bobber():
	bobber.set_physics_process(true)
	bobber.global_position = mark_line_start.global_position
	bobber.velocity = -global_basis.z * 15 + Vector3.UP * 5	
