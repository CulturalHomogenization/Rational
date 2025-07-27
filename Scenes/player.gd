extends CharacterBody3D

const SPEED := 5.0
const TURN_SPEED := 8.0
const GRAVITY := 20.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interact: Label3D = $InteractRay/Interact
@onready var interact_ray: RayCast3D = $InteractRay

func _push_away_rigid_bodies():
	for i in  get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			const MASS = 80
			var mass_ratio = min(1., MASS / c.get_collider().mass)
			push_dir.y = 0
			var push_force = mass_ratio * 3
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)

func _physics_process(delta):
	var direction := Vector3.ZERO

	if Input.is_action_pressed("up"):
		direction.z -= 1
	if Input.is_action_pressed("down"):
		direction.z += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1

	direction = direction.normalized()

	# Movement
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	_push_away_rigid_bodies()
	move_and_slide()

	# Smooth rotation facing movement
	if direction != Vector3.ZERO:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, TURN_SPEED * delta)

	if anim_player:
		if direction != Vector3.ZERO:
			if anim_player.current_animation != "Running_A":
				anim_player.play("Running_A")
		else:
			if anim_player.current_animation != "Idle":
				anim_player.play("Idle")
	
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Interactable:
			interact.text = collider.get_prompt()
			if Input.is_action_just_pressed(collider.prompt_input):
				collider.interact(owner)
	else:
		interact.text = ""
		
