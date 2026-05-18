extends Node3D

@onready var bobber: CharacterBody3D = %Bobber
@onready var line: MeshInstance3D = %Line
@onready var mark_line_end: Marker3D = %MarkLineEnd
@onready var mark_line_start: Marker3D = %MarkLineStart

# Inicialize the overloaded _physics_process
func _ready() -> void:
	bobber.is_physics_process(false)
	line.hide()

# Overides the Phycis process of bobber
func _physics_process(delta: float) -> void:
	_refresh_line()

func _refresh_line():
	var centerPosition = (mark_line_start.global_position + bobber.global_position / 2)
	var distance = mark_line_start.global_position.distance_to(bobber.global_position)
	
	line.global_position = centerPosition
	line.mesh.height = distance
	line.look_at(mark_line_start.global_position)
	line.rotation_degrees.x -= 90

func _fishing_Starts():
	line.show()
	_throw_Bobber()
	
func _throw_Bobber():
	bobber.velocity = global_basis * Vector3(1,1,0) * 5
	bobber.velocity.y = 6
	bobber.set_physics_process(true)
	
