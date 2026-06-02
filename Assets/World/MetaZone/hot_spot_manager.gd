extends Node3D

var hotspot_y = sheets_globals.water_level

@onready var zones: Array[CollisionShape3D] = [
	$"../FishingZoneMain",
	$"../FishingZoneLeft",
	$"../FishingZoneRight"
]

@onready var hotspots: Array[Marker3D] = [
	$HotSpot_1,
	$HotSpot_2,
	$HotSpot_3,
	$HotSpot_4,
	$HotSpot_5,
	$HotSpot_6,
	$HotSpot_7
]


func _ready() -> void:
	_mix_hotspot()


func _mix_hotspot() -> void:
	for hotspot in hotspots:
		var zone: CollisionShape3D = zones.pick_random() # Ran between three zones
		hotspot.global_position = _get_random_point_in_zone(zone)


func _get_random_point_in_zone(zone: CollisionShape3D) -> Vector3:
	var shape := zone.shape as BoxShape3D
	var half_size := shape.size * 0.5 # Finds global position base on center of box shape.

	var local_point := Vector3(
		randf_range(-half_size.x, half_size.x),
		0.0,
		randf_range(-half_size.z, half_size.z)
	)

	var world_point := zone.global_transform * local_point
	world_point.y = hotspot_y

	return world_point
