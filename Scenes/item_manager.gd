extends Node

const item_scenes: Dictionary = {
	"carrot_seeds": preload("res://Scenes/carrot_seed.tscn"),
	"carrot_plant": preload("res://Scenes/carrot_plant.tscn"),
	"carrot": preload("res://Scenes/carrot.tscn")
}

func spawn_item(item_id: String, position: Vector3) -> Node:
	if not item_scenes.has(item_id):
		print("No scene found for item: " + item_id)
		return null
	
	var item_scene = item_scenes[item_id]
	var item_instance = item_scene.instantiate()
	item_instance.global_position = position
	
	return item_instance

func get_item_scene(item_id: String) -> PackedScene:
	return item_scenes.get(item_id, null)

func has_item(item_id: String) -> bool:
	return item_scenes.has(item_id)
