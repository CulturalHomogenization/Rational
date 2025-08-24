extends Control

@export var tooltip_icon: Texture2D

var tooltip_instance: PanelContainer

var upgrade_id : int
@onready var upgrade: Upgrade = $"../../.."

func _ready() -> void:
	upgrade_id = upgrade.upgrade_id

func _on_mouse_entered():
	if tooltip_instance == null:
		var tooltip_scene = preload("res://Scenes/tooltip.tscn")
		tooltip_instance = tooltip_scene.instantiate()
		get_tree().root.add_child(tooltip_instance)
		tooltip_instance.setup_from_id(upgrade_id, tooltip_icon)


func _process(delta: float) -> void:
	if tooltip_instance != null:
		if get_rect().has_point(get_local_mouse_position()) == false:
			tooltip_instance.queue_free()
