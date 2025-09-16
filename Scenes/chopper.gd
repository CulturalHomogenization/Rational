extends Interactable

@export var accepted_item_ids: Array[String] = [
	"carrot",
	"onion", 
	"potato",
	"lettuce",
	"dough",
	"meat",
	"fish",
	"tomato"
]

@export var station_name: String = "Chopping Station"
@export var chopping_time: float = 3.0

# Simple item processing dictionary: input_item -> processed_scene
@export var item_processing: Dictionary = {
	"carrot": preload("res://Scenes/ChoppedCarrot.tscn"),
	"onion": preload("res://Scenes/ChoppedOnion.tscn"),
	"potato": preload("res://Scenes/ChoppedPotato.tscn"),
	"lettuce": preload("res://Scenes/ChoppedLettuce.tscn"),
	"dough": preload("res://Scenes/noodles.tscn"),
	"meat": preload("res://Scenes/ChoppedMeat.tscn"),
	"fish": preload("res://Scenes/ChoppedFish.tscn"),
	"tomato": preload("res://Scenes/ChoppedTomato.tscn")
}

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var item_position: Marker3D = $Item
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var info: Label3D = $Info

var processing_queue: Array[String] = []
var is_processing: bool = false
var processing_timer: Timer

func _ready() -> void:
	if info:
		info.setup(self)
	
	interaction_actions = {
		"Process Item": {
			"message": "Chop Ingredient",
			"input_action": "interact"
		}
	}
	
	# Setup processing timer
	processing_timer = Timer.new()
	processing_timer.wait_time = chopping_time
	processing_timer.one_shot = true
	processing_timer.timeout.connect(_on_processing_complete)
	add_child(processing_timer)
	
	interacted.connect(_on_chopping_station_interacted)

func accepts_item(item_id: String) -> bool:
	return item_id in accepted_item_ids

func can_process_item(item_id: String) -> bool:
	return item_id in item_processing

func process_item(item_id: String) -> void:
	if can_process_item(item_id) and not is_processing:
		processing_queue.append(item_id)
		if processing_queue.size() == 1:  # Start processing if this is the first item
			start_processing()

func start_processing() -> void:
	if processing_queue.size() > 0 and not is_processing:
		is_processing = true
		
		# Update interaction to show processing status
		interaction_actions = {
			"Processing": {
				"message": "Chopping " + processing_queue[0] + "...",
				"input_action": ""
			}
		}
		
		# Start animations if available
		if animation_player and animation_player.has_animation("chop"):
			animation_player.play("chop")
		
		if info:
			info.show_message("Started chopping " + processing_queue[0])
		
		print("Chopping started for: ", processing_queue[0])
		processing_timer.start()

func _on_processing_complete() -> void:
	if processing_queue.size() > 0:
		var processed_item_id = processing_queue.pop_front()
		var processed_scene = item_processing[processed_item_id]
		
		# Spawn the chopped item
		spawn_processed_item(processed_scene)
		
		print("Chopping complete for: ", processed_item_id)
		
		# Stop animations
		if animation_player:
			animation_player.stop()
		
		if info:
			info.show_message("Chopping finished!")
		
		# Continue processing next item if any
		is_processing = false
		if processing_queue.size() > 0:
			start_processing()
		else:
			# Reset to default interaction
			interaction_actions = {
				"Process Item": {
					"message": "Chop Ingredient",
					"input_action": "interact"
				}
			}

func spawn_processed_item(processed_scene: PackedScene) -> void:
	var processed_item = processed_scene.instantiate()
	
	# Position the item at spawn point or near the station
	var spawn_position = spawn_point.global_position if spawn_point else global_position + Vector3(2, 1, 0)
	processed_item.global_position = spawn_position
	
	# Add to the scene
	get_tree().current_scene.add_child(processed_item)
	
	print("Spawned chopped item at: ", spawn_position)

func get_processing_status() -> String:
	if is_processing:
		var time_left = processing_timer.time_left
		return "Chopping... " + str(int(time_left)) + "s remaining"
	elif processing_queue.size() > 0:
		return "Queue: " + str(processing_queue.size()) + " items"
	else:
		return "Ready to chop ingredients"

func _on_chopping_station_interacted(player, action_id: String):
	match action_id:
		"Process Item":
			if player.held_item and can_process_item(player.held_item.id):
				var item_to_process = player.held_item.id
				
				# Remove the item from player
				player.held_item.queue_free()
				player.held_item = null
				
				# Add to processing queue
				process_item(item_to_process)
				print("Added to chopping queue: ", item_to_process)
			else:
				if player.held_item:
					print("Cannot chop this item: ", player.held_item.id)
					if info:
						info.show_message("This ingredient cannot be chopped.")
				else:
					print("No item to chop")
					if info:
						info.show_message("This station only accepts ingredients")

# Override the prompt to show processing status
func get_prompt() -> String:
	var base_prompt = super.get_prompt()
	var status = get_processing_status()
	
	if status != "Ready to chop ingredients":
		return base_prompt + "\n" + status
	else:
		return base_prompt
