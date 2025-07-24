extends Node3D

var terrain_chunk := preload("res://Scenes/scatter_chunk.tscn")
var chunk_size := 50
const terrain_size := 10

func _ready():
	for i in range(terrain_size):
		for i in range(terrain_size):
			var proton_scatter = terrain_chunk.instantiate()
			proton_scatter.position.x = i * chunk_size
			add_child(proton_scatter)
			await proton_scatter.build_completed
