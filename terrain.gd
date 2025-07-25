@tool
extends MeshInstance3D

<<<<<<< Updated upstream
const size := 256.0

@export_range(4, 256, 4) var resolution := 32:
=======
const size := 5000.0
@onready var proton_scatter: Node3D = $ProtonScatter
@export_range(4, 2506, 4) var resolution := 320:
>>>>>>> Stashed changes
	set(new_resolution):
		resolution = new_resolution
		update_mesh()

@export var noise : FastNoiseLite:
	set(new_noise):
		noise = new_noise
		update_mesh()
		if noise:
			noise.changed.connect(update_mesh)

<<<<<<< Updated upstream
@export_range(4.0, 128.0, 4.0) var height := 64.0:
=======
@export_range(4.0, 2048.0, 4.0) var height := 2048.0:
>>>>>>> Stashed changes
	set(new_height):
		height = new_height
		update_mesh()

func get_height(x: float, y: float) -> float:
	return noise.get_noise_2d(x, y) * height

func get_normal(x: float, y: float) -> Vector3:
	var epilson := size / resolution
	var normal := Vector3(
		(get_height(x + epilson, y) - get_height(x - epilson, y)) / (2.0 * epilson),
		1,
		(get_height(x, y + epilson) - get_height(x, y - epilson)) / (2.0 * epilson)
	)
	return normal.normalized()

func update_mesh() -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size, size)
	
	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array : PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array : PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array : PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	for i:int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = get_height(vertex.x, vertex.z)
			normal = get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mesh
