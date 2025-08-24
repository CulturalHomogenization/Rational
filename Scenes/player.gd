extends CharacterBody3D

const SPEED := 5.0
const TURN_SPEED := 8.0
const GRAVITY := 20.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interact: Label3D = $InteractRay/Interact
@onready var interact_ray: RayCast3D = $InteractRay
@onready var hold_marker: Marker3D = $hold
@onready var UpgradeMenu: SubViewportContainer = $"../CanvasLayer/SubViewportContainer"

var previous_scene_path: String = ""
var held_item : PickupItem

func pickup_item(item: PickupItem):
	if held_item:
		drop_item()
	
	item.is_picked_up = true
	item.collision_shape_3d.disabled = true
	item.global_position = hold_marker.global_position
	held_item = item
	print("Picked up: ", item.item_name)

func drop_item():
	if held_item:
		held_item.collision_shape_3d.disabled = false
		held_item.is_picked_up = false
		held_item = null
		print("Dropped item")

func check_if_in_wall(body : PickupItem) -> bool:
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

	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Interactable:
			if held_item and collider.has_method("accepts_item") and collider.accepts_item(held_item.id):
				interact.text = collider.get_prompt()
				var pressed_action = collider.get_pressed_action()
				if pressed_action != "":
					collider.interact(self, pressed_action)
			elif not held_item and collider is PickupItem and not collider.is_picked_up:
				interact.text = collider.get_prompt()
				var pressed_action = collider.get_pressed_action()
				if pressed_action == "pickup":
					pickup_item(collider)
			elif not held_item and not (collider is PickupItem):
				interact.text = collider.get_prompt()
				var pressed_action = collider.get_pressed_action()
				if pressed_action != "":
					collider.interact(self, pressed_action)
			elif held_item and (collider is PickupItem):
				var key_name = ""
				for event in InputMap.action_get_events("interact"):
					if event is InputEventKey:
						key_name = event.as_text_physical_keycode()
						break
				interact.text = "Swap [" + key_name + "]"
				var pressed_action = collider.get_pressed_action()
				if pressed_action == "pickup":
					drop_item()
					pickup_item(collider)
				
	else:
		if held_item != null:
			var key_name = ""
			for event in InputMap.action_get_events("interact"):
				if event is InputEventKey:
					key_name = event.as_text_physical_keycode()
					break
			interact.text = "Drop [" + key_name + "]"
			var pressed_action = held_item.get_pressed_action()
			if held_item.get_pressed_action() == "pickup":
				drop_item()
		else:
			interact.text = ""

	if held_item:
		held_item.global_position = hold_marker.global_position
		held_item.global_rotation = Vector3.ZERO

func _on_button_pressed() -> void:
	UpgradeMenu.visible = false
