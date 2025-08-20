extends PanelContainer

@export var offset := Vector2(12, 12)
var tool_text := ""

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Title/TextureRect
@onready var label: Label = $MarginContainer/VBoxContainer/Title/Label

func _ready() -> void:
	top_level = true

func setup(text: String, icon_texture: Texture2D = null) -> void:
	tool_text = text
	label.text = text
	if icon_texture:
		icon.texture = icon_texture
		icon.visible = true
	else:
		icon.visible = false

func _process(_delta: float) -> void:
	label.text = tool_text
	_update_position()

func _update_position() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_global_mouse_position() + offset
	var size_px = size
	position = mouse_pos
