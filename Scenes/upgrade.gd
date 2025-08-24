extends Control
class_name Upgrade
@export var upgrade_id : int
@export var title : String
@export var description : String
@export var dependencies : Array
@export var buffs : Array
@export var costs : Array
@export var is_purchased : bool = false
@onready var upgrade_area: Container = $Panel/VBoxContainer/MainIcon

func _ready() -> void:
	# Set initial line colors to dim
	for child in get_children():
		if child is Line2D:
			child.default_color = Color(80, 80, 0)


func can_purchase_upgrade() -> bool:
	# Check if already purchased
	if is_purchased:
		return false
	
	# Check dependencies are met
	for dep_id in dependencies:
		if dep_id in PlayerStats.upgrades:
			pass
		else:
			return false
	# Check if player has enough resources
	#for cost in costs:
		#var item_name = cost["item"]
		#var required_amount = cost["amount"]
		#if not Inventory.has_item(item_name, required_amount):
			#return false
	
	return true

func purchase_upgrade() -> void:
	if not can_purchase_upgrade():
		return
	
	# Deduct costs from inventory
	#for cost in costs:
		#var item_name = cost["item"]
		#var required_amount = cost["amount"]
		#Inventory.remove_item(item_name, required_amount)
	
	# Mark as purchased
	is_purchased = true
	PlayerStats.upgrades.append(upgrade_id)
	# Apply buffs - TODO: implement later
	# apply_upgrade_buffs()
	
	# Update visual state
	modulate = Color(0.8, 1.0, 0.8)  # Slightly green tint for purchased upgrades

func apply_upgrade_buffs() -> void:
	# TODO: Implement buff system later
	print("Buffs applied for upgrade: " + title)
	for buff in buffs:
		print("  - " + buff["type"] + ": " + str(buff["amount"]))


func _on_upgrade_icon_pressed() -> void:
# Check if upgrade can be purchased
	if not can_purchase_upgrade():
		print("Cannot purchase upgrade: " + title)
		return
	
	# Purchase the upgrade
	purchase_upgrade()
	
	# Update visual feedback - brighten the lines
	for child in get_children():
		if child is Line2D:
			child.default_color = Color(255, 255, 255)
			print("Upgrade purchased: " + title)
