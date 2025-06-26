extends CharacterBody3D

@export var speed = 5.0
var velocity = Vector3.ZERO

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		
		# Rotate character to face movement direction
		var target_rotation = Vector3.UP.angle_to(input_dir)
		# Better approach: Use look_at or set rotation directly
		look_at(global_position + input_dir, Vector3.UP)
		
		# Move character in input direction
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
	else:
		velocity.x = lerp(velocity.x, 0, 0.1)
		velocity.z = lerp(velocity.z, 0, 0.1)

	velocity = move_and_slide(velocity, Vector3.UP)
