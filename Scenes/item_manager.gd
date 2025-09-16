extends Node

const item_scenes: Dictionary = {
	"carrot_seeds": preload("res://Scenes/CarrotSeed.tscn"),
	"carrot_plant": preload("res://Scenes/CarrotPlant.tscn"),
	"carrot_sack": preload("res://Scenes/CarrotSack.tscn"),
	"potato_sack": preload("res://Scenes/PotatoSack.tscn"),
	"potato_seeds": preload("res://Scenes/PotatoSeed.tscn"),
	"potato_plant": preload("res://Scenes/PotatoPlant.tscn"),
	"onion_sack": preload("res://Scenes/OnionSack.tscn"),
	"onion_seeds": preload("res://Scenes/OnionSeed.tscn"),
	"onion_plant": preload("res://Scenes/OnionPlant.tscn"),
	"wheat_sack": preload("res://Scenes/WheatSack.tscn"),
	"wheat_seeds": preload("res://Scenes/WheatSeed.tscn"),
	"wheat_plant": preload("res://Scenes/WheatPlant.tscn"),
	"lettuce_sack": preload("res://Scenes/LettuceSack.tscn"),
	"lettuce_seeds": preload("res://Scenes/LettuceSeed.tscn"),
	"lettuce_plant": preload("res://Scenes/LettucePlant.tscn"),
	"tomato_sack": preload("res://Scenes/TomatoSack.tscn"),
	"tomato_seeds": preload("res://Scenes/TomatoSeed.tscn"),
	"tomato_plant": preload("res://Scenes/TomatoPlant.tscn"),
	"Pizza": preload("res://Scenes/pizza.tscn"),
	"HardTack Cracker": preload("res://Scenes/crackers.tscn"),
	"Protein Bar": preload("res://Scenes/bar.tscn"),
	"Cooked meat" : preload("res://Scenes/cooked_meat.tscn"),
	"Cooked fish": preload("res://Scenes/cooked_fish.tscn"),
	"Vegetable Jerky Mix" : preload("res://Scenes/veg_jerky.tscn"),
	"Dried Noodle Block" : preload("res://Scenes/noodleblock.tscn"),
	"Steamed Veg Pouch": preload("res://Scenes/steamed_veg_pouch.tscn"),
	"Stew Pack": preload("res://Scenes/stew_pack.tscn"),
	"Fish Stew Can": preload("res://Scenes/fish_stew_can.tscn"),
	"Luxury Survival Stew": preload("res://Scenes/lux_stew.tscn"),
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
