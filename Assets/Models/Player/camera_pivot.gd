extends Node3D

enum CameraMode {
	free,
	fishing
}

var mode: CameraMode = CameraMode.free
var mouse_sensitivity := 0.002

@onready var Player: CharacterBody3D = get_parent()

func enter_free_mode() -> void:
	mode = CameraMode.free
	rotation.x = 0.0

func enter_fishing_mode() -> void:
	mode = CameraMode.fishing
	rotation.x = 0.0

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if mode != CameraMode.free:
		return

	Player.rotate_y(-event.relative.x * mouse_sensitivity)

	rotate_x(-event.relative.y * mouse_sensitivity)
	rotation.x = clamp(
		rotation.x,
		deg_to_rad(-80),
		deg_to_rad(80)
	)

func update_fishing_lock(delta: float, target_global_position: Vector3) -> void:
	if mode != CameraMode.fishing:
		return

	var look_target := target_global_position
	look_target.y = Player.global_position.y

	var direction := look_target - Player.global_position

	if direction.length() <= 0.01:
		return

	var target_basis := Transform3D().looking_at(direction.normalized(), Vector3.UP).basis

	Player.global_basis = Player.global_basis.orthonormalized().slerp(
		target_basis.orthonormalized(),
		0.15
	).orthonormalized()

	rotation.x = lerp(rotation.x, 0.0, 0.15)
