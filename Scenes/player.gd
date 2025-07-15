extends CharacterBody3D

@export var speed: float = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed: float = 10.0

func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_dir = input_dir.normalized()

	var direction = Vector3(input_dir.x, 0, input_dir.y)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if direction.length() > 0.1:
		var current_facing = -transform.basis.z
		var target_facing = direction.normalized()
		var angle = current_facing.signed_angle_to(target_facing, Vector3.UP)
		rotate_y(angle * delta * rotation_speed)

	move_and_slide()
