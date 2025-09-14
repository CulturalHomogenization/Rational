extends CharacterBody3D

const SPEED := 5.0
const TURN_SPEED := 8.0
const GRAVITY := 20.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var interact: Label3D = $InteractArea/Interact
@onready var interact_area: Area3D = $InteractArea
@onready var hold_marker: Marker3D = $hold
@onready var UpgradeMenu: SubViewportContainer = $"../CanvasLayer/SubViewportContainer"
@export var debug_wall_checks: bool = true
@export var show_debug_mesh: bool = true
@export var debug_mesh_color: Color = Color.RED
@export var debug_mesh_duration: float = 2.0

var debug_mesh_instance: MeshInstance3D
var debug_material: StandardMaterial3D

var previous_scene_path: String = ""
var held_item : PickupItem
var closest_interactable: Interactable = null

func pickup_item(item: PickupItem):
	if held_item:
		if check_if_in_wall(held_item):
			return
		drop_item()
	
	item.is_picked_up = true
	# DON'T disable the collision shape - keep it active
	# item.collision_shape_3d.disabled = true
	
	# Change collision layer - remove from layer 1 but keep mask to detect layer 1
	item.collision_layer = 0  # Not on any layer (won't be detected by others)
	item.collision_mask = 1   # Still detects layer 1 (walls)
	
	item.global_position = hold_marker.global_position
	item.freeze = true
	held_item = item
	print("Picked up: ", item.item_name)


func drop_item():
	if held_item and not check_if_in_wall(held_item):
		# item.collision_shape_3d.disabled = false  # No longer needed
		held_item.is_picked_up = false
		
		# Restore original collision layer
		held_item.collision_layer = 3  # Back on layer 1
		held_item.collision_mask = 1   # Keep detecting layer 1
		
		held_item.linear_velocity = velocity
		held_item.freeze = false
		held_item = null
		print("Dropped item")
	elif held_item:
		print("Can't drop - would be in wall: ", held_item.id, held_item.global_position)


func check_if_in_wall(body: PickupItem) -> bool:
	var space_state = get_world_3d().direct_space_state
	var collision_node = body.get_node("CollisionShape3D")
	
	if not collision_node or not collision_node.shape:
		return false
	
	# Create expanded collision query to catch "inside wall" cases
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = collision_node.shape
	query.transform = body.global_transform * collision_node.transform
	query.transform = query.transform.scaled(Vector3(1.05, 1.05, 1.05))
	query.collision_mask = 1
	query.exclude = [body, self]
	
	# Method 1: Expanded shape check
	var results = space_state.intersect_shape(query, 32)
	for result in results:
		var collider = result.collider
		if collider is StaticBody3D or collider is RigidBody3D:
			return true
	
	# Method 2: Raycast fallback for edge cases
	var center = query.transform.origin
	var directions = [
		Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK
	]
	
	for direction in directions:
		var ray_query = PhysicsRayQueryParameters3D.create(center, center + direction * 0.5)
		ray_query.collision_mask = 1
		ray_query.exclude = [body, self]
		
		var ray_result = space_state.intersect_ray(ray_query)
		if ray_result and (ray_result.collider is StaticBody3D or ray_result.collider is RigidBody3D):
			return true
	
	return false

func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D and c.get_collider() != held_item:
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

	var bodies = interact_area.get_overlapping_bodies()
	var areas = interact_area.get_overlapping_areas()
	var all_objects = bodies + areas
	
	closest_interactable = null
	var closest_distance = INF
	
	for obj in all_objects:
		if obj is Interactable:
			var distance = global_position.distance_to(obj.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_interactable = obj
	
	if closest_interactable != null:
		if held_item and closest_interactable is PickupItem and closest_interactable != held_item:
			# Holding item + looking at pickup = swap
			var key_name = ""
			for event in InputMap.action_get_events("interact"):
				if event is InputEventKey:
					key_name = event.as_text_physical_keycode()
					break
			interact.text = "Swap [" + key_name + "]"
			var pressed_action = closest_interactable.get_pressed_action()
			if pressed_action == "pickup":
				drop_item()
				pickup_item(closest_interactable)
		else:
			# All other cases: show the object's prompt and handle its interactions
			interact.text = closest_interactable.get_prompt()
			var pressed_action = closest_interactable.get_pressed_action()
			if pressed_action == "pickup" and closest_interactable is PickupItem and not closest_interactable.is_picked_up and not held_item:
				pickup_item(closest_interactable)
			elif pressed_action != "" and pressed_action != "pickup":
				closest_interactable.interact(self, pressed_action)
	else:
		# Not looking at anything
		if held_item:
			var key_name = ""
			for event in InputMap.action_get_events("interact"):
				if event is InputEventKey:
					key_name = event.as_text_physical_keycode()
					break
			interact.text = "Drop [" + key_name + "]"
			if Input.is_action_just_pressed("interact"):
				drop_item()
		else:
			interact.text = ""

	if held_item:
		held_item.global_position = hold_marker.global_position
		held_item.global_rotation = Vector3.ZERO

func _on_button_pressed() -> void:
	UpgradeMenu.visible = false
