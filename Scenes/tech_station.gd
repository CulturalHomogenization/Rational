extends Interactable

@export var accepted_item_ids: Array[String] = [
	"Brass-Infused Soil Crucibles",
	"Riveted Growth Lattices",
	"Mineral-Tuned Water Condensers",
	"Steam Seed Incubators",
	"Coal-Fired Radiant Braziers",
	"Gear-Clamped Harvest Shears",
	"Pressure-Dial Water Regulators",
	"Steam-Powered Soil Augers",
	"Copper-Plated Sun Diverters",
	"Oscillating Pollen Turbines",
	"Seed Conveyor Turbine",
	"Steam-Driven Root Infusers",
	"Condensate Reclaim Funnels",
	"Boiler-Piped Root Jackets",
	"Fog-Driven Moisture Manifolds",
	"Gear-Ratcheted Seeder Frames",
	"Coil-Spun Dew Harvesters",
	"Soil-Gauge Chronometers",
	"Piston-Driven Fertilizer Pumps",
	"Steam-Gridded Soil Plates",
	"Wire-Caged Airflow Trellises",
	"Reflective Brass Canopies",
	"Lever-Pumped Water Towers",
	"Pulley-Drawn Shade Mechanisms",
	"Auto-Sowing Apparatus",
	"Slag-Fired Nutrient Distillers",
	"Steam-Tubed Nutrient Conduits",
	"Auto-Harvest Engine",
	"Vapor-Sealed Growth Chambers",
	"Furnace-Driven Thermal Casings"
]

@export var station_name: String = "Storage"
var stored_items : Array[String] = []

func _ready() -> void:
	interaction_actions = {
		"Open Menu" : {
			"message" : "Upgrade",
			"input_action": "interact"
		},
		"Store Item" : {
			"message" : "Store Item",
			"input_action" : "interact_2",
		}
	}
	
	interacted.connect(_on_tech_station_interacted)

func accepts_item(item_id: String) -> bool:
	return item_id in accepted_item_ids

func _on_tech_station_interacted(player, action_id: String):
	match action_id:
		"Open Menu":
			player.UpgradeMenu.visible = true
		"Store Item":
			if player.held_item and accepts_item(player.held_item.id):
				player.held_item.collision_shape_3d.disabled = true
				player.held_item.visible = false
				player.held_item.is_picked_up = false
				stored_items.append(player.held_item.id)
				player.held_item = null
			else:
				print("This station doesn't accept that item")
