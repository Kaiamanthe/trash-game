extends CollisionShape3D

@onready var Bobber: RigidBody3D = $"../.."
@onready var Bobber_Area: Area3D = $".."
@onready var BobberFishUI: Node3D = $BobberFishUI

var nearby_hotspots: Array[Area3D] = []
var closest_hotspot: Area3D = null
var closest_distance: float = INF

func _ready() -> void:
	Bobber_Area.monitoring = true
	Bobber_Area.monitorable = true

	Bobber_Area.area_entered.connect(_on_area_entered)
	Bobber_Area.area_exited.connect(_on_area_exited)

	BobberFishUI.hide_all()

func reset_hotspots() -> void:
	nearby_hotspots.clear()
	closest_hotspot = null
	closest_distance = INF
	BobberFishUI.hide_all()

func refresh_nearby_hotspots() -> void:
	nearby_hotspots.clear()

	var overlapping_areas := Bobber_Area.get_overlapping_areas()

	for area in overlapping_areas:
		if area is Area3D:
			if _is_fish_hotspot(area):
				nearby_hotspots.append(area)

	_update_closest_hotspot()

func get_closest_hotspot() -> Area3D:
	return closest_hotspot

func get_distance_to_closest_hotspot() -> float:
	if closest_hotspot == null:
		return INF

	return Bobber.global_position.distance_to(closest_hotspot.global_position)

func set_proximity_visual(prox_text: String) -> void:
	BobberFishUI.show_proximity(prox_text)

func play_bite_check_visual() -> void:
	BobberFishUI.play_bite_check_shake()

func show_direction_guide(direction: int) -> void:
	BobberFishUI.show_direction_guide(direction)

func show_wrong_direction() -> void:
	BobberFishUI.show_wrong_direction()

func show_reel_guide(expected_action: String = "move_forw") -> void:
	BobberFishUI.show_reel_guide(expected_action)

func show_reel_expected(expected_action: String) -> void:
	BobberFishUI.show_reel_expected(expected_action)

func show_wrong_reel(next_expected_action: String = "move_forw") -> void:
	BobberFishUI.show_wrong_reel(next_expected_action)

func hide_fish_ui() -> void:
	BobberFishUI.hide_all()

func _on_area_entered(area: Area3D) -> void:
	if not _is_fish_hotspot(area):
		return

	if not nearby_hotspots.has(area):
		nearby_hotspots.append(area)

	_update_closest_hotspot()

func _on_area_exited(area: Area3D) -> void:
	if not _is_fish_hotspot(area):
		return

	nearby_hotspots.erase(area)

	if closest_hotspot == area:
		closest_hotspot = null
		closest_distance = INF

	_update_closest_hotspot()

func _update_closest_hotspot() -> void:
	closest_hotspot = null
	closest_distance = INF

	for hotspot in nearby_hotspots:
		if hotspot == null:
			continue

		var distance: float = Bobber.global_position.distance_to(hotspot.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_hotspot = hotspot

func _is_fish_hotspot(area: Area3D) -> bool:
	if area == null:
		return false

	if area.is_in_group("fish_hotspot"):
		return true

	if area.name.begins_with("HotSpot_"):
		return true

	return false
