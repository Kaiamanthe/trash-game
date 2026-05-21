extends MeshInstance3D

@onready var bobber: Area3D = $"../../../Bobber"
@onready var line: MeshInstance3D = $"."
@onready var mark_line_end: Marker3D = $"../Bobber/Mark_LineEnd"
@onready var mark_line_start: Marker3D = $"../Pole/Mark_LineStart"


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# Lines
func _refresh_line():
	var start_pos = mark_line_end.global_position
	var end_pos = mark_line_start.global_position
	var centerPosition = (start_pos + end_pos) / 2.0
	var distance = start_pos.distance_to(end_pos)

	line.global_position = centerPosition
	line.scale = Vector3(1, distance, 1)
	line.look_at(end_pos, Vector3.FORWARD)
	line.rotation_degrees.x -= 90
	line.hide()

func on_pole_ready():
	line.hide()

func on_cast():
	line.show()
