extends PanelContainer

@export var offset := Vector2(12, 12)

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Title/TextureRect
@onready var title: Label = $MarginContainer/VBoxContainer/Title/Label
@onready var description: Label = $MarginContainer/VBoxContainer/Description/Label
@onready var research: Label = $MarginContainer/VBoxContainer/Research/Label
@onready var requirements: Label = $MarginContainer/VBoxContainer/Requirements/Label


func _ready() -> void:
	top_level = true

func format_description(upgrade: Dictionary) -> String:
	var text := ""
	text += upgrade["Description"] + "\n\n"
	text += "Cost:\n"
	for item in upgrade["Cost"]:
		text += "\t- %s: \t%s \n" % [item, str(upgrade["Cost"][item])]
	text += "\nSignature Item: \t%s" % upgrade["Signature Crafted Item"]
	text += "\n"
	return text

func setup_from_id(upgrade_id: int, icon_texture: Texture2D = null) -> void:
	if not UpgradeData.upgrades.has(upgrade_id):
		title.text = "Unknown Upgrade"
		description.text = "No data available."
		return
	var u = UpgradeData.upgrades[upgrade_id]
	title.text = u["Upgrade Name"]
	description.text = format_description(u)
	requirements.text = "Reasearch Level: \t%s" % str(u["Dependencies"])
	requirements.text += "\n"
	research.text = "Buff: \t%s (%s%%)" % [u["Buff Type"], str(u["Buff Amount"])]
	# Handle icon
	if icon_texture:
		icon.texture = icon_texture
		icon.visible = true
	else:
		icon.visible = false

func _process(_delta: float) -> void:
	_update_position()

func _update_position() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_global_mouse_position() + offset
	var size_px = size
	position = mouse_pos
