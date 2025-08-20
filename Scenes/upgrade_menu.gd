extends Node2D

# In your gameplay scene:
# In your UI scene:
func _on_close_pressed():
	SceneManager.restore_scene()
