extends MeshInstance3D

# Valley generation parameters
@export var mesh_resolution: int = 500  # Points along the curve (higher resolution)
@export var width_resolution: int = 150  # Points across the valley width (even higher for bumpy walls)
@export var valley_min_width: float = 50.0  # Minimum valley width (meters)
@export var valley_max_width: float = 100.0  # Maximum valley width (meters)
@export var camp_width: float = 200.0  # Width at enemy camp locations
@export var mountain_height: float = 80.0  # Height of hill peaks (moderate hills, not canyon walls)
@export var path_roughness: float = 3.0  # How rough the path surface is (more bumpy)
@export var noise_scale: float = 0.008  # Scale for fractal noise (finer detail)
@export var noise_octaves: int = 6  # Number of noise octaves (more detail)
@export var wall_steepness: float = 45.0  # Constant wall angle in degrees
@onready var path_3d: NonCrossingBezierCurve = $Path3D

var noise: FastNoiseLite
var scaled_curve: Curve3D
var camp_positions: Array[int] = []
var camp_world_positions: Array[Vector3] = []  # Store actual world positions of camps

func _ready():
	setup_noise()
	generate_valley_mesh()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_octaves = noise_octaves
	noise.frequency = 0.1

func generate_valley_mesh():
	# Get and scale the curve
	var original_curve = path_3d.get_curve()  # Your existing function
	scaled_curve = Curve3D.new()
	
	# Scale up the curve by 300x
	for i in range(original_curve.point_count):
		var point = original_curve.get_point_position(i) * 300.0
		var in_handle = original_curve.get_point_in(i) * 300.0
		var out_handle = original_curve.get_point_out(i) * 300.0
		
		scaled_curve.add_point(point, in_handle, out_handle)
	
	# Calculate camp positions (evenly spaced + start/end)
	calculate_camp_positions()
	
	# Generate the mesh
	var valley_mesh = create_valley_mesh()
	mesh = valley_mesh
	
	# Store camp world positions after mesh generation
	store_camp_world_positions()

func calculate_camp_positions():
	camp_positions.clear()
	var total_points = mesh_resolution
	
	# Add start position
	camp_positions.append(0)
	
	# Add 5 evenly spaced positions
	for i in range(1, 6):
		var pos = int((float(i) / 6.0) * total_points)
		camp_positions.append(pos)
	
	# Add end position
	camp_positions.append(total_points - 1)

func create_valley_mesh() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate valley cross-sections along the curve
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	# First pass: generate all vertices and UVs
	for i in range(mesh_resolution):
		var t = float(i) / float(mesh_resolution - 1)
		var curve_point = scaled_curve.sample_baked(t * scaled_curve.get_baked_length())
		var curve_forward = get_curve_forward(t)
		var curve_right = get_curve_right(curve_forward)
		
		# Determine valley width at this point
		var valley_width = get_valley_width_at_point(i)
		
		# Generate cross-section points
		for j in range(width_resolution):
			var width_t = float(j) / float(width_resolution - 1)
			var distance_from_center = (width_t - 0.5) * valley_width
			
			var world_pos = curve_point + curve_right * distance_from_center
			var height = calculate_terrain_height(world_pos, distance_from_center, valley_width, i)
			
			world_pos.y += height
			vertices.append(world_pos)
			
			# Calculate UV coordinates
			var uv = Vector2(t * 5.0, width_t * 3.0)  # Scale UVs for better texture tiling
			uvs.append(uv)
	
	# Second pass: create triangles using SurfaceTool
	for i in range(mesh_resolution - 1):
		for j in range(width_resolution - 1):
			var current = i * width_resolution + j
			var next = (i + 1) * width_resolution + j
			
			# First triangle (proper counter-clockwise winding when viewed from above)
			surface_tool.set_uv(uvs[current])
			surface_tool.add_vertex(vertices[current])
			
			surface_tool.set_uv(uvs[next])
			surface_tool.add_vertex(vertices[next])
			
			surface_tool.set_uv(uvs[current + 1])
			surface_tool.add_vertex(vertices[current + 1])
			
			# Second triangle (proper counter-clockwise winding when viewed from above)
			surface_tool.set_uv(uvs[current + 1])
			surface_tool.add_vertex(vertices[current + 1])
			
			surface_tool.set_uv(uvs[next])
			surface_tool.add_vertex(vertices[next])
			
			surface_tool.set_uv(uvs[next + 1])
			surface_tool.add_vertex(vertices[next + 1])
	
	# Generate normals and tangents automatically
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	
	return surface_tool.commit()

func get_curve_forward(t: float) -> Vector3:
	var epsilon = 0.001  # Smaller epsilon for more stable direction
	var curve_length = scaled_curve.get_baked_length()
	
	# Ensure we stay within bounds
	var t1 = max(0.0, t - epsilon)
	var t2 = min(1.0, t + epsilon)
	
	var point1 = scaled_curve.sample_baked(t1 * curve_length)
	var point2 = scaled_curve.sample_baked(t2 * curve_length)
	
	var forward = (point2 - point1).normalized()
	
	# Ensure we have a valid forward vector
	if forward.length_squared() < 0.01:
		# Fallback to a default forward direction
		forward = Vector3.FORWARD
	
	return forward

func get_curve_right(forward: Vector3) -> Vector3:
	# Use consistent up vector and ensure right vector is normalized
	var right = forward.cross(Vector3.UP).normalized()
	
	# Handle edge case where forward is parallel to UP
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	
	return right

func get_valley_width_at_point(point_index: int) -> float:
	# Check if this is a camp location
	if point_index in camp_positions:
		return camp_width
	
	# Check if we're near a camp location and need to transition smoothly
	var transition_distance = 20  # Number of points over which to transition
	
	for camp_pos in camp_positions:
		var distance = abs(point_index - camp_pos)
		if distance <= transition_distance and distance > 0:
			var transition_t = 1.0 - (float(distance) / float(transition_distance))
			transition_t = smoothstep(0.0, 1.0, transition_t)  # Smooth transition
			
			var base_width = lerp(valley_min_width, valley_max_width, 
				noise.get_noise_1d(point_index * 0.1) * 0.5 + 0.5)
			
			return lerp(base_width, camp_width, transition_t)
	
	# Normal valley width with some variation
	var width_noise = noise.get_noise_1d(point_index * 0.05) * 0.5 + 0.5
	return lerp(valley_min_width, valley_max_width, width_noise)

func calculate_terrain_height(world_pos: Vector3, distance_from_center: float, valley_width: float, point_index: int) -> float:
	var abs_distance = abs(distance_from_center)
	var valley_half_width = valley_width * 0.5
	
	# Base height starts at 0 in the center and rises towards edges
	var height = 0.0
	
	# Path area (center of valley) - bumpy but drivable terrain
	if abs_distance < valley_half_width * 0.35:
		# Multi-octave path roughness for realistic bumpy terrain
		var path_noise = 0.0
		var amplitude = path_roughness
		var frequency = noise_scale * 8.0
		
		for octave in range(3):
			path_noise += noise.get_noise_2d(world_pos.x * frequency, world_pos.z * frequency) * amplitude
			amplitude *= 0.6
			frequency *= 2.0
		
		height = path_noise
		
		# Make camp areas slightly flatter but still bumpy
		if point_index in camp_positions:
			height *= 0.5
	
	# Smooth transition zone from path to hill slopes
	elif abs_distance < valley_half_width * 0.6:
		var transition_t = (abs_distance - valley_half_width * 0.35) / (valley_half_width * 0.25)
		
		# Gentle rise for smooth connection
		var path_noise = 0.0
		var amplitude = path_roughness * (1.0 - transition_t * 0.7)
		var frequency = noise_scale * 8.0
		
		for octave in range(3):
			path_noise += noise.get_noise_2d(world_pos.x * frequency, world_pos.z * frequency) * amplitude
			amplitude *= 0.6
			frequency *= 2.0
		
		# Gradual height increase with smooth curve
		var base_height = smoothstep(0.0, 1.0, transition_t) * mountain_height * 0.1
		height = path_noise + base_height
	
	# Hill slopes - constant steepness regardless of valley width
	else:
		# Calculate distance beyond the transition zone
		var slope_distance = abs_distance - valley_half_width * 0.6
		
		# Convert wall steepness from degrees to rise/run ratio
		var slope_ratio = tan(deg_to_rad(wall_steepness))
		
		# Base height increases linearly with distance at constant angle
		var base_height = mountain_height * 0.1 + slope_distance * slope_ratio
		
		# Cap the maximum height
		base_height = min(base_height, mountain_height)
		
		# Add detailed bumpy wall texture with multiple noise layers
		var wall_noise = 0.0
		
		# Large scale wall variation
		var amplitude = mountain_height * 0.08
		var frequency = noise_scale * 1.5
		for octave in range(3):
			wall_noise += noise.get_noise_2d(
				world_pos.x * frequency, 
				world_pos.z * frequency
			) * amplitude
			amplitude *= 0.6
			frequency *= 2.0
		
		# Medium scale wall bumps
		amplitude = mountain_height * 0.04
		frequency = noise_scale * 8.0
		for octave in range(2):
			wall_noise += noise.get_noise_2d(
				world_pos.x * frequency, 
				world_pos.z * frequency
			) * amplitude
			amplitude *= 0.7
			frequency *= 2.2
		
		# Fine detail wall texture
		amplitude = mountain_height * 0.02
		frequency = noise_scale * 25.0
		wall_noise += noise.get_noise_2d(
			world_pos.x * frequency, 
			world_pos.z * frequency
		) * amplitude
		
		height = base_height + wall_noise
	
	return height



func store_camp_world_positions():
	camp_world_positions.clear()
	
	for camp_index in camp_positions:
		var t = float(camp_index) / float(mesh_resolution - 1)
		var world_pos = scaled_curve.sample_baked(t * scaled_curve.get_baked_length())
		camp_world_positions.append(world_pos)

# Function to get camp positions for placing enemy camps
func get_camp_positions() -> Array[Vector3]:
	return camp_world_positions

# Helper function to check if a world position is in a camp area
func is_in_camp_area(world_pos: Vector3) -> bool:
	for camp_pos in camp_world_positions:
		if world_pos.distance_to(camp_pos) < camp_width * 0.4:
			return true
	return false
