extends PickupItem
class_name Ingredient

# The processed version of this ingredient that should spawn after chopping
@export var processed_item_scene: PackedScene

# Optional: override the processed item's spawn position offset
@export var spawn_offset: Vector3 = Vector3.ZERO

# Check if this ingredient can be processed
func can_be_processed() -> bool:
	return processed_item_scene != null

# Get the processed item scene
func get_processed_scene() -> PackedScene:
	return processed_item_scene

# Create and return an instance of the processed item
func create_processed_item() -> Node:
	if not can_be_processed():
		print("Warning: No processed item scene set for " + item_name)
		return null
	
	var processed_item = processed_item_scene.instantiate()
	return processed_item
