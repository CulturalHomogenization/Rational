extends Node3D
class_name NonCrossingBezierCurve

## Generates a random Bézier curve that never crosses itself
## Creates a smooth, winding path from start to end point (left/right only)
## Now with solidify effect - creates parallel curves on both sides

# Path Parameters
@export_group("Path Settings")
@export var start_point: Vector3 = Vector3.ZERO : set = set_start_point
@export var end_point: Vector3 = Vector3(300, 0, 0) : set = set_end_point
@export var path_complexity: int = 100 : set = set_path_complexity # Number of segments
@export var curve_intensity: float = 0.4 : set = set_curve_intensity # How curvy the path is

# Solidify Parameters
@export_group("Solidify")
@export var solidify_width: float = 0.5 : set = set_solidify_width # Width of solidify effect
@export var create_solidify: bool = true : set = set_create_solidify # Enable/disable solidify

# Generation Parameters
@export_group("Generation")
@export var path_width: float = 30.0 : set = set_path_width # How wide the path can deviate left/right
@export var smoothness: float = 1 : set = set_smoothness # Control point smoothness (0-1)
@export var avoid_sharp_turns: bool = true : set = set_avoid_sharp_turns

# Randomization
@export_group("Randomization")
@export var random_seed: int = 0 : set = set_random_seed
@export var auto_generate: bool = true
@export var generate_on_ready: bool = true

# Advanced Settings
@export_group("Advanced")
@export var self_intersection_checks: int = 20 : set = set_intersection_checks
@export var max_generation_attempts: int = 50 : set = set_max_attempts
@export var debug_visualize: bool = false : set = set_debug_visualize

# Private variables
var curve_3d: Curve3D
var left_curve: Curve3D
var right_curve: Curve3D
var rng: RandomNumberGenerator

@onready var path_3d: Path3D = $Path3D

func _ready():
	if generate_on_ready:
		setup_rng()
		generate_curve()
	self.curve = get_curve()
	
	# Assign the second curve to child Path3D
	if create_solidify and path_3d and right_curve:
		path_3d.curve = right_curve

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		regenerate()
		self.curve = get_curve()
		# Update child Path3D with second curve
		if create_solidify and path_3d and right_curve:
			path_3d.curve = right_curve

func setup_rng():
	rng = RandomNumberGenerator.new()
	rng.seed = random_seed

func generate_curve():
	if not rng:
		setup_rng()
	
	var attempts = 0
	var success = false
	
	while attempts < max_generation_attempts and not success:
		curve_3d = Curve3D.new()
		success = generate_non_crossing_curve()
		attempts += 1
		
		if not success:
			print("Attempt ", attempts, " failed - regenerating...")
	
	if success:
		smooth_curve(1)  # Optional, for extra smoothing
		print("Curve generated successfully in ", attempts, " attempts")
		
		# Generate solidify curves
		if create_solidify:
			generate_solidify_curves()
			# Assign second curve to child Path3D
			if path_3d and right_curve:
				path_3d.curve = right_curve
		
		if debug_visualize:
			create_debug_visualization()
	else:
		print("Failed to generate non-crossing curve after ", max_generation_attempts, " attempts")
		generate_simple_fallback()

func generate_solidify_curves():
	if not curve_3d:
		return
	
	left_curve = Curve3D.new()
	right_curve = Curve3D.new()
	
	var curve_length = curve_3d.get_baked_length()
	if curve_length <= 0:
		return
	
	# Sample points along the curve and calculate normals
	var sample_count = curve_3d.get_point_count() * 10 # More samples for smoother result
	
	for i in range(sample_count):
		var t = float(i) / float(sample_count - 1)
		var distance = t * curve_length
		
		# Get position on curve
		var pos = curve_3d.sample_baked(distance)
		
		# Calculate normal by getting tangent and rotating 90 degrees in horizontal plane
		var tangent = Vector3.ZERO
		if i == 0:
			# First point - look forward
			var next_pos = curve_3d.sample_baked(distance + 1.0)
			tangent = (next_pos - pos).normalized()
		elif i == sample_count - 1:
			# Last point - look backward
			var prev_pos = curve_3d.sample_baked(distance - 1.0)
			tangent = (pos - prev_pos).normalized()
		else:
			# Middle points - average of forward and backward
			var next_pos = curve_3d.sample_baked(distance + 1.0)
			var prev_pos = curve_3d.sample_baked(distance - 1.0)
			tangent = (next_pos - prev_pos).normalized()
		
		# Calculate normal (perpendicular to tangent in horizontal plane)
		tangent.y = 0 # Keep in horizontal plane
		tangent = tangent.normalized()
		var normal = Vector3.UP.cross(tangent).normalized()
		
		# Create left and right points
		var left_point = pos - normal * solidify_width * 0.5
		var right_point = pos + normal * solidify_width * 0.5
		
		left_curve.add_point(left_point)
		right_curve.add_point(right_point)

func generate_non_crossing_curve() -> bool:
	# Generate waypoints that only deviate left and right
	var waypoints = generate_horizontal_waypoints()
	
	# Convert waypoints to Bézier curve points
	if not create_bezier_from_waypoints(waypoints):
		return false
	
	# Check for self-intersections in the horizontal plane
	if has_horizontal_intersections():
		return false
	
	return true

func generate_horizontal_waypoints() -> PackedVector3Array:
	var waypoints = PackedVector3Array()
	waypoints.append(start_point)
	
	# Calculate the forward direction and right vector
	var forward_direction = (end_point - start_point).normalized()
	var right_vector = Vector3.UP.cross(forward_direction).normalized()
	
	# Track cumulative deviation to prevent excessive wandering
	var cumulative_deviation = 0.0
	var previous_deviation = 0.0
	
	# Generate intermediate waypoints
	for i in range(1, path_complexity):
		var t = float(i) / float(path_complexity)
		
		# Base position along main direction
		var base_pos = start_point.lerp(end_point, t)
		
		# Calculate deviation strength (stronger in middle, weaker at ends)
		var deviation_strength = sin(t * PI) * path_width
		
		# Generate random deviation with bias to return toward center
		var target_deviation = rng.randf_range(-deviation_strength, deviation_strength)
		
		# Apply smoothing and prevent excessive wandering
		var smoothing_factor = 0.3
		var return_bias = -cumulative_deviation * 0.2 # Bias toward returning to center
		var smooth_deviation = previous_deviation * smoothing_factor + target_deviation * (1.0 - smoothing_factor) + return_bias
		
		# Clamp deviation to prevent going too far off course
		smooth_deviation = clamp(smooth_deviation, -deviation_strength, deviation_strength)
		
		# Apply additional noise for natural variation
		var noise_deviation = sin(t * PI * 1.5 + rng.randf() * TAU) * deviation_strength * 0.05
		var final_deviation = smooth_deviation + noise_deviation
		
		# Create the waypoint (only horizontal deviation)
		var offset = right_vector * final_deviation
		var waypoint = base_pos + offset
		waypoint.y = base_pos.y # Ensure no vertical deviation
		
		waypoints.append(waypoint)
		
		# Update tracking variables
		cumulative_deviation += final_deviation * 0.1
		previous_deviation = final_deviation
	
	waypoints.append(end_point)
	return waypoints

func create_bezier_from_waypoints(waypoints: PackedVector3Array) -> bool:
	if waypoints.size() < 2:
		return false

	curve_3d.clear_points()

	var main_forward = (end_point - start_point).normalized()
	var main_right = Vector3.UP.cross(main_forward).normalized()

	for i in range(waypoints.size()):
		var point = waypoints[i]
		var in_handle = Vector3.ZERO
		var out_handle = Vector3.ZERO

		if i > 0 and i < waypoints.size() - 1:
			var prev_point = waypoints[i - 1]
			var next_point = waypoints[i + 1]

			var local_forward = (next_point - prev_point).normalized()
			local_forward.y = 0
			local_forward = local_forward.normalized()

			var distance_prev = Vector2(point.x - prev_point.x, point.z - prev_point.z).length()
			var distance_next = Vector2(next_point.x - point.x, next_point.z - point.z).length()
			var avg_distance = (distance_prev + distance_next) * 0.5

			var handle_length = avg_distance * smoothness * curve_intensity

			if avoid_sharp_turns:
				var prev_dir = Vector2(point.x - prev_point.x, point.z - prev_point.z).normalized()
				var next_dir = Vector2(next_point.x - point.x, next_point.z - point.z).normalized()
				var angle = prev_dir.angle_to(next_dir)
				var angle_factor = pow(1.0 - (abs(angle) / PI), 2)
				handle_length *= lerp(0.1, 1.0, angle_factor)

			in_handle = -local_forward * handle_length
			out_handle = local_forward * handle_length

			var random_angle = rng.randf_range(-0.2, 0.2) * curve_intensity
			in_handle = Vector3(
				in_handle.x * cos(random_angle) - in_handle.z * sin(random_angle),
				0,
				in_handle.x * sin(random_angle) + in_handle.z * cos(random_angle)
			)
			out_handle = Vector3(
				out_handle.x * cos(-random_angle) - out_handle.z * sin(-random_angle),
				0,
				out_handle.x * sin(-random_angle) + out_handle.z * cos(-random_angle)
			)

		curve_3d.add_point(point, in_handle, out_handle)

	return true

func has_horizontal_intersections() -> bool:
	if not curve_3d or curve_3d.get_point_count() < 3:
		return false
	
	var curve_length = curve_3d.get_baked_length()
	if curve_length <= 0:
		return false
	
	var check_step = curve_length / float(self_intersection_checks * path_complexity)
	var positions_2d = PackedVector2Array()
	
	# Sample points along the curve (convert to 2D horizontal plane)
	for i in range(self_intersection_checks * path_complexity):
		var distance = i * check_step
		var pos_3d = curve_3d.sample_baked(distance)
		var pos_2d = Vector2(pos_3d.x, pos_3d.z)
		positions_2d.append(pos_2d)
	
	# Check for intersections using line segment intersection
	for i in range(positions_2d.size() - 1):
		var line1_start = positions_2d[i]
		var line1_end = positions_2d[i + 1]
		
		# Check against non-adjacent segments
		for j in range(i + 3, positions_2d.size() - 1):
			# Don't check the very end against the very beginning
			if i == 0 and j >= positions_2d.size() - 3:
				continue
				
			var line2_start = positions_2d[j]
			var line2_end = positions_2d[j + 1]
			
			if lines_intersect_2d(line1_start, line1_end, line2_start, line2_end):
				return true
	
	return false

func lines_intersect_2d(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
	"""Check if two 2D line segments intersect"""
	var denominator = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
	
	if abs(denominator) < 1e-10:
		return false # Lines are parallel
	
	var t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denominator
	var u = -((p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x)) / denominator
	
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0

func generate_simple_fallback():
	"""Generate a simple curved path when complex generation fails"""
	curve_3d = Curve3D.new()
	curve_3d.clear_points()
	
	var forward = (end_point - start_point).normalized()
	var right = Vector3.UP.cross(forward).normalized()
	
	# Create a simple S-curve
	var quarter_point = start_point.lerp(end_point, 0.33)
	quarter_point += right * rng.randf_range(-path_width * 0.3, path_width * 0.3)
	quarter_point.y = start_point.y
	
	var three_quarter_point = start_point.lerp(end_point, 0.67)
	three_quarter_point += right * rng.randf_range(-path_width * 0.3, path_width * 0.3)
	three_quarter_point.y = end_point.y
	
	curve_3d.add_point(start_point)
	curve_3d.add_point(quarter_point)
	curve_3d.add_point(three_quarter_point)
	curve_3d.add_point(end_point)
	
	# Generate solidify curves for fallback too
	if create_solidify:
		generate_solidify_curves()
		# Assign second curve to child Path3D
		if path_3d and right_curve:
			path_3d.curve = right_curve
	
	print("Generated fallback curve")
	
func smooth_curve(iterations: int = 1):
	"""Optional: Post-smooth the curve using a simplified Chaikin algorithm"""
	for _i in range(iterations):
		var new_positions = []
		for j in range(curve_3d.get_point_count() - 1):
			var p0 = curve_3d.get_point_position(j)
			var p1 = curve_3d.get_point_position(j + 1)
			var q = p0.lerp(p1, 0.25)
			var r = p0.lerp(p1, 0.75)
			new_positions.append(q)
			new_positions.append(r)

		curve_3d.clear_points()
		for pt in new_positions:
			curve_3d.add_point(pt)

func create_debug_visualization():
	"""Create debug visualization of all curves"""
	# Remove existing debug nodes
	for child in get_children():
		if child.name.begins_with("Debug"):
			child.queue_free()
	
	if not curve_3d:
		return
	
	# Create debug spheres at curve points
	for i in range(curve_3d.get_point_count()):
		var point_pos = curve_3d.get_point_position(i)
		var color = Color.RED if i == 0 or i == curve_3d.get_point_count() - 1 else Color.WHITE
		var debug_sphere = create_debug_sphere(point_pos, color)
		debug_sphere.name = "Debug_Point_" + str(i)
		add_child(debug_sphere)
		
		# Visualize control handles
		var in_handle = curve_3d.get_point_in(i)
		var out_handle = curve_3d.get_point_out(i)
		
		if in_handle.length() > 0.1:
			var in_sphere = create_debug_sphere(point_pos + in_handle, Color.GREEN, 0.2)
			in_sphere.name = "Debug_In_Handle_" + str(i)
			add_child(in_sphere)
		
		if out_handle.length() > 0.1:
			var out_sphere = create_debug_sphere(point_pos + out_handle, Color.YELLOW, 0.2)
			out_sphere.name = "Debug_Out_Handle_" + str(i)
			add_child(out_sphere)
	
	# Create path visualizations
	create_path_visualization(curve_3d, Color.WHITE, "Main")
	
	if create_solidify and left_curve and right_curve:
		create_path_visualization(left_curve, Color.RED, "Left")
		create_path_visualization(right_curve, Color.BLUE, "Right")

func create_path_visualization(curve: Curve3D, color: Color, name_suffix: String):
	"""Create a visual representation of a curve path"""
	if not curve or curve.get_point_count() < 2:
		return
	
	var path_viz = MeshInstance3D.new()
	path_viz.name = "Debug_Path_" + name_suffix
	
	var curve_length = curve.get_baked_length()
	var segments = int(curve_length * 2) # 2 segments per unit
	segments = max(10, min(segments, 200)) # Clamp between 10 and 200
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Sample points along the curve
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var distance = t * curve_length
		var pos = curve.sample_baked(distance)
		vertices.append(pos)
		
		if i < segments:
			indices.append(i)
			indices.append(i + 1)
	
	# Create line mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	path_viz.mesh = array_mesh
	
	add_child(path_viz)

func create_debug_sphere(pos: Vector3, color: Color, size: float = 0.5) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size
	sphere_mesh.height = size * 2
	mesh_instance.mesh = sphere_mesh
	
	mesh_instance.position = pos
	return mesh_instance

# Property setters
func set_start_point(value: Vector3):
	start_point = value
	if auto_generate and is_inside_tree():
		generate_curve()

func set_end_point(value: Vector3):
	end_point = value
	if auto_generate and is_inside_tree():
		generate_curve()

func set_path_complexity(value: int):
	path_complexity = max(2, value)
	if auto_generate and is_inside_tree():
		generate_curve()

func set_curve_intensity(value: float):
	curve_intensity = max(0.1, value)
	if auto_generate and is_inside_tree():
		generate_curve()

func set_path_width(value: float):
	path_width = max(0.1, value)
	if auto_generate and is_inside_tree():
		generate_curve()

func set_solidify_width(value: float):
	solidify_width = max(0.1, value)
	if auto_generate and is_inside_tree():
		generate_curve()

func set_create_solidify(value: bool):
	create_solidify = value
	if auto_generate and is_inside_tree():
		generate_curve()

func set_smoothness(value: float):
	smoothness = clamp(value, 0.0, 1.0)
	if auto_generate and is_inside_tree():
		generate_curve()

func set_avoid_sharp_turns(value: bool):
	avoid_sharp_turns = value
	if auto_generate and is_inside_tree():
		generate_curve()

func set_random_seed(value: int):
	random_seed = value
	if rng:
		rng.seed = value
	if auto_generate and is_inside_tree():
		generate_curve()

func set_intersection_checks(value: int):
	self_intersection_checks = max(5, value)

func set_max_attempts(value: int):
	max_generation_attempts = max(1, value)

func set_debug_visualize(value: bool):
	debug_visualize = value
	if is_inside_tree():
		if debug_visualize and curve_3d:
			create_debug_visualization()
		else:
			# Remove debug visualization
			for child in get_children():
				if child.name.begins_with("Debug"):
					child.queue_free()

# Utility functions
func get_curve() -> Curve3D:
	"""Get the generated Curve3D object"""
	return curve_3d

func get_left_curve() -> Curve3D:
	"""Get the left solidify curve"""
	return left_curve

func get_right_curve() -> Curve3D:
	"""Get the right solidify curve"""
	return right_curve

func get_curve_length() -> float:
	"""Get the total length of the curve"""
	if curve_3d:
		return curve_3d.get_baked_length()
	return 0.0

func get_position_at_distance(distance: float) -> Vector3:
	"""Get position along curve at specific distance"""
	if curve_3d:
		return curve_3d.sample_baked(distance)
	return Vector3.ZERO

func get_position_at_progress(progress: float) -> Vector3:
	"""Get position along curve at progress (0.0 to 1.0)"""
	if curve_3d:
		var distance = progress * curve_3d.get_baked_length()
		return curve_3d.sample_baked(distance)
	return Vector3.ZERO

func regenerate():
	"""Manually regenerate the curve"""
	generate_curve()

func randomize_seed():
	"""Generate a random seed and regenerate"""
	random_seed = randi()
	generate_curve()
