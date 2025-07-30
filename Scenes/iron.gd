extends Interactable
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _on_interacted(body: Variant) -> void:
	var key_name = ""
	for action in InputMap.action_get_events(prompt_input):
		if action is InputEventKey:
			key_name = action.as_text_physical_keycode()
			break
	collision_shape_3d.disabled = true
	body.interact.text = "Drop" + "\n[" + key_name + "]"
