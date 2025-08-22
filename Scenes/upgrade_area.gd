extends Control

@export var tooltip_icon: Texture2D

var tooltip_instance: PanelContainer

var upgrade_id : int
@onready var upgrade: Upgrade = $"../../.."

func _ready() -> void:
	upgrade_id = upgrade.upgrade_id

func _on_mouse_entered():
	var tooltip_scene = preload("res://Scenes/tooltip.tscn")
	tooltip_instance = tooltip_scene.instantiate()
	get_tree().root.add_child(tooltip_instance) # Add to root so it overlays everything
	tooltip_instance.setup_from_id(upgrade_id)

func _on_mouse_exited():
	if tooltip_instance:
		tooltip_instance.queue_free()
		tooltip_instance = null
