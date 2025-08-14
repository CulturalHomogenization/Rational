extends Node

var items: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	if items.has(item_id):
		items[item_id] += amount
	else:
		items[item_id] = amount
	print("Added %d of %s. Total: %d" % [amount, item_id, items[item_id]])

func remove_item(item_id: String, amount: int = 1) -> bool:
	if has_item(item_id, amount):
		items[item_id] -= amount
		if items[item_id] <= 0:
			items.erase(item_id)
		print("Removed %d of %s. Remaining: %d" % [amount, item_id, items.get(item_id, 0)])
		return true
	print("Cannot remove %d of %s – not enough in inventory." % [amount, item_id])
	return false

func has_item(item_id: String, amount: int = 1) -> bool:
	return items.has(item_id) and items[item_id] >= amount

func get_all_items() -> Dictionary:
	return items.duplicate()
