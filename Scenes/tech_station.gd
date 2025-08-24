extends Interactable

@export var accepted_item_ids: Array[String] = ["Coal"]
@export var station_name: String = "Storage"
var stored_items : Array[String] = []
func _ready() -> void:
	interaction_actions = {
		"Open Menu" : {
			"message" : "Upgrade",
			"input_action": "interact"
		},
		"Store Item" : {
			"message" : "Store Item",
			"input_action" : "interact_2",
		}
	}
	
	interacted.connect(_on_tech_station_interacted)

func accepts_item(item_id: String) -> bool:
	return item_id in accepted_item_ids

func _on_tech_station_interacted(player, action_id: String):
	match action_id:
		"Open Menu":
			player.UpgradeMenu.visible = true
		"Store Item":
			if player.held_item and accepts_item(player.held_item.id):
				player.held_item.collision_shape_3d.disabled = true
				player.held_item.visible = false
				player.held_item.is_picked_up = false
				stored_items.append(player.held_item.id)
				player.held_item = null
			else:
				print("This station doesn't accept that item")
