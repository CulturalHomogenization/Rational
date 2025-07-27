extends Node3D

const TERRAIN_CHUNK := preload("res://Scenes/scatter_chunk.tscn")
const CHUNK_SIZE := 50
const TERRAIN_SIZE := 10
var proton_scatter : Node3D

func _ready():
	for j in range(TERRAIN_SIZE):
		for i in range(TERRAIN_SIZE):
			print("start")
			var chunk := TERRAIN_CHUNK.instantiate()
			print("instantiating")
			add_child(chunk)
			await child_entered_tree
			print("added_child")
			chunk.position = Vector3(i * CHUNK_SIZE, 0, j * CHUNK_SIZE)
			print("position set  ", chunk.position)
			await get_tree().create_timer(2).timeout
			print("Chunk placed:", i, j)
