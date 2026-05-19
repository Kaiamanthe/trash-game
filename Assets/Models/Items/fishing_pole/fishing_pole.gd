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
	_refresh_line()

func _refresh_line():
	var start_pos = mark_line_end.global_position
	var end_pos = mark_line_start.global_position

	var centerPosition = (start_pos + end_pos) / 2.0
	var distance = start_pos.distance_to(end_pos)

	line.global_position = centerPosition
	line.scale = Vector3(1, distance, 1)

	line.look_at(end_pos, Vector3.FORWARD)
	line.rotation_degrees.x -= 90
		
func _fishing_Starts():
	line.show()
	_throw_Bobber()
	
func _throw_Bobber():
	bobber.set_physics_process(true)
	bobber.global_position = mark_line_start.global_position
	bobber.velocity = -global_basis.z * 15 + Vector3.UP * 5	
