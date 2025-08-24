extends Interactable
class_name PickupItem

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@export var id: String
@export var item_name: String = "Item"

var is_picked_up: bool = false

func _ready():
	# Set up the pickup interaction
	interaction_actions = {
		"pickup": {
			"message": "Pick up " + item_name,
			"input_action": "interact"
		}
	}
