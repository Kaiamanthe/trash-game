extends MeshInstance3D

@onready var mark_line_start: Marker3D = $"../FishingPole/Mark_LineStart"
@onready var mark_line_end: Marker3D = $"../Bobber/Mark_LineEnd"

var start_pos := mark_line_start.global_position
var end_pos := mark_line_end.global_position

var center_position := (start_pos + end_pos) / 2.0
var distance := start_pos.distance_to(end_pos)

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	global_position = center_position
	scale = Vector3(1, distance, 1)

	look_at(end_pos, Vector3.FORWARD)
	rotation_degrees.x -= 90

func on_pole_ready():
	hide()

func on_cast():
	show()
