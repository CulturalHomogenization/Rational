extends Interactable

@export var accepted_item_id : String
@export var give_item_type : PackedScene

@export var num_items : int = 1
@export var station_name: String

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var info: Label3D = $Info


func _ready() -> void:
	interaction_actions = {
		"Store Item": {
			"message": "Store" + accepted_item_id ,
			"input_action": "interact"
		},
		"Take Item": {
			"message": "Take" + give_item_type.item_id,
			"input_action": "interact_2"
		},
	}
	
	interacted.connect(_on_chopping_station_interacted)

func _on_chopping_station_interacted(player, action_id: String):
	match action_id:
		"Store Item":
			if player.held_item.item_id == accepted_item_id:
				player.held_item.queue_free()
				player.held_item = null
				num_items += 1
			else:
				if not player.held_item:
					if info:
						info.show_message("This material cannot be refined.")
				else:
					if info:
						info.show_message("No material")
