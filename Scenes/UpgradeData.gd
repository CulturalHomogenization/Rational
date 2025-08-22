extends Node

var upgrades = {
	16: {
		"Upgrade Name": "Brass-Infused Soil Crucibles",
		"Description": "Soil trays laced with brass filings to fortify rootbeds.",
		"Dependencies": 1,
		"Buff Type": "Yield",
		"Buff Amount": 10,
		"Cost": {"Copper Pipe": 3, "Iron Plate": 2},
		"Signature Crafted Item": "Soil Crucible Array"
	},
	17: {
		"Upgrade Name": "Riveted Growth Lattices",
		"Description": "Rigid brass lattices coax plants upright, channeling vitality.",
		"Dependencies": 1,
		"Buff Type": "Growth Speed",
		"Buff Amount": 8,
		"Cost": {"Iron Gear": 4, "Copper Coil": 2},
		"Signature Crafted Item": "Lattice Gearframe"
	},
	18: {
		"Upgrade Name": "Mineral-Tuned Water Condensers",
		"Description": "Filtering condensers enrich irrigation with trace metals.",
		"Dependencies": 2,
		"Buff Type": "Yield",
		"Buff Amount": 12,
		"Cost": {"Iron Pipe": 6, "Mitre Gear": 3},
		"Signature Crafted Item": "Water Condenser Unit"
	},
	19: {
		"Upgrade Name": "Steam Seed Incubators",
		"Description": "Steam chambers accelerate sprouting with controlled heat.",
		"Dependencies": 2,
		"Buff Type": "Sowing Time",
		"Buff Amount": -10,
		"Cost": {"Copper Coil": 4, "Iron Plate": 3},
		"Signature Crafted Item": "Incubation Boiler"
	},
	20: {
		"Upgrade Name": "Coal-Fired Radiant Braziers",
		"Description": "Furnaces radiate constant warmth into crop rows.",
		"Dependencies": 3,
		"Buff Type": "Growth Speed",
		"Buff Amount": 14,
		"Cost": {"Copper Pipe": 8, "Coal Furnace": 1},
		"Signature Crafted Item": "Radiant Heat Array"
	},
	21: {
		"Upgrade Name": "Gear-Clamped Harvest Shears",
		"Description": "Mechanized shears reduce harvest time with precision.",
		"Dependencies": 3,
		"Buff Type": "Harvesting Time",
		"Buff Amount": -12,
		"Cost": {"Iron Gear": 5, "Copper Pipe": 4},
		"Signature Crafted Item": "Harvest Shear Engine"
	},
	22: {
		"Upgrade Name": "Pressure-Dial Water Regulators",
		"Description": "Dials fine-tune irrigation with steam-driven precision.",
		"Dependencies": 4,
		"Buff Type": "Growth Speed",
		"Buff Amount": 10,
		"Cost": {"Copper Valve": 3, "Iron Lever": 2},
		"Signature Crafted Item": "Irrigation Regulator"
	},
	23: {
		"Upgrade Name": "Steam-Powered Soil Augers",
		"Description": "Pneumatic augers churn soil, pumping in fresh oxygen.",
		"Dependencies": 4,
		"Buff Type": "Growth Speed",
		"Buff Amount": 12,
		"Cost": {"Iron Gear": 5, "Copper Pipe": 4},
		"Signature Crafted Item": "Soil Auger Core"
	},
	24: {
		"Upgrade Name": "Copper-Plated Sun Diverters",
		"Description": "Panels redirect sunlight deep into foliage efficiently.",
		"Dependencies": 5,
		"Buff Type": "Yield",
		"Buff Amount": 15,
		"Cost": {"Copper Panel": 3, "Iron Rivet": 6},
		"Signature Crafted Item": "Sun Diverter Assembly"
	},
	25: {
		"Upgrade Name": "Oscillating Pollen Turbines",
		"Description": "Rotating turbines distribute pollen evenly across crops.",
		"Dependencies": 5,
		"Buff Type": "Yield",
		"Buff Amount": 12,
		"Cost": {"Iron Gear": 4, "Copper Coil": 3},
		"Signature Crafted Item": "Pollination Turbine"
	},
	26: {
		"Upgrade Name": "Seed Conveyor Turbine",
		"Description": "Pneumatic turbine spreads seeds across soil beds.",
		"Dependencies": 6,
		"Buff Type": "Sowing Time",
		"Buff Amount": -20,
		"Cost": {"Copper Pipe": 6, "Iron Gear": 5},
		"Signature Crafted Item": "Seed Conveyor Core"
	},
	27: {
		"Upgrade Name": "Steam-Driven Root Infusers",
		"Description": "Pipes circulate enriched steam directly to roots.",
		"Dependencies": 6,
		"Buff Type": "Growth Speed",
		"Buff Amount": 15,
		"Cost": {"Iron Pipe": 8, "Copper Coil": 3},
		"Signature Crafted Item": "Root Infuser Engine"
	},
	28: {
		"Upgrade Name": "Condensate Reclaim Funnels",
		"Description": "Funnels capture steam to recycle as irrigation water.",
		"Dependencies": 6,
		"Buff Type": "Growth Speed",
		"Buff Amount": 12,
		"Cost": {"Mitre Gear": 5, "Iron Plate": 2},
		"Signature Crafted Item": "Condensation Funnel Unit"
	},
	29: {
		"Upgrade Name": "Boiler-Piped Root Jackets",
		"Description": "Steam jackets wrap around soil beds, warming roots steadily.",
		"Dependencies": 7,
		"Buff Type": "Growth Speed",
		"Buff Amount": 20,
		"Cost": {"Iron Pipe": 7, "Coal Furnace": 2},
		"Signature Crafted Item": "Root Jacket Assembly"
	},
	30: {
		"Upgrade Name": "Fog-Driven Moisture Manifolds",
		"Description": "Coal-heated mist saturates crops with humid vapors.",
		"Dependencies": 7,
		"Buff Type": "Growth Speed",
		"Buff Amount": 16,
		"Cost": {"Copper Valve": 5, "Coal Furnace": 3},
		"Signature Crafted Item": "Moisture Distribution Manifold"
	},
	31: {
		"Upgrade Name": "Gear-Ratcheted Seeder Frames",
		"Description": "Ratchet assemblies distribute seeds efficiently.",
		"Dependencies": 8,
		"Buff Type": "Sowing Time",
		"Buff Amount": -15,
		"Cost": {"Iron Gear": 6, "Copper Pipe": 4},
		"Signature Crafted Item": "Seeder Frame Gearwork"
	},
	32: {
		"Upgrade Name": "Coil-Spun Dew Harvesters",
		"Description": "Copper coils condense atmospheric moisture for irrigation.",
		"Dependencies": 8,
		"Buff Type": "Growth Speed",
		"Buff Amount": 15,
		"Cost": {"Copper Coil": 5, "Iron Pipe": 5},
		"Signature Crafted Item": "Dew Collector Unit"
	},
	33: {
		"Upgrade Name": "Soil-Gauge Chronometers",
		"Description": "Meters reveal soil conditions in real time.",
		"Dependencies": 9,
		"Buff Type": "Yield",
		"Buff Amount": 12,
		"Cost": {"Copper Valve": 3, "Iron Plate": 6},
		"Signature Crafted Item": "Soil Monitoring Instrument"
	},
	34: {
		"Upgrade Name": "Piston-Driven Fertilizer Pumps",
		"Description": "Pump assemblies force nutrients deep into roots.",
		"Dependencies": 9,
		"Buff Type": "Growth Speed",
		"Buff Amount": 18,
		"Cost": {"Copper Valve": 4, "Iron Gear": 4},
		"Signature Crafted Item": "Fertilizer Pump Engine"
	},
	35: {
		"Upgrade Name": "Steam-Gridded Soil Plates",
		"Description": "Heated plates prevent frost across entire soil beds.",
		"Dependencies": 10,
		"Buff Type": "Growth Speed",
		"Buff Amount": 20,
		"Cost": {"Copper Panel": 5, "Iron Pipe": 5},
		"Signature Crafted Item": "Gridded Soil Plate Array"
	},
	36: {
		"Upgrade Name": "Wire-Caged Airflow Trellises",
		"Description": "Mesh cages channel air currents to crops efficiently.",
		"Dependencies": 10,
		"Buff Type": "Growth Speed",
		"Buff Amount": 16,
		"Cost": {"Mitre Gear": 6, "Iron Rivet": 3},
		"Signature Crafted Item": "Airflow Trellis Unit"
	},
	37: {
		"Upgrade Name": "Reflective Brass Canopies",
		"Description": "Adjustable brass awnings shield crops from heat.",
		"Dependencies": 11,
		"Buff Type": "Yield",
		"Buff Amount": 18,
		"Cost": {"Copper Panel": 7, "Iron Gear": 4},
		"Signature Crafted Item": "Canopy Frame Assembly"
	},
	38: {
		"Upgrade Name": "Lever-Pumped Water Towers",
		"Description": "Pneumatic-assisted towers steadily deliver irrigation.",
		"Dependencies": 11,
		"Buff Type": "Growth Speed",
		"Buff Amount": 15,
		"Cost": {"Iron Lever": 4, "Copper Pipe": 5},
		"Signature Crafted Item": "Water Tower Engine"
	},
	39: {
		"Upgrade Name": "Pulley-Drawn Shade Mechanisms",
		"Description": "Automated pulleys adjust shading on demand.",
		"Dependencies": 12,
		"Buff Type": "Yield",
		"Buff Amount": 18,
		"Cost": {"Iron Gear": 6, "Copper Valve": 5},
		"Signature Crafted Item": "Shade Adjustment Engine"
	},
	40: {
		"Upgrade Name": "Auto-Sowing Apparatus",
		"Description": "Fully automated seeding rig, no manual input needed.",
		"Dependencies": 12,
		"Buff Type": "Auto Sowing",
		"Buff Amount": 0,
		"Cost": {"Iron Gear": 8, "Copper Pipe": 6, "Coal Furnace": 1},
		"Signature Crafted Item": "Automated Seeder Rig"
	},
	41: {
		"Upgrade Name": "Slag-Fired Nutrient Distillers",
		"Description": "Distillers brew nutrient-rich slurry for irrigation.",
		"Dependencies": 12,
		"Buff Type": "Yield",
		"Buff Amount": 20,
		"Cost": {"Coal Furnace": 4, "Copper Pipe": 6},
		"Signature Crafted Item": "Slurry Distiller Core"
	},
	42: {
		"Upgrade Name": "Steam-Tubed Nutrient Conduits",
		"Description": "Steam-laced conduits deliver enriched water to roots.",
		"Dependencies": 13,
		"Buff Type": "Growth Speed",
		"Buff Amount": 25,
		"Cost": {"Copper Coil": 8, "Iron Pipe": 4},
		"Signature Crafted Item": "Nutrient Conduit Engine"
	},
	43: {
		"Upgrade Name": "Auto-Harvest Engine",
		"Description": "Mechanized reaper reduces harvest labor.",
		"Dependencies": 13,
		"Buff Type": "Auto Harvesting",
		"Buff Amount": 0,
		"Cost": {"Iron Plate": 10, "Copper Valve": 6, "Coal Furnace": 1},
		"Signature Crafted Item": "Harvest Reaper Engine"
	},
	44: {
		"Upgrade Name": "Vapor-Sealed Growth Chambers",
		"Description": "Brass domes cycle steam and moisture for rapid growth.",
		"Dependencies": 14,
		"Buff Type": "Growth Speed",
		"Buff Amount": 30,
		"Cost": {"Copper Pipe": 8, "Coal Furnace": 4},
		"Signature Crafted Item": "Growth Chamber Core"
	},
	45: {
		"Upgrade Name": "Furnace-Driven Thermal Casings",
		"Description": "Massive furnaces radiate warmth for year-round yield.",
		"Dependencies": 15,
		"Buff Type": "Growth Speed",
		"Buff Amount": 40,
		"Cost": {"Coal Furnace": 9, "Iron Plate": 5},
		"Signature Crafted Item": "Thermal Casing Assembly"
	}
}
