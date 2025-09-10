extends Interactable

@export var accepted_item_ids: Array[String] = [
	"Carrot",
	"Onion", 
	"Potato",
	"Tomato",
	"Lettuce"
]
@export var station_name: String = "Chopping Station"
@export var chopping_time: float = 3.0

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var item_position: Marker3D = $Item
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var chopping_timer: Timer = $ChoppingTimer
@onready var info: Label3D = $Info

var is_chopping: bool = false
var current_ingredient: Ingredient = null

func _ready() -> void:
	interaction_actions = {
		"Insert Item": {
			"message": "Chop Ingredient",
			"input_action": "interact"
		}
	}
	interacted.connect(_on_chopping_station_interacted)
	
	if not chopping_timer:
		chopping_timer = Timer.new()
		add_child(chopping_timer)
	
	chopping_timer.wait_time = chopping_time
	chopping_timer.one_shot = true
	chopping_timer.timeout.connect(_on_chopping_finished)

func accepts_item(item) -> bool:
	return (item is Ingredient 
		and item.can_be_processed() 
		and item.id in accepted_item_ids 
		and not is_chopping)

func _on_chopping_station_interacted(player, action_id: String):
	match action_id:
		"Insert Item":
			if player.held_item and accepts_item(player.held_item):
				start_chopping(player, player.held_item)
			elif is_chopping:
				info.show_message("Station is currently chopping an item")
			elif player.held_item and player.held_item is Ingredient and not (player.held_item.id in accepted_item_ids):
				info.show_message("This ingredient needs to be milled, not chopped")
			elif player.held_item and player.held_item is Ingredient and not player.held_item.can_be_processed():
				info.show_message("This ingredient can't be processed")
			else:
				info.show_message("This station only accepts choppable ingredients")

func start_chopping(player, ingredient: Ingredient):
	current_ingredient = ingredient
	player.held_item = null
	
	ingredient.get_parent().remove_child(ingredient)
	add_child(ingredient)
	ingredient.global_position = item_position.global_position
	ingredient.freeze = true
	ingredient.collision_shape_3d.disabled = true
	ingredient.is_picked_up = false
	ingredient.interaction_actions.clear()
	
	is_chopping = true
	
	interaction_actions = {
		"Processing": {
			"message": "Chopping " + ingredient.item_name + "...",
			"input_action": ""
		}
	}
	
	if animation_player and animation_player.has_animation("chop"):
		animation_player.play("chop")
	
	chopping_timer.start()
	print("Started chopping " + ingredient.item_name)

func _on_chopping_finished():
	if current_ingredient and current_ingredient.can_be_processed():
		spawn_processed_item()
	
	if current_ingredient:
		current_ingredient.queue_free()
		current_ingredient = null
	
	is_chopping = false
	
	interaction_actions = {
		"Insert Item": {
			"message": "Insert Ingredient to Chop",
			"input_action": "interact"
		}
	}
	
	if animation_player:
		animation_player.stop()
	
	print("Chopping finished!")

func spawn_processed_item():
	var processed_item = current_ingredient.create_processed_item()
	
	if processed_item:
		processed_item.global_position = spawn_point.global_position + current_ingredient.spawn_offset
		get_tree().current_scene.add_child(processed_item)
		print("Spawned processed " + current_ingredient.item_name + " at spawn point")
	else:
		print("Failed to create processed item from " + current_ingredient.item_name)

func get_status() -> String:
	if is_chopping and current_ingredient:
		var time_left = chopping_timer.time_left
		return "Chopping " + current_ingredient.item_name + " (" + str(int(time_left)) + "s remaining)"
	else:
		return "Ready to chop ingredients"
