extends Sprite2D
class_name Upgrade

@export var upgrade_id : int
@onready var upgrade_area: Area2D = $UpgradeArea

@export var title : String
@export var description : String
@export var dependencies : Array
@export var buffs : Array

func _ready() -> void:
	title = UpgradeData.upgrades[upgrade_id]["title"]
	description = UpgradeData.upgrades[upgrade_id]["description"]
	dependencies = UpgradeData.upgrades[upgrade_id]["dependencies"]
	buffs = UpgradeData.upgrades[upgrade_id]["buffs"]
	upgrade_area.tooltip_text = title
	print(description)
	print(dependencies)
	print(buffs)
