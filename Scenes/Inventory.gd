extends Node

var resources: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	if resources.has(item_id):
		resources[item_id] += amount
	else:
		resources[item_id] = amount
	print("Added %d of %s. Total: %d" % [amount, item_id, resources[item_id]])

func remove_item(item_id: String, amount: int = 1) -> bool:
	if has_item(item_id, amount):
		if resources[item_id] <= 0:
			resources.erase(item_id)
		print("Removed %d of %s. Remaining: %d" % [amount, item_id, resources.get(item_id, 0)])
		return true
	print("Cannot remove %d of %s – not enough in inventory." % [amount, item_id])
	return false

func has_item(item_id: String, amount: int = 1) -> bool:
	return resources.has(item_id) and resources[item_id] >= amount

func get_all_items() -> Dictionary:
	return resources.duplicate()
