extends MeshInstance3D

# Valley parameters
@export var valley_length: float = 30000.0
@export var valley_base_width: float = 50.0
@export var valley_min_width: float = 25.0
@export var valley_max_width: float = 75.0
@export var valley_depth: float = 100.0
@export var wall_steepness: float = 0.8

# Wide sections parameters
@export var wide_section_width: float = 300.0
@export var wide_section_length: float = 300.0
@export var num_wide_sections: int = 5
@export var transition_smoothness: float = 0.3

# Mesh detail
@export var path_resolution: int = 1000
@export var width_segments: int = 20
@export var wall_noise_strength: float = 2.0

# Floor parameters
@export var floor_resolution: int = 64
@export var floor_noise: FastNoiseLite
@export var floor_height_variation: float = 8.0

# Drunken walk parameters
@export var step_deviation: float = 500.0
@export var target_pull_strength: float = 0.7
@export var smoothing_iterations: int = 3

# Start and end points
@export var start_point: Vector3 = Vector3.ZERO
@export var end_point: Vector3 = Vector3(25000, 0, 5000)

var wall_noise: FastNoiseLite
var path_points: Array
var path_directions: Array
var path_widths: Array
var valley_bounds: Dictionary  # Will store min/max X/Z for the valley

func _ready():
	setup_noise()
	generate_valley_terrain()

func setup_noise():
	wall_noise = FastNoiseLite.new()
	wall_noise.seed = randi()
	wall_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	wall_noise.frequency = 0.01
	wall_noise.fractal_octaves = 4
	
	if not floor_noise:
		floor_noise = FastNoiseLite.new()
		floor_noise.seed = randi() + 1000
		floor_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		floor_noise.frequency = 0.02
		floor_noise.fractal_octaves = 3

func generate_valley_terrain():
	# Phase 1: Generate walls only
	var wall_vertices = PackedVector3Array()
	var wall_colors = PackedColorArray()
	var wall_indices = PackedInt32Array()
	
	generate_walls(wall_vertices, wall_colors, wall_indices)
	
	# Phase 2: Generate floor knowing where walls are
	var floor_vertices = PackedVector3Array()
	var floor_colors = PackedColorArray()
	var floor_indices = PackedInt32Array()
	
	generate_floor(floor_vertices, floor_colors, floor_indices)
	
	# Phase 3: Combine walls and floor into final mesh
	combine_meshes(wall_vertices, wall_colors, wall_indices, floor_vertices, floor_colors, floor_indices)

func generate_drunken_walk_path() -> Array:
	var points = []
	points.append(start_point)
	
	var current_pos = start_point
	
	for i in range(1, path_resolution):
		var progress = float(i) / float(path_resolution)
		
		var ideal_next = start_point.lerp(end_point, progress)
		
		var random_angle = randf() * TAU
		var deviation_distance = randf() * step_deviation
		var random_offset = Vector3(
			cos(random_angle) * deviation_distance,
			0,
			sin(random_angle) * deviation_distance
		)
		
		var next_pos = ideal_next.lerp(current_pos + random_offset, 1.0 - target_pull_strength)
		
		points.append(next_pos)
		current_pos = next_pos
	
	points.append(end_point)
	
	for iteration in range(smoothing_iterations):
		smooth_path_points(points)
	
	return points

func smooth_path_points(points: Array):
	if points.size() < 3:
		return
	
	var smoothed = points.duplicate()
	
	for i in range(1, points.size() - 1):
		var prev = points[i - 1]
		var curr = points[i]
		var next = points[i + 1]
		
		smoothed[i] = (prev + curr * 2.0 + next) * 0.25
	
	for i in range(points.size()):
		points[i] = smoothed[i]

func generate_walls(wall_vertices: PackedVector3Array, wall_colors: PackedColorArray, wall_indices: PackedInt32Array):
	# Generate path and calculate widths
	var raw_path_points = generate_drunken_walk_path()
	var raw_widths = []
	
	# Calculate base widths
	for i in range(raw_path_points.size()):
		var t = float(i) / float(raw_path_points.size() - 1)
		var width = calculate_base_width_at_position(t)
		raw_widths.append(width)
	
	# Calculate safe segment length considering wide sections
	var safe_distance = calculate_safe_segment_length(raw_path_points, raw_widths)
	
	# Resample path
	path_points = []
	path_directions = []
	path_widths = []
	
	resample_path_adaptive(raw_path_points, raw_widths, safe_distance, path_points, path_directions, path_widths)
	
	# Apply wide sections
	apply_wide_sections_to_path()
	
	# Calculate valley bounds for floor generation
	calculate_valley_bounds()
	
	# Generate wall cross-sections (only walls, no floor)
	for i in range(path_points.size()):
		var center = path_points[i]
		var forward = path_directions[i]
		var right = Vector3(-forward.z, 0, forward.x).normalized()
		var width = path_widths[i]
		
		create_wall_cross_section(wall_vertices, wall_colors, center, right, width, i)
	
	# Generate indices for walls
	generate_wall_indices(wall_indices, path_points.size())
	
	# Apply noise to walls
	apply_noise_to_wall_vertices(wall_vertices)

func calculate_base_width_at_position(t: float) -> float:
	var base_width = valley_base_width
	var width_variation = sin(t * PI * 8) * (valley_max_width - valley_min_width) * 0.3
	var noise_variation = wall_noise.get_noise_1d(t * 100) * (valley_max_width - valley_min_width) * 0.2
	return clamp(base_width + width_variation + noise_variation, valley_min_width, valley_max_width)

func apply_wide_sections_to_path():
	var wide_positions = []
	wide_positions.append(0.0)
	wide_positions.append(1.0)
	
	for i in range(num_wide_sections):
		var t = (float(i + 1) / float(num_wide_sections + 1))
		wide_positions.append(t)
	
	for wide_pos in wide_positions:
		apply_wide_section_at_position(wide_pos)

func apply_wide_section_at_position(target_t: float):
	var target_section = int(target_t * (path_points.size() - 1))
	var section_range = int(wide_section_length / (valley_length / path_points.size()))
	section_range = max(section_range, 3)
	
	var start_section = max(0, target_section - section_range / 2)
	var end_section = min(path_points.size() - 1, target_section + section_range / 2)
	
	for section_idx in range(start_section, end_section + 1):
		var distance_from_center = abs(section_idx - target_section)
		var max_distance = section_range / 2.0
		
		var blend_factor = 1.0 - (distance_from_center / max_distance)
		blend_factor = smoothstep(0.0, 1.0, blend_factor)
		
		var normal_width = calculate_base_width_at_position(float(section_idx) / float(path_points.size() - 1))
		path_widths[section_idx] = lerp(normal_width, wide_section_width, blend_factor)

func calculate_valley_bounds():
	valley_bounds = {"min_x": INF, "max_x": -INF, "min_z": INF, "max_z": -INF}
	
	for i in range(path_points.size()):
		var center = path_points[i]
		var forward = path_directions[i]
		var right = Vector3(-forward.z, 0, forward.x).normalized()
		var width = path_widths[i]
		var half_width = width * 0.5
		
		var left_point = center - right * half_width
		var right_point = center + right * half_width
		
		valley_bounds.min_x = min(valley_bounds.min_x, min(left_point.x, right_point.x))
		valley_bounds.max_x = max(valley_bounds.max_x, max(left_point.x, right_point.x))
		valley_bounds.min_z = min(valley_bounds.min_z, min(left_point.z, right_point.z))
		valley_bounds.max_z = max(valley_bounds.max_z, max(left_point.z, right_point.z))
	
	# Add some padding
	var padding = wide_section_width * 0.1
	valley_bounds.min_x -= padding
	valley_bounds.max_x += padding
	valley_bounds.min_z -= padding
	valley_bounds.max_z += padding

func create_wall_cross_section(wall_vertices: PackedVector3Array, wall_colors: PackedColorArray, center: Vector3, right: Vector3, width: float, section_index: int):
	var half_width = width * 0.5
	
	# Only create wall vertices (no floor vertices)
	for i in range(width_segments + 1):
		var t = float(i) / float(width_segments)
		var x = (t - 0.5) * width
		
		# Skip the flat bottom area - only generate walls
		if abs(x) < half_width * 0.8:
			continue  # Skip floor area
		
		# Generate wall
		var wall_t = (abs(x) - half_width * 0.8) / (half_width * 0.2)
		var y = -valley_depth + pow(wall_t, wall_steepness) * valley_depth
		
		var vertex = center + right * x + Vector3.UP * y
		wall_vertices.append(vertex)
		wall_colors.append(Color.BROWN)

func generate_floor(floor_vertices: PackedVector3Array, floor_colors: PackedColorArray, floor_indices: PackedInt32Array):
	# Calculate floor dimensions
	var floor_width = valley_bounds.max_x - valley_bounds.min_x
	var floor_depth = valley_bounds.max_z - valley_bounds.min_z
	
	# Create a plane mesh for the floor area
	var plane = PlaneMesh.new()
	plane.subdivide_depth = floor_resolution
	plane.subdivide_width = floor_resolution
	plane.size = Vector2(floor_width, floor_depth)
	
	var plane_arrays = plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	
	# Process each vertex to fit our valley and apply height variation
	for i in range(vertex_array.size()):
		var vertex = vertex_array[i]
		
		# Transform vertex to world position within valley bounds
		var world_x = vertex.x + (valley_bounds.min_x + valley_bounds.max_x) * 0.5
		var world_z = vertex.z + (valley_bounds.min_z + valley_bounds.max_z) * 0.5
		
		# Check if this point is inside the valley (not under walls)
		if is_point_inside_valley(world_x, world_z):
			# Apply noise-based height variation
			var height_offset = floor_noise.get_noise_2d(world_x, world_z) * floor_height_variation
			vertex.y = -valley_depth + height_offset
			vertex.x = world_x
			vertex.z = world_z
			
			floor_vertices.append(vertex)
			floor_colors.append(Color.GREEN)

func is_point_inside_valley(world_x: float, world_z: float) -> bool:
	# Find the closest path segment and check if point is within valley width
	var closest_distance = INF
	var is_inside = false
	
	for i in range(path_points.size() - 1):
		var seg_start = path_points[i]
		var seg_end = path_points[i + 1]
		var width = (path_widths[i] + path_widths[i + 1]) * 0.5
		
		# Calculate distance from point to line segment
		var seg_vec = seg_end - seg_start
		var point_vec = Vector3(world_x, 0, world_z) - Vector3(seg_start.x, 0, seg_start.z)
		
		var seg_length_sq = seg_vec.length_squared()
		if seg_length_sq < 0.0001:
			continue
		
		var t = clamp(point_vec.dot(Vector3(seg_vec.x, 0, seg_vec.z)) / seg_length_sq, 0.0, 1.0)
		var closest_point = Vector3(seg_start.x, 0, seg_start.z) + Vector3(seg_vec.x, 0, seg_vec.z) * t
		var distance = Vector3(world_x, 0, world_z).distance_to(closest_point)
		
		if distance < width * 0.4:  # Only include floor area (not under walls)
			is_inside = true
			break
	
	return is_inside

func calculate_safe_segment_length(points: Array, widths: Array) -> float:
	var max_width = wide_section_width
	var min_safe_distance = max_width * 1.5
	
	var max_curvature_distance = 0.0
	for i in range(1, points.size() - 1):
		var prev = points[i - 1]
		var curr = points[i]
		var next = points[i + 1]
		
		var angle = prev.direction_to(curr).angle_to(curr.direction_to(next))
		if angle > 0.1:
			var curvature_distance = max_width / sin(angle * 0.5)
			max_curvature_distance = max(max_curvature_distance, curvature_distance)
	
	return max(min_safe_distance, max_curvature_distance)

func resample_path_adaptive(raw_points: Array, raw_widths: Array, safe_distance: float, 
							out_points: Array, out_directions: Array, out_widths: Array):
	
	out_points.append(raw_points[0])
	out_widths.append(raw_widths[0])
	
	var current_raw_index = 0
	var accumulated_distance = 0.0
	var last_added_pos = raw_points[0]
	
	while current_raw_index < raw_points.size() - 1:
		current_raw_index += 1
		var current_pos = raw_points[current_raw_index]
		var segment_distance = last_added_pos.distance_to(current_pos)
		accumulated_distance += segment_distance
		
		var local_width = raw_widths[current_raw_index]
		var required_distance = max(safe_distance * 0.3, local_width * 0.8)
		
		if current_raw_index > 0 and current_raw_index < raw_points.size() - 1:
			var prev = raw_points[current_raw_index - 1]
			var curr = raw_points[current_raw_index]
			var next = raw_points[current_raw_index + 1]
			
			var angle = prev.direction_to(curr).angle_to(curr.direction_to(next))
			if angle > 0.5:
				required_distance *= 0.5
		
		if accumulated_distance >= required_distance or current_raw_index == raw_points.size() - 1:
			out_points.append(current_pos)
			out_widths.append(raw_widths[current_raw_index])
			last_added_pos = current_pos
			accumulated_distance = 0.0
	
	for i in range(out_points.size()):
		var direction: Vector3
		if i < out_points.size() - 1:
			direction = (out_points[i + 1] - out_points[i]).normalized()
		else:
			direction = out_directions[i - 1] if out_directions.size() > 0 else Vector3.FORWARD
		
		out_directions.append(direction)

func generate_wall_indices(wall_indices: PackedInt32Array, num_sections: int):
	# Note: This is a simplified version since we're only generating walls
	# The indexing will need to be adjusted based on how many vertices each cross-section actually produces
	var vertices_per_section = 0
	
	# Count vertices per section (only wall vertices)
	for i in range(width_segments + 1):
		var t = float(i) / float(width_segments)
		var x = (t - 0.5)
		var half_width = 0.5  # Normalized
		
		if abs(x) >= half_width * 0.8:  # Only walls
			vertices_per_section += 1
	
	# Generate indices for wall strips
	for section in range(num_sections - 1):
		for i in range(vertices_per_section - 1):
			var current_row = section * vertices_per_section
			var next_row = (section + 1) * vertices_per_section
			
			wall_indices.append(current_row + i)
			wall_indices.append(next_row + i)
			wall_indices.append(current_row + i + 1)
			
			wall_indices.append(current_row + i + 1)
			wall_indices.append(next_row + i)
			wall_indices.append(next_row + i + 1)

func apply_noise_to_wall_vertices(wall_vertices: PackedVector3Array):
	for i in range(wall_vertices.size()):
		var vertex = wall_vertices[i]
		var noise_offset = Vector3(
			wall_noise.get_noise_3d(vertex.x, vertex.y, vertex.z) * wall_noise_strength,
			wall_noise.get_noise_3d(vertex.x + 1000, vertex.y, vertex.z) * wall_noise_strength * 0.5,
			wall_noise.get_noise_3d(vertex.x, vertex.y, vertex.z + 1000) * wall_noise_strength
		)
		wall_vertices[i] = vertex + noise_offset

func combine_meshes(wall_vertices: PackedVector3Array, wall_colors: PackedColorArray, wall_indices: PackedInt32Array,
					floor_vertices: PackedVector3Array, floor_colors: PackedColorArray, floor_indices: PackedInt32Array):
	
	# Combine vertices and colors
	var final_vertices = PackedVector3Array()
	var final_colors = PackedColorArray()
	var final_indices = PackedInt32Array()
	
	# Add wall vertices
	final_vertices.append_array(wall_vertices)
	final_colors.append_array(wall_colors)
	
	# Add wall indices
	final_indices.append_array(wall_indices)
	
	# Add floor vertices (offset indices by wall vertex count)
	var wall_vertex_count = wall_vertices.size()
	final_vertices.append_array(floor_vertices)
	final_colors.append_array(floor_colors)
	
	# Add floor indices with offset
	for i in range(floor_indices.size()):
		final_indices.append(floor_indices[i] + wall_vertex_count)
	
	# Create final mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = final_vertices
	arrays[Mesh.ARRAY_INDEX] = final_indices
	arrays[Mesh.ARRAY_COLOR] = final_colors
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	mesh = array_mesh
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.8
	set_surface_override_material(0, material)

func regenerate():
	setup_noise()
	generate_valley_terrain()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			regenerate()
