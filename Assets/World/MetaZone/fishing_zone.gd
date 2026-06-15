extends Node3D

@onready var FishingZoneMain: CollisionShape3D = $FishingZoneMain
@onready var FishingZoneLeft: CollisionShape3D = $FishingZoneLeft
@onready var FishingZoneRight: CollisionShape3D = $FishingZoneRight

func get_zones() -> Array[CollisionShape3D]:
	return [
		FishingZoneMain,
		FishingZoneLeft,
		FishingZoneRight
	]

func is_point_inside_any_zone(point: Vector3) -> bool:
	for zone in get_zones():
		if is_point_inside_zone(point, zone):
			return true
	return false

func is_point_inside_zone(point: Vector3, zone: CollisionShape3D) -> bool:
	if zone == null:
		return false

	var box := zone.shape as BoxShape3D

	if box == null:
		return false

	var local_point := zone.global_transform.affine_inverse() * point
	var half_size := box.size * 0.5

	return (
		abs(local_point.x) <= half_size.x
		and abs(local_point.z) <= half_size.z
	)

func clamp_point_inside_any_zone(point: Vector3) -> Vector3:
	var best_point := point
	var best_distance := INF

	for zone in get_zones():
		var clamped := clamp_point_inside_zone(point, zone)
		var distance := point.distance_to(clamped)

		if distance < best_distance:
			best_distance = distance
			best_point = clamped

	best_point.y = sheets_globals.water_level
	return best_point

func clamp_point_inside_zone(point: Vector3, zone: CollisionShape3D) -> Vector3:
	if zone == null:
		return point

	var box := zone.shape as BoxShape3D

	if box == null:
		return point

	var local_point := zone.global_transform.affine_inverse() * point
	var half_size := box.size * 0.5

	local_point.x = clamp(local_point.x, -half_size.x, half_size.x)
	local_point.z = clamp(local_point.z, -half_size.z, half_size.z)

	var world_point := zone.global_transform * local_point
	world_point.y = sheets_globals.water_level

	return world_point

func get_combined_zone_center() -> Vector3:
	var center := Vector3.ZERO
	var count := 0

	for zone in get_zones():
		if zone == null:
			continue

		center += zone.global_position
		count += 1

	if count == 0:
		return global_position

	center /= float(count)
	center.y = sheets_globals.water_level
	return center
