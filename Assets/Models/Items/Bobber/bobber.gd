extends CharacterBody3D

var in_water := false
var buoyancy_time := 0
var water_y = 0.0


func _physics_process(delta):
	if not in_water:
		velocity.y -= sheets_globals.gravity * delta
	else:
		buoyancy_time += delta
		
		# buoyancy sim
		var target_y = water_y + sin(buoyancy_time * 2) * 0.15
		global_position = lerp(global_position.y, target_y, delta * 3.0)
		
		velocity.x = lerp(velocity.x, 0.0, delta * 2.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 2.0)
		velocity.y = 0.0
		
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.collision_layer & sheets_globals.terrain_layer:
				move_and_slide()
			
			if collider.collision_layer &  sheets_globals.water_layer:
				in_water = true
				water_y = collision.get_position().y
				velocity *= 0.25
		
