extends Interactable

@export var accepted_item_ids: Array[String] = [
	"Chopped Carrot",
	"Chopped Onions", 
	"Chopped Potatoes",
	"Chopped Mushrooms",
	"Chopped Tomatoes",
	"Chopped Herbs",
	"Salt",
	"Pepper",
	"Oil",
	"Flour",
	"Milk",
	"Butter"
]
@export var station_name: String = "Cooking Station"
@export var cooking_time: float = 15.0

@export var recipes: Array[Dictionary] = [
	{
		"ingredients": ["Chopped Carrot"],
		"result": "Carrot Soup"
	},
	{
		"ingredients": ["Chopped Potatoes", "Chopped Mushrooms", "Pepper"],
		"result": "Mushroom Stew"
	},
	{
		"ingredients": ["Chopped Tomatoes", "Chopped Herbs", "Oil"],
		"result": "Tomato Sauce"
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
					"message": "Harvest (Bowl Required)",
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
		print("No item to store")
		return
	
	var item_id = player.held_item.id
	
	if item_id not in accepted_item_ids:
		print("This station doesn't accept " + item_id)
		return
	
	if item_id in inventory:
		print("This ingredient is already stored")
		return
	
	inventory.append(item_id)
	player.held_item.queue_free()
	player.held_item = null
	
	print("Stored " + item_id + ". Ingredients: " + str(inventory))

func attempt_start_cooking():
	if current_state != CookingState.IDLE:
		return
	
	if inventory.is_empty():
		print("No ingredients to cook")
		return
	
	var recipe_result = find_matching_recipe()
	if recipe_result == "":
		print("No recipe matches these ingredients: " + str(inventory))
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
	
	return ""

func start_cooking(result: String):
	current_state = CookingState.COOKING
	cooked_result = result
	inventory.clear()
	
	update_interactions()
	cooking_timer.start()
	
	print("Started cooking " + result)

func _on_cooking_finished():
	current_state = CookingState.READY
	update_interactions()
	print("Cooking finished! " + cooked_result + " is ready")

func attempt_harvest(player):
	if current_state != CookingState.READY:
		return
	
	if not player.held_item or player.held_item.id != "bowl":
		print("You need a bowl to harvest the food")
		return
	
	player.held_item.queue_free()
	player.held_item = null
	
	spawn_cooked_food()
	
	current_state = CookingState.IDLE
	cooked_result = ""
	update_interactions()

func spawn_cooked_food():
	var item_instance = ItemManager.spawn_item(cooked_result, global_position + Vector3(0, 1, 0))
	if item_instance:
		get_tree().current_scene.add_child(item_instance)
		print("Harvested " + cooked_result)
	else:
		print("Failed to spawn " + cooked_result)
