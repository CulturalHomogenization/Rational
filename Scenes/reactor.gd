extends Interactable

@export var station_name: String = "Coal Station"
@onready var info: Label3D = $Info

var accepted_coal_count: int = 0
var max_coal_capacity: int = 10  # Optional: limit how much coal it can accept

func _ready() -> void:
	update_interactions()
	interacted.connect(_on_coal_station_interacted)

func update_interactions():
	if accepted_coal_count >= max_coal_capacity:
		interaction_actions = {
			"Full": {
				"message": "Coal Station Full (" + str(accepted_coal_count) + "/" + str(max_coal_capacity) + ")",
				"input_action": ""
			}
		}
	else:
		interaction_actions = {
			"Give Coal": {
				"message": "Give Coal (" + str(accepted_coal_count) + "/" + str(max_coal_capacity) + ")",
				"input_action": "interact"
			}
		}

func _on_coal_station_interacted(player, action_id: String):
	match action_id:
		"Give Coal":
			try_accept_coal(player)

func try_accept_coal(player):
	# Check if player has coal in their inventory or hand
	var has_coal = check_player_has_coal(player)
	
	if has_coal and accepted_coal_count < max_coal_capacity:
		# Remove coal from player and accept it
		remove_coal_from_player(player)
		accepted_coal_count += 1
		update_interactions()
		info.show_message("Coal accepted! Total: " + str(accepted_coal_count))
	elif not has_coal:
		info.show_message("You need coal to use this station!")
	else:
		info.show_message("Coal station is full!")

func check_player_has_coal(player) -> bool:
	return player.held_item != null and player.held_item.item_id == "Coal"

func remove_coal_from_player(player):
	if player.held_item and player.held_item.item_id == "Coal":
		player.held_item.queue_free()
		player.held_item = null

# Optional: Method to get current coal count (useful for other systems)
func get_coal_count() -> int:
	return accepted_coal_count

# Optional: Method to consume coal (if other systems need to use the stored coal)
func consume_coal(amount: int = 1) -> int:
	var consumed = min(amount, accepted_coal_count)
	accepted_coal_count -= consumed
	update_interactions()
	if consumed > 0:
		info.show_message("Consumed " + str(consumed) + " coal. Remaining: " + str(accepted_coal_count))
	return consumed
