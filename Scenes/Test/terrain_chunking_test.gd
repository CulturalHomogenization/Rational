extends Node3D

const TERRAIN_CHUNK := preload("res://Scenes/scatter_chunk.tscn")
const CHUNK_SIZE := 50
const TERRAIN_SIZE := 10
var proton_scatter : Node3D

func _ready():
	for j in range(TERRAIN_SIZE):
		for i in range(TERRAIN_SIZE):
			var chunk := TERRAIN_CHUNK.instantiate()
			add_child(chunk)
			chunk.position = Vector3(i * CHUNK_SIZE, 0, j * CHUNK_SIZE)
			if chunk.has_signal("build_completed"):
				await chunk.build_completed
			print("Chunk placed:", i, j)
