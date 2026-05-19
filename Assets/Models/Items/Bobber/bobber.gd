extends CharacterBody3D

var gravity := 9.8

func _physics_process(delta):
	velocity.y -= gravity * delta
	move_and_slide()
