extends Button

# Signal for when the sprite is clicked
signal sprite_clicked

# Reference to the Area2D child node
@onready var area: Area2D = $Area2D

func _on_pressed():
	print("Sprite clicked!")
	sprite_clicked.emit()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2, 1.0)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
