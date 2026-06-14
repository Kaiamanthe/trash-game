extends Node3D

var hotspot_y = sheets_globals.water_level

@onready var Hotspot_Timer: Timer = $"../Timer"

@onready var zones: Array[CollisionShape3D] = [
	$"../FishingZoneMain",
	$"../FishingZoneLeft",
	$"../FishingZoneRight"
]

@onready var hotspots: Array[Area3D] = [
	$HotSpot_1,
	$HotSpot_2,
	$HotSpot_3,
	$HotSpot_4,
	$HotSpot_5,
	$HotSpot_6,
	$HotSpot_7
]

func _ready() -> void:
	Hotspot_Timer.wait_time = 30.0
	Hotspot_Timer.one_shot = false
	Hotspot_Timer.timeout.connect(_on_hotspot_timer_timeout)

	_mix_hotspot()
	Hotspot_Timer.start()

func _process(_delta: float) -> void:
	pass

func _on_hotspot_timer_timeout() -> void:
	_mix_hotspot()

func _mix_hotspot() -> void:
	for hotspot in hotspots:
		var zone: CollisionShape3D = zones.pick_random()

		hotspot.global_position = _get_random_point_in_zone(zone)

	print("Hotspots moved.")

func _get_random_point_in_zone(zone: CollisionShape3D) -> Vector3:
	var shape := zone.shape as BoxShape3D
	var half_size := shape.size * 0.5

	var local_point := Vector3(
		randf_range(-half_size.x, half_size.x),
		0.0,
		randf_range(-half_size.z, half_size.z)
	)

	var world_point := zone.global_transform * local_point
	world_point.y = hotspot_y

	return world_point
