extends Node3D
@export var terrain : MeshInstance3D

func _ready():
	if not terrain:
		terrain = $Terrain

	terrain.create_trimesh_collision()
	
	
