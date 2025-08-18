extends Sprite2D

# Signal for when the sprite is clicked
signal sprite_clicked

# Reference to the Area2D child node
@onready var area: Area2D = $Area2D

func _handle_click():
	print("Sprite clicked!")
	sprite_clicked.emit()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.30), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 0.25), 0.1)


func _on_upgrade_button_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2, 1.0)


func _on_upgrade_button_mouse_exited() -> void:
	modulate = Color.WHITE

func _on_upgrade_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click()
