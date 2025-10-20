# UpgradeData.gd
class_name UpgradeData
extends Node

# This dictionary holds all upgrade data. The key (e.g., "start_node") is the unique ID.
# 'unlocks' is an array of IDs for the upgrades this one makes available.
var upgrades = {
	"start_node": {
		"name": "Primal Instincts",
		"description": "Basic squirrel knowledge.",
		"cost": 0,
		"icon_path": "res://sqrlart/primalinstincts.png", # Replace with your art
		"unlocks": ["sharp_claws", "better_nuts", "unlock_forest"],
		"purchased": true # The first node is already "purchased"
	},
	"sharp_claws": {
		"name": "Sharp Claws",
		"description": "Increases squirrels per click by 1.",
		"cost": 50,
		"icon_path": "res://sqrlart/sharpclawsupgrade.png",
		"unlocks": [], # This is the end of a strand for now
		"purchased": false
	},
	"better_nuts": {
		"name": "Better Nuts",
		"description": "Increases SPS from all Nut buildings by 0.1.",
		"cost": 100,
		"icon_path": "res://sqrlart/upgraded nuts.png",
		"unlocks": [],
		"purchased": false
	},
	"unlock_forest": {
		"name": "Unlock The Forest",
		"description": "Unlocks a new area (feature coming soon!).",
		"cost": 250,
		"icon_path": "res://sqrlart/forestupgradeunlock.png",
		"unlocks": [],
		"purchased": false
	}
}
