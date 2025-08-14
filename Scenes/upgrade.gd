extends Sprite2D
class_name Upgrade

@export var upgrade_id : int

var title = UpgradeData.upgrades[upgrade_id]["title"]
var description = UpgradeData.upgrades[upgrade_id]["description"]
var dependencies = UpgradeData.upgrades[upgrade_id]["dependencies"]
var buffs = UpgradeData.upgrades[upgrade_id]["buffs"]
