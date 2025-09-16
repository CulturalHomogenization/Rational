extends Interactable

@export var station_name: String = "Crafting Station"
@export var crafting_time: float = 10.0
@onready var info: Label3D = $Info

@export var craftable_items: Array[Dictionary] = [
	{
		"name": "Wooden Spoon",
		"ingredients": {"Wood": 1, "Tool Parts": 1}
	},
	{
		"name": "Iron Knife",
		"ingredients": {"Iron Ingot": 1, "Wood": 1, "Tool Parts": 1}
	},
	{
		"name": "Cooking Pot",
		"ingredients": {"Iron Ingot": 2, "Handle": 1}
	}
]

@onready var crafting_timer: Timer = $CraftingTimer
@onready var crafting_menu: Control = $CraftingMenu
@onready var item_list: ItemList = $CraftingMenu/VBoxContainer/ItemList
@onready var craft_button: Button = $CraftingMenu/VBoxContainer/CraftButton
@onready var close_button: Button = $CraftingMenu/VBoxContainer/CloseButton

var is_crafting: bool = false
var selected_recipe: Dictionary = {}
var inventory: Array[String] = []

func _ready() -> void:
	update_interactions()
	interacted.connect(_on_crafting_station_interacted)
	
	if not crafting_timer:
		crafting_timer = Timer.new()
		add_child(crafting_timer)
	
	crafting_timer.wait_time = crafting_time
	crafting_timer.one_shot = true
	crafting_timer.timeout.connect(_on_crafting_finished)
	
	setup_menu()

func update_interactions():
	if is_crafting:
		interaction_actions = {
			"Crafting": {
				"message": "Crafting...",
				"input_action": ""
			}
		}
	else:
		interaction_actions = {
			"Open Menu": {
				"message": "Open Crafting Menu",
				"input_action": "interact"
			}
		}

func setup_menu():
	if not crafting_menu:
		return
	
	crafting_menu.visible = false
	
	if craft_button:
		craft_button.pressed.connect(_on_craft_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if item_list:
		item_list.item_selected.connect(_on_item_selected)
	
	populate_item_list()

func populate_item_list():
	if not item_list:
		print("No list")
		return
	
	item_list.clear()
	
	for i in range(craftable_items.size()):
		var recipe = craftable_items[i]
		var item_name = recipe["name"]
		var ingredients = recipe["ingredients"]
		
		item_list.add_item(item_name)
		
		var tooltip_text = "Ingredients:\n"
		for ingredient in ingredients:
			var count = ingredients[ingredient]
			tooltip_text += ingredient + " x" + str(count) + "\n"
		
		item_list.set_item_tooltip(i, tooltip_text)

func _on_crafting_station_interacted(player, action_id: String):
	match action_id:
		"Open Menu":
			open_crafting_menu(player)

func open_crafting_menu(player):
	crafting_menu.visible = true

func _on_item_selected(index: int):
	if index >= 0 and index < craftable_items.size():
		selected_recipe = craftable_items[index]
		
		if craft_button:
			craft_button.text = "Craft " + selected_recipe["name"]
			craft_button.disabled = false

func _on_craft_button_pressed():
	if selected_recipe.is_empty():
		return
	
	if can_craft_item(selected_recipe):
		start_crafting()
	else:
		info.show_message("Missing ingredients for " + selected_recipe["name"])

func _on_close_button_pressed():
	crafting_menu.visible = false
	selected_recipe = {}

func can_craft_item(recipe: Dictionary) -> bool:
	return true

func start_crafting():
	is_crafting = true
	crafting_menu.visible = false
	
	update_interactions()
	crafting_timer.start()
	
	info.show_message("Started crafting " + selected_recipe["name"])

func _on_crafting_finished():
	var result_item = selected_recipe["name"]
	spawn_crafted_item(result_item)
	
	is_crafting = false
	selected_recipe = {}
	
	update_interactions()
	info.show_message("Crafting finished!")

func spawn_crafted_item(item_id: String):
	var item_instance = ItemManager.spawn_item(item_id, global_position + Vector3(0, 1, 0))
	if item_instance:
		get_tree().current_scene.add_child(item_instance)
		info.show_message("Crafted " + item_id)
	else:
		print("Failed to spawn " + item_id)
