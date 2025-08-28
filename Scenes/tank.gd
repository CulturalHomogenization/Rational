# TankController.gd
# World of Tanks style control - turret follows camera aim point
# Attach this script to your Tank node (VehicleBody3D)

extends VehicleBody3D

@export var turret_rotation_speed: float = 90.0  # degrees per second
@export var barrel_rotation_speed: float = 45.0  # degrees per second
@export var max_barrel_elevation: float = 0.0   # degrees up (positive)
@export var max_barrel_depression: float = 40.0  # degrees down (will be made negative)
@export var camera_distance: float = 10.0
@export var camera_height: float = 3.0
@export var mouse_sensitivity: float = 2.0

# Node references
@onready var turret: Node3D = $Turret
@onready var barrel: Node3D = $Turret/Barrel
@onready var camera: Camera3D

var camera_yaw: float = 0.0
var camera_pitch: float = 0.0
var aim_point: Vector3

func _ready():
	# Get the main camera from the scene
	camera = get_viewport().get_camera_3d()
	
	# Don't capture mouse - keep it visible for aiming

func _process(delta):
	calculate_aim_point()
	rotate_turret_to_aim_point(delta)
	rotate_barrel_to_aim_point(delta)

func calculate_aim_point():
	# Get mouse position in viewport and cast ray from camera
	var mouse_pos = get_viewport().get_mouse_position()
	
	if camera:
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_direction = camera.project_ray_normal(mouse_pos)
		
		# Cast ray from camera through mouse position
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_origin + ray_direction * 1000.0
		)
		
		var result = space_state.intersect_ray(query)
		
		if result:
			aim_point = result.position
		else:
			# If no collision, project onto a plane at barrel height
			var barrel_height = barrel.global_position.y
			var t = (barrel_height - ray_origin.y) / ray_direction.y
			
			if t > 0:
				aim_point = ray_origin + ray_direction * t
			else:
				# Fallback to distant point in ray direction
				aim_point = ray_origin + ray_direction * 100.0

func rotate_turret_to_aim_point(delta):
	# Calculate horizontal direction from turret to aim point
	var turret_pos = turret.global_position
	var horizontal_dir = Vector3(
		aim_point.x - turret_pos.x,
		0.0,
		aim_point.z - turret_pos.z
	).normalized()
	
	if horizontal_dir.length() > 0.01:
		# Calculate target yaw angle for turret with 90 degree offset correction
		var target_yaw = atan2(horizontal_dir.x, horizontal_dir.z) + PI/2
		var current_yaw = turret.rotation.y
		
		# Calculate shortest rotation path
		var yaw_diff = angle_difference(current_yaw, target_yaw)
		
		# Smooth rotation with speed limit
		var max_rotation = deg_to_rad(turret_rotation_speed) * delta
		var rotation_step = clamp(yaw_diff, -max_rotation, max_rotation)
		
		turret.rotation.y += rotation_step

func rotate_barrel_to_aim_point(delta):
	# Calculate elevation angle from barrel to aim point
	var barrel_pos = barrel.global_position
	var direction = aim_point - barrel_pos
	var horizontal_distance = Vector3(direction.x, 0, direction.z).length()
	
	if horizontal_distance > 0.01:
		# Calculate pitch angle (flipped - negative for up, positive for down)
		var target_pitch = -atan2(direction.y, horizontal_distance)
		
		# Clamp to barrel limits (depression is negative, elevation is positive)
		target_pitch = clamp(target_pitch, 
						   deg_to_rad(-max_barrel_depression),  # negative for depression
						   deg_to_rad(max_barrel_elevation))    # positive for elevation
		
		var current_pitch = barrel.rotation.z  # Still Z-axis
		var pitch_diff = angle_difference(current_pitch, target_pitch)
		
		# Smooth rotation with speed limit
		var max_rotation = deg_to_rad(barrel_rotation_speed) * delta
		var rotation_step = clamp(pitch_diff, -max_rotation, max_rotation)
		
		barrel.rotation.z += rotation_step
		
		# Debug print to see if barrel is trying to move
		if abs(pitch_diff) > 0.01:
			print("Barrel target: ", rad_to_deg(target_pitch), " current: ", rad_to_deg(current_pitch), " diff: ", rad_to_deg(pitch_diff))

func angle_difference(from_angle: float, to_angle: float) -> float:
	var diff = to_angle - from_angle
	while diff > PI:
		diff -= 2.0 * PI
	while diff < -PI:
		diff += 2.0 * PI
	return diff

func _unhandled_input(event):
	# Optional: Add other input handling here if needed
	pass
