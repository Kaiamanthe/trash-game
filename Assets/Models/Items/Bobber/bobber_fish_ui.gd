extends Node3D

enum GuideMode {
	hidden,
	proximity,
	direction,
	reel
}

@onready var Bobber: RigidBody3D = $"../../.."

@onready var ProximityGuide: Sprite3D = $ProximityGuide

@onready var DirectionGuide: Node3D = $DirectionGuide
@onready var Direction_Key_A: Sprite3D = $DirectionGuide/Key_A
@onready var Direction_Key_D: Sprite3D = $DirectionGuide/Key_D

@onready var ReelGuide: Node3D = $ReelGuide
@onready var Reel_Key_W: Sprite3D = $ReelGuide/Key_W
@onready var Reel_Key_D: Sprite3D = $ReelGuide/Key_D
@onready var Reel_Key_S: Sprite3D = $ReelGuide/Key_S
@onready var Reel_Key_A: Sprite3D = $ReelGuide/Key_A

var mode: GuideMode = GuideMode.hidden

var active_key: Sprite3D = null
var blink_timer := 0.0
var blink_interval := 0.35
var blink_on := true

var shake_offset := Vector3.ZERO
var shake_tween: Tween = null
var flash_tween: Tween = null

var pending_restore_action := ""

const HEIGHT_ABOVE_BOBBER := 3.0

const PROX_CLOSE_SCALE := 10.0
const PROX_CLOSER_SCALE := 12.0
const PROX_CLOSEST_SCALE := 15.0

const KEY_NORMAL_SCALE := 4.0
const KEY_ACTIVE_SCALE := 5.0
const KEY_WRONG_SCALE := 5.5

const DIRECTION_KEY_SPACING := 8.0
const REEL_KEY_SPACING_X := 8.0
const REEL_KEY_TOP_Y := 5.0
const REEL_KEY_BOTTOM_Y := -4.0

const COLOR_CLOSE := Color.WHITE
const COLOR_CLOSER := Color.YELLOW
const COLOR_CLOSEST := Color.ORANGE
const COLOR_NORMAL := Color.WHITE
const COLOR_DIM := Color(0.35, 0.35, 0.35, 1.0)
const COLOR_WRONG := Color.RED

func _ready() -> void:
	_setup_key_layout()
	hide_all()

func _process(delta: float) -> void:
	_follow_bobber()
	_face_camera_upright()
	_process_blink(delta)

# Places direction keys and reel keys into their UI layouts
func _setup_key_layout() -> void:
	Direction_Key_A.position = Vector3(-DIRECTION_KEY_SPACING, 0.0, 0.0)
	Direction_Key_D.position = Vector3(DIRECTION_KEY_SPACING, 0.0, 0.0)

	Reel_Key_W.position = Vector3(0.0, REEL_KEY_TOP_Y, 0.0)
	Reel_Key_A.position = Vector3(-REEL_KEY_SPACING_X, REEL_KEY_BOTTOM_Y, 0.0)
	Reel_Key_S.position = Vector3(0.0, REEL_KEY_BOTTOM_Y, 0.0)
	Reel_Key_D.position = Vector3(REEL_KEY_SPACING_X, REEL_KEY_BOTTOM_Y, 0.0)

# Moves the whole UI so it stays above the bobber
func _follow_bobber() -> void:
	if Bobber == null:
		return

	global_position = Bobber.global_position + Vector3.UP * HEIGHT_ABOVE_BOBBER + shake_offset

# Hide UI reset
func hide_all() -> void:
	mode = GuideMode.hidden
	visible = false

	ProximityGuide.visible = false
	DirectionGuide.visible = false
	ReelGuide.visible = false

	active_key = null
	pending_restore_action = ""

# Shows fish proximity
func show_proximity(prox_text: String) -> void:
	if prox_text == "Cold":
		hide_all()
		return

	mode = GuideMode.proximity
	visible = true

	ProximityGuide.visible = true
	DirectionGuide.visible = false
	ReelGuide.visible = false

	active_key = null

	match prox_text:
		"Close":
			ProximityGuide.modulate = COLOR_CLOSE
			ProximityGuide.scale = Vector3.ONE * PROX_CLOSE_SCALE
		"Closer":
			ProximityGuide.modulate = COLOR_CLOSER
			ProximityGuide.scale = Vector3.ONE * PROX_CLOSER_SCALE
		"Closest":
			ProximityGuide.modulate = COLOR_CLOSEST
			ProximityGuide.scale = Vector3.ONE * PROX_CLOSEST_SCALE

# Bite shake detection
func play_bite_check_shake() -> void:
	if mode != GuideMode.proximity:
		return

	_shake(0.18, 0.35)

# Shows swim direction guide
func show_direction_guide(direction: int) -> void:
	mode = GuideMode.direction
	visible = true

	ProximityGuide.visible = false
	DirectionGuide.visible = true
	ReelGuide.visible = false

	Direction_Key_A.visible = true
	Direction_Key_D.visible = true

	_set_direction_keys_dim()

	if direction == -1:
		active_key = Direction_Key_A
	else:
		active_key = Direction_Key_D

	_reset_blink()

func show_wrong_direction() -> void:
	_flash_wrong_direction()
	_shake(0.22, 0.45)

func show_reel_guide(expected_action: String = "move_forw") -> void:
	show_reel_expected(expected_action)

func show_reel_expected(expected_action: String) -> void:
	mode = GuideMode.reel
	visible = true

	ProximityGuide.visible = false
	DirectionGuide.visible = false
	ReelGuide.visible = true

	Reel_Key_W.visible = true
	Reel_Key_A.visible = true
	Reel_Key_S.visible = true
	Reel_Key_D.visible = true

	_set_reel_keys_dim()

	match expected_action:
		"move_forw":
			active_key = Reel_Key_W
		"move_rghtw":
			active_key = Reel_Key_D
		"move_bckw":
			active_key = Reel_Key_S
		"move_leftw":
			active_key = Reel_Key_A
		_:
			active_key = Reel_Key_W

	_reset_blink()

func show_wrong_reel(next_expected_action: String = "move_forw") -> void:
	pending_restore_action = next_expected_action

	_flash_wrong_reel()
	_shake(0.22, 0.45)

func _process_blink(delta: float) -> void:
	if active_key == null:
		return

	blink_timer += delta

	if blink_timer < blink_interval:
		return

	blink_timer = 0.0
	blink_on = !blink_on

	if blink_on:
		active_key.modulate = COLOR_NORMAL
		active_key.scale = Vector3.ONE * KEY_ACTIVE_SCALE
	else:
		active_key.modulate = COLOR_DIM
		active_key.scale = Vector3.ONE * KEY_NORMAL_SCALE

func _reset_blink() -> void:
	blink_timer = 0.0
	blink_on = true

	if active_key != null:
		active_key.visible = true
		active_key.modulate = COLOR_NORMAL
		active_key.scale = Vector3.ONE * KEY_ACTIVE_SCALE

func _set_direction_keys_dim() -> void:
	Direction_Key_A.visible = true
	Direction_Key_D.visible = true

	Direction_Key_A.modulate = COLOR_DIM
	Direction_Key_D.modulate = COLOR_DIM

	Direction_Key_A.scale = Vector3.ONE * KEY_NORMAL_SCALE
	Direction_Key_D.scale = Vector3.ONE * KEY_NORMAL_SCALE

func _set_reel_keys_dim() -> void:
	Reel_Key_W.visible = true
	Reel_Key_A.visible = true
	Reel_Key_S.visible = true
	Reel_Key_D.visible = true

	Reel_Key_W.modulate = COLOR_DIM
	Reel_Key_D.modulate = COLOR_DIM
	Reel_Key_S.modulate = COLOR_DIM
	Reel_Key_A.modulate = COLOR_DIM

	Reel_Key_W.scale = Vector3.ONE * KEY_NORMAL_SCALE
	Reel_Key_D.scale = Vector3.ONE * KEY_NORMAL_SCALE
	Reel_Key_S.scale = Vector3.ONE * KEY_NORMAL_SCALE
	Reel_Key_A.scale = Vector3.ONE * KEY_NORMAL_SCALE

func _flash_wrong_direction() -> void:
	if flash_tween != null:
		flash_tween.kill()

	Direction_Key_A.modulate = COLOR_WRONG
	Direction_Key_D.modulate = COLOR_WRONG
	Direction_Key_A.scale = Vector3.ONE * KEY_WRONG_SCALE
	Direction_Key_D.scale = Vector3.ONE * KEY_WRONG_SCALE

	flash_tween = create_tween()
	flash_tween.tween_interval(0.15)
	flash_tween.tween_callback(func():
		if mode != GuideMode.direction:
			return

		_set_direction_keys_dim()

		if active_key != null:
			active_key.modulate = COLOR_NORMAL
			active_key.scale = Vector3.ONE * KEY_ACTIVE_SCALE
	)

# Flashes WASD keys red wrong input.
func _flash_wrong_reel() -> void:
	if flash_tween != null:
		flash_tween.kill()

	var keys := [Reel_Key_W, Reel_Key_D, Reel_Key_S, Reel_Key_A]

	for key in keys:
		key.visible = true
		key.modulate = COLOR_WRONG
		key.scale = Vector3.ONE * KEY_WRONG_SCALE

	flash_tween = create_tween()
	flash_tween.tween_interval(0.15)
	flash_tween.tween_callback(func():
		if mode != GuideMode.reel:
			return

		show_reel_expected(pending_restore_action)
	)

# Adds a short shake animation
func _shake(duration: float, strength: float) -> void:
	if shake_tween != null:
		shake_tween.kill()

	shake_offset = Vector3.ZERO

	shake_tween = create_tween()
	shake_tween.tween_property(self, "shake_offset", Vector3(strength, 0.0, 0.0), duration * 0.20)
	shake_tween.tween_property(self, "shake_offset", Vector3(-strength, 0.0, 0.0), duration * 0.20)
	shake_tween.tween_property(self, "shake_offset", Vector3(strength * 0.5, 0.0, 0.0), duration * 0.20)
	shake_tween.tween_property(self, "shake_offset", Vector3.ZERO, duration * 0.40)

func _face_camera_upright() -> void:
	if not visible:
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	var direction := camera.global_position - global_position
	direction.y = 0.0

	if direction.length() <= 0.01:
		return

	look_at(global_position + direction.normalized(), Vector3.UP)
	rotate_y(PI)
