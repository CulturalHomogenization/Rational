extends Interactable

@export var accepted_item_ids: Array[String] = [
	"dough",
	"chopped_tomato",
	"chopped_meat",
	"spices",
	"berries"
]
@export var station_name: String = "Cooking Station"
@export var cooking_time: float = 1.0
@onready var info: Label3D = $Info
@onready var item_spawn: Marker3D = $ItemSpawn
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var recipes: Array[Dictionary] = [
	{
		"ingredients": ["dough"],
		"result": "HardTack Cracker"
	},
	{
		"ingredients": ["dough", "chopped_tomato", "spices", "chopped_meat"],
		"result": "Pizza"
	},
	{
		"ingredients": ["dough", "berries"],
		"result": "Protein Bar"
	}
]

@onready var cooking_timer: Timer = $CookingTimer

var inventory: Array[String] = []
var is_cooking: bool = false
var cooked_result: String = ""

enum CookingState { IDLE, COOKING, READY }
var current_state: CookingState = CookingState.IDLE

func _ready() -> void:
	update_interactions()
	interacted.connect(_on_cooking_station_interacted)
	
	if not cooking_timer:
		cooking_timer = Timer.new()
		add_child(cooking_timer)
	
	cooking_timer.wait_time = cooking_time
	cooking_timer.one_shot = true
	cooking_timer.timeout.connect(_on_cooking_finished)

func update_interactions():
	match current_state:
		CookingState.IDLE:
			interaction_actions = {
				"Start Cooking": {
					"message": "Start Cooking",
					"input_action": "interact"
				},
				"Store Item": {
					"message": "Store Item",
					"input_action": "interact_2"
				}
			}
		CookingState.COOKING:
			interaction_actions = {
				"Cooking": {
					"message": "Cooking...",
					"input_action": ""
				}
			}
		CookingState.READY:
			interaction_actions = {
				"Harvest": {
					"message": "Harvest",
					"input_action": "interact"
				}
			}

func _on_cooking_station_interacted(player, action_id: String):
	match action_id:
		"Start Cooking":
			attempt_start_cooking()
		"Store Item":
			attempt_store_item(player)
		"Harvest":
			attempt_harvest(player)

func attempt_store_item(player):
	if not player.held_item:
		info.show_message("No item to store")
		return
	
	var item_id = player.held_item.id
	
	if item_id not in accepted_item_ids:
		info.show_message("This item is not accepted")
		return
	
	if item_id in inventory:
		info.show_message("This ingredient is already stored")
		return
	
	inventory.append(item_id)
	player.held_item.queue_free()
	player.held_item = null
	
	info.show_message("Stored " + item_id + ". Ingredients: " + str(inventory))

func attempt_start_cooking():
	if current_state != CookingState.IDLE:
		return
	
	if inventory.is_empty():
		info.show_message("No ingredients to cook")
		return
	
	var recipe_result = find_matching_recipe()
	if recipe_result == "":
		info.show_message("No recipe matches these ingredients: " + str(inventory))
		return
	
	start_cooking(recipe_result)

func find_matching_recipe() -> String:
	for recipe in recipes:
		var recipe_ingredients = recipe["ingredients"]
		
		if recipe_ingredients.size() != inventory.size():
			continue
		
		var matches = true
		for ingredient in recipe_ingredients:
			if ingredient not in inventory:
				matches = false
				break
		
		if matches:
			return recipe["result"]
	info.show_message("No recipes match stored ingredients")
	return ""

func start_cooking(result: String):
	current_state = CookingState.COOKING
	cooked_result = result
	inventory.clear()
	animation_player.play("bake")
	
	update_interactions()
	cooking_timer.start()
	
	info.show_message("Started cooking " + result)

func _on_cooking_finished():
	current_state = CookingState.READY
	update_interactions()
	info.show_message("Cooking finished! " + cooked_result + " is ready")
	animation_player.play("RESET")

func attempt_harvest(player):
	if current_state != CookingState.READY:
		return
	
	spawn_cooked_food()
	
	current_state = CookingState.IDLE
	cooked_result = ""
	update_interactions()

func spawn_cooked_food():
	var item_instance = ItemManager.spawn_item(cooked_result, item_spawn.global_position)
	if item_instance:
		get_tree().current_scene.add_child(item_instance)
		print("Harvested " + cooked_result)
	else:
		print("Failed to spawn " + cooked_result)
