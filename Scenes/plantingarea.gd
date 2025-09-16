extends Interactable
class_name Plant

enum PlantState {
	EMPTY,
	GROWING,
	NEEDS_WATER,
	FULLY_GROWN,
	DEAD
}

# Plant configuration
@export var plant_data: Dictionary = {} # Will store plant types with their properties
@export var harvest_hold_time: float = 3.0
@export var water_timeout: float = 60.0
@export var growth_time: float = 5.0 # Total time to grow when not waiting for water

# Current plant state
var current_state: PlantState = PlantState.EMPTY
var planted_seed_id: String = ""
var current_plant_type: Dictionary = {}
var mesh_instance: MeshInstance3D
var water_count: int = 0
var required_waters: int = 3

# Timers
var growth_timer: float = 0.0
var water_timeout_timer: float = 0.0
var harvest_timer: float = 0.0
var is_harvesting: bool = false

# Water timing - random intervals where plant needs water
var water_intervals: Array[float] = []
var next_water_index: int = 0

func _ready():
	setup_plant_data()
	update_interactions()
	
func _process(delta):
	match current_state:
		PlantState.GROWING:
			process_growing(delta)
		PlantState.NEEDS_WATER:
			process_water_timeout(delta)
		PlantState.FULLY_GROWN:
			process_harvesting(delta)

func setup_plant_data():
	plant_data = {
		"carrot_seed": {
			"name": "carrot",
			"mesh_scene": "res://Scenes/CarrotPlant.tscn",
			"harvest_item": "Carrot",
			"harvest_item_scene": "res://Scenes/CarrotSack.tscn",
			"seed_scene": "res://Scenes/CarrotSeed.tscn",
			"harvest_count": 1,
			"seed_return": 1
		},
		"potato_seed": {
			"name": "potato",
			"mesh_scene": "res://Scenes/PotatoPlant.tscn",
			"harvest_item": "Potato",
			"harvest_item_scene": "res://Scenes/PotatoSack.tscn",
			"seed_scene": "res://Scenes/PotatoSeed.tscn",
			"harvest_count": 1,
			"seed_return": 1
		},
		"onion_seed": {
			"name": "onion",
			"mesh_scene": "res://Scenes/OnionPlant.tscn",
			"harvest_item": "Onion",
			"harvest_item_scene": "res://Scenes/OnionSack.tscn",
			"seed_scene": "res://Scenes/OnionSeed.tscn",
			"harvest_count": 1,
			"seed_return": 1
		},
		"wheat_seed": {
			"name": "wheat",
			"mesh_scene": "res://Scenes/WheatPlant.tscn",
			"harvest_item": "Wheat",
			"harvest_item_scene": "res://Scenes/WheatSack.tscn",
			"seed_scene": "res://Scenes/WheatSeed.tscn",
			"harvest_count": 1,
			"seed_return": 1
		},
		"lettuce_seed": {
			"name": "lettuce",
			"mesh_scene": "res://Scenes/LettucePlant.tscn",
			"harvest_item": "Lettuce",
			"harvest_item_scene": "res://Scenes/LettuceSack.tscn",
			"seed_scene": "res://Scenes/LettuceSeed.tscn",
			"harvest_count": 1,
			"seed_return": 1
		},
		"tomato_seed": {
			"name": "tomato",
			"mesh_scene": "res://Scenes/TomatoPlant.tscn",
			"harvest_item": "Tomato",
			"harvest_item_scene": "res://Scenes/TomatoSack.tscn",
			"seed_scene": "res://Scenes/TomatoSeed.tscn",
			"harvest_count": 1,
			"seed_return": 1
		}
	}

func update_interactions():
	interaction_actions.clear()
	
	match current_state:
		PlantState.EMPTY:
			interaction_actions["plant"] = {
				"message": "Plant Seed",
				"input_action": "interact"
			}
		PlantState.GROWING:
			# No interactions while growing normally
			pass
		PlantState.NEEDS_WATER:
			interaction_actions["water"] = {
				"message": "Water Plant",
				"input_action": "interact"
			}
		PlantState.FULLY_GROWN:
			interaction_actions["harvest"] = {
				"message": "Hold to Harvest",
				"input_action": "interact"
			}
		PlantState.DEAD:
			interaction_actions["clear"] = {
				"message": "Clear Dead Plant",
				"input_action": "interact"
			}

func interact(body, action_id: String):
	match action_id:
		"plant":
			attempt_plant(body)
		"water":
			water_plant()
		"harvest":
			start_harvest()
		"clear":
			clear_dead_plant()
	
	super.interact(body, action_id)

func attempt_plant(body):
	# Check if player has a seed item in their hand
	var held_item = body.held_item
	
	if held_item and held_item.has_method("get_script") and plant_data.has(held_item.id):
		plant_seed(held_item.id)
		# Remove the seed item from player's hand
		held_item.queue_free()
		body.held_item = null

func plant_seed(seed_id: String):
	planted_seed_id = seed_id
	current_plant_type = plant_data[seed_id]
	current_state = PlantState.GROWING
	
	# Create plant mesh
	if current_plant_type.has("mesh_scene"):
		var plant_scene = load(current_plant_type.mesh_scene)
		if plant_scene:
			mesh_instance = plant_scene.instantiate()
			add_child(mesh_instance)
			# Start small and scale up as it grows
			mesh_instance.scale = Vector3(0.1, 0.1, 0.1)
	
	# Set up random water intervals
	setup_water_intervals()
	
	# Reset counters
	growth_timer = 0.0
	water_count = 0
	next_water_index = 0
	
	update_interactions()
	print("Planted " + current_plant_type.name)

func setup_water_intervals():
	water_intervals.clear()
	# Create 3 random intervals during the growth period
	for i in range(required_waters):
		var random_time = randf() * growth_time
		water_intervals.append(random_time)
	
	water_intervals.sort()

func process_growing(delta):
	growth_timer += delta
	
	# Check if we need water
	if next_water_index < water_intervals.size() and growth_timer >= water_intervals[next_water_index]:
		current_state = PlantState.NEEDS_WATER
		water_timeout_timer = 0.0
		update_interactions()
		print(current_plant_type.name + " needs water!")
		return
	
	# Update plant scale based on growth
	if mesh_instance:
		var growth_progress = growth_timer / growth_time
		var scale_factor = lerp(0.1, 1.0, growth_progress)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Check if fully grown
	if growth_timer >= growth_time and water_count >= required_waters:
		current_state = PlantState.FULLY_GROWN
		update_interactions()
		print(current_plant_type.name + " is ready to harvest!")

func process_water_timeout(delta):
	water_timeout_timer += delta
	
	if water_timeout_timer >= water_timeout:
		# Plant dies
		current_state = PlantState.DEAD
		update_interactions()
		print(current_plant_type.name + " died from lack of water!")

func water_plant():
	if current_state == PlantState.NEEDS_WATER:
		water_count += 1
		next_water_index += 1
		current_state = PlantState.GROWING
		update_interactions()
		print("Watered " + current_plant_type.name + " (" + str(water_count) + "/" + str(required_waters) + ")")

func process_harvesting(delta):
	if is_harvesting:
		harvest_timer += delta
		
		# Progress feedback
		var progress = harvest_timer / harvest_hold_time
		print("Harvesting... " + str(int(progress * 100)) + "%")
		
		if harvest_timer >= harvest_hold_time:
			complete_harvest()
	else:
		harvest_timer = 0.0

func start_harvest():
	if current_state == PlantState.FULLY_GROWN:
		is_harvesting = true
		harvest_timer = 0.0
		print("Harvesting " + current_plant_type.name + "...")

func complete_harvest():
	# Spawn harvest items
	spawn_harvest_items()
	
	# Reset plant
	reset_plant()
	
	is_harvesting = false
	harvest_timer = 0.0


func spawn_harvest_items():
	var harvest_item = current_plant_type.get("harvest_item_scene", "")
	var harvest_count = current_plant_type.get("harvest_count", 1)
	var seed_return = current_plant_type.get("seed_return", 1)
	
	# Spawn harvest items
	for i in range(harvest_count):
		spawn_item_from_scene(harvest_item, global_position + Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)))
	
	# Spawn seeds
	for i in range(seed_return):
		spawn_item_from_scene(current_plant_type.get("seed_scene", ""), global_position + Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)))

func clear_dead_plant():
	if current_state == PlantState.DEAD:
		# Return fewer seeds for dead plant
		var seed_return = max(1, current_plant_type.get("seed_return", 1) - 1)
		for i in range(seed_return):
			spawn_item_from_scene(planted_seed_id, global_position + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)))
		
		reset_plant()
		print("Cleared dead plant")

func reset_plant():
	current_state = PlantState.EMPTY
	planted_seed_id = ""
	current_plant_type = {}
	water_count = 0
	next_water_index = 0
	growth_timer = 0.0
	water_timeout_timer = 0.0
	
	if mesh_instance:
		mesh_instance.queue_free()
		mesh_instance = null
	
	water_intervals.clear()
	update_interactions()

# Spawn items using specific scene files
func spawn_item_from_scene(scene_path: String, position: Vector3):
	if scene_path == "":
		print("Warning: No scene path provided for item")
		return
		
	var item_scene = load(scene_path)
	if item_scene == null:
		print("Warning: Could not load scene: " + scene_path)
		return
		
	var item_instance = item_scene.instantiate()
	
	item_instance.global_position = position
	
	# Add to the scene tree
	get_tree().current_scene.add_child(item_instance)

# Legacy function for compatibility (if needed elsewhere)
func spawn_item(item_id: String, position: Vector3):
	print("Warning: spawn_item() is deprecated. Use spawn_item_from_scene() instead.")
	# Fallback - you could implement a default behavior here if needed

# Override input check to handle harvest hold mechanics
func get_pressed_action() -> String:
	for action_id in interaction_actions:
		var input_action = interaction_actions[action_id].get("input_action", "")
		if input_action != "":
			if action_id == "harvest":
				if Input.is_action_pressed(input_action):
					return action_id
			else:
				# For other actions, use just_pressed
				if Input.is_action_just_pressed(input_action):
					return action_id
	return ""
