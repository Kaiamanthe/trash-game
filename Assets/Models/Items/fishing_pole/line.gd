extends MeshInstance3D

@onready var mark_line_start: Marker3D = $"../FishingPole/Mark_LineStart"
@onready var mark_line_end: Marker3D = $"../Bobber/Mark_LineEnd"

func _ready() -> void:
	mesh = ImmediateMesh.new()

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	material.albedo_color = Color(0.85, 0.85, 0.85, 0.15)

	material_override = material


func _process(_delta: float) -> void:
	var start_pos := mark_line_start.global_position
	var end_pos := mark_line_end.global_position

	var immediate_mesh := mesh as ImmediateMesh
	immediate_mesh.clear_surfaces()

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	immediate_mesh.surface_add_vertex(
		to_local(start_pos)
	)

	immediate_mesh.surface_add_vertex(
		to_local(end_pos)
	)

	immediate_mesh.surface_end()
