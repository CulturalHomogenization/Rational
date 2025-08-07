extends MeshInstance3D

@onready var path_3d: NonCrossingBezierCurve = $Path3D

# Valley parameters
@export var valley_width: float = 100
@export var valley_depth: float = 100.0
@export var path_resolution: int = 3000
@export var cross_section_points: int = 30
@export var smoothness: float = 1
@export var path_scale_xz: float = 200.0

func _ready():
	generate_valley_mesh()
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("test"):
		generate_valley_mesh()


func generate_valley_mesh():
	if not path_3d:
		print("Path3D not found!")
		return
	
	var curve = path_3d.get_curve()
	if not curve:
		print("No curve found in Path3D!")
		return
	
	# Create arrays for mesh data
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generate valley cross-section profile (U-shape)
	var profile_points = generate_valley_profile()
	
	# Generate vertices along the path
	for i in range(path_resolution + 1):
		var t = float(i) / float(path_resolution)
		var path_point = curve.sample_baked(t * curve.get_baked_length())
		
		# Scale the path point (x and z by scale factor, keep y unchanged)
		path_point.x *= path_scale_xz
		path_point.z *= path_scale_xz
		
		# Get path direction for orientation
		var forward = Vector3.FORWARD
		if i < path_resolution:
			var t_next = float(i + 1) / float(path_resolution)
			var next_point = curve.sample_baked(t_next * curve.get_baked_length())
			# Scale the next point too
			next_point.x *= path_scale_xz
			next_point.z *= path_scale_xz
			forward = (next_point - path_point).normalized()
		elif i > 0:
			var t_prev = float(i - 1) / float(path_resolution)
			var prev_point = curve.sample_baked(t_prev * curve.get_baked_length())
			# Scale the previous point too
			prev_point.x *= path_scale_xz
			prev_point.z *= path_scale_xz
			forward = (path_point - prev_point).normalized()
		
		# Calculate right and up vectors
		var up = Vector3.UP
		var right = forward.cross(up).normalized()
		up = right.cross(forward).normalized()
		
		# Create cross-section vertices at this path point
		for j in range(cross_section_points):
			var profile_point = profile_points[j]
			var world_pos = path_point + right * profile_point.x + up * profile_point.y
			
			vertices.append(world_pos)
			
			# Calculate normal based on valley slope
			var slope_factor = abs(profile_point.x) / (valley_width * 0.5)
			var normal = (up + right * slope_factor * 0.3).normalized()
			normals.append(normal)
			
			# UV coordinates
			var u = float(j) / float(cross_section_points - 1)
			var v = float(i) / float(path_resolution)
			uvs.append(Vector2(u, v))
	
	# Generate triangular faces
	for i in range(path_resolution):
		for j in range(cross_section_points - 1):
			var current_row = i * cross_section_points
			var next_row = (i + 1) * cross_section_points
			
			# First triangle
			indices.append(current_row + j)
			indices.append(next_row + j)
			indices.append(current_row + j + 1)
			
			# Second triangle
			indices.append(current_row + j + 1)
			indices.append(next_row + j)
			indices.append(next_row + j + 1)
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	mesh = array_mesh
	
	print("Valley mesh generated with ", vertices.size(), " vertices and ", indices.size() / 3, " triangles")

func generate_valley_profile() -> PackedVector2Array:
	var profile = PackedVector2Array()
	
	# Create U-shaped valley profile
	for i in range(cross_section_points):
		var t = float(i) / float(cross_section_points - 1)
		var x = (t - 0.5) * valley_width
		
		# U-shaped curve using a parabola
		var normalized_x = (t - 0.5) * 2.0  # -1 to 1
		var y = -valley_depth * (1.0 - normalized_x * normalized_x * smoothness)
		
		profile.append(Vector2(x, y))
	
	return profile

# Function to regenerate mesh (useful for runtime changes)
func update_valley_mesh():
	generate_valley_mesh()

# Function to set valley parameters and update
func set_valley_parameters(width: float, depth: float, resolution: int = 100):
	valley_width = width
	valley_depth = depth
	path_resolution = resolution
	update_valley_mesh()
