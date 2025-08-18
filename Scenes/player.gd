extends CharacterBody3D

const SPEED := 5.0
const TURN_SPEED := 8.0
const GRAVITY := 20.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interact: Label3D = $InteractRay/Interact
@onready var interact_ray: RayCast3D = $InteractRay
@onready var hold_marker: Marker3D = $hold

var previous_scene_path: String = ""
var picked_up_item : RigidBody3D

func pick_object():
	var collider = interact_ray.get_collider()
	if collider != null and collider.is_in_group("pickup"):
		picked_up_item = collider
		print(picked_up_item)

func remove_object():
	if picked_up_item != null:
		picked_up_item.collision_shape_3d.disabled = false
		picked_up_item = null

func check_if_in_wall(body :RigidBody3D) -> bool:
	var space_state :PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collision_node :CollisionShape3D = body.get_node("CollisionShape3D")
	var query :PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = collision_node.shape
	query.transform = body.global_transform
	query.transform = query.transform.scaled(Vector3(0.95,0.95,0.95))
	query.collision_mask = 1  # Adjust to match the wall's layer mask
	query.exclude = [body]    # Avoid detecting itself

	var results :Array[Dictionary] = space_state.intersect_shape(query, 32)
	print(results)
	for result in results:
		var collider :Object = result.collider
		if collider is StaticBody3D or collider is RigidBody3D:
			return false
	return true

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
	
	if picked_up_item == null:
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider is Interactable:
				interact.text = collider.get_prompt()
				if Input.is_action_just_pressed(collider.prompt_input):
					collider.interact(self)
					if collider.is_in_group("pickup"):
						if picked_up_item == null:
							pick_object()
		else:
			interact.text = ""

	elif picked_up_item != null:
		picked_up_item.global_position = hold_marker.global_position
		picked_up_item.global_rotation = Vector3.ZERO
		if Input.is_action_just_pressed("interact"):
			if check_if_in_wall(picked_up_item) == true:
				remove_object()

func _on_tech_station_interacted(body: Variant) -> void:
	SceneManager.switch_to_upgrade_menu()
