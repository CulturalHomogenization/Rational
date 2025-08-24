extends CollisionObject3D
class_name Interactable

signal interacted(body, action_id)

# Define interaction actions as a dictionary
# Key: action_id (string), Value: dictionary with message and input_action
var interaction_actions : Dictionary

func get_prompt() -> String:
	var prompt_lines = []
	
	for action_id in interaction_actions:
		var action_data = interaction_actions[action_id]
		var message = action_data.get("message", "Interact")
		var input_action = action_data.get("input_action", "interact")
		
		var key_name = ""
		for event in InputMap.action_get_events(input_action):
			if event is InputEventKey:
				key_name = event.as_text_physical_keycode()
				break
		
		if key_name != "":
			prompt_lines.append(message + " [" + key_name + "]")
	
	return "\n".join(prompt_lines)

func interact(body, action_id: String):
	if action_id in interaction_actions:
		interacted.emit(body, action_id)

# Helper function to check if any interaction input is pressed
func get_pressed_action() -> String:
	for action_id in interaction_actions:
		var input_action = interaction_actions[action_id].get("input_action", "")
		if input_action != "" and Input.is_action_just_pressed(input_action):
			return action_id
	return ""
