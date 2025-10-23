# GameState.gd
extends Node

# --- All persistent game data lives here ---
var squirrels: float = 0.0
var squirrels_per_click: int = 1
var squirrels_per_second: float = 0.0
var buildings: Array = []

# --- Variables to communicate offline progress to the UI ---
var offline_seconds_passed: int = 0
var offline_squirrels_earned: float = 0.0

func _ready():
	load_game()
	if buildings.is_empty():
		setup_buildings()
	recalculate_sps()

func _process(delta):
	squirrels += squirrels_per_second * delta
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mainmenu.tscn")

# --- Core Game Logic ---

func setup_buildings():
	buildings = [
		{"name": "Nuts", "base_cost": 10, "sps": 0.1, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-sqrladdfornuts.png"},
		{"name": "Trees", "base_cost": 100, "sps": 1, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adfortree.png"},
		{"name": "Arboretums", "base_cost": 1000, "sps": 10, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-arboretum.png"},
		{"name": "Montreal", "base_cost": 10000, "sps": 100, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adformontreal.png"}
	]

func recalculate_sps():
	squirrels_per_second = 0.0
	for building in buildings:
		squirrels_per_second += building.owned * building.sps

func calculate_building_cost(building_index: int) -> int:
	if building_index >= 0 and building_index < buildings.size():
		var building = buildings[building_index]
		return int(ceil(building.base_cost * pow(1.1, building.owned)))
	return 0

# --- Saving & Loading with Offline Progress ---

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func save_game():
	var file_path = "user://savegame.dat"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"squirrels": squirrels,
			"squirrels_per_click": squirrels_per_click,
			"buildings": buildings,
			"save_timestamp": Time.get_unix_time_from_system() # <-- ADDED: Save current time
		}
		file.store_var(save_data)
		print("Game Saved!")
	else:
		print("Error writing save file: ", file_path)

func load_game():
	var file_path = "user://savegame.dat"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var loaded_data = file.get_var()
			if typeof(loaded_data) == TYPE_DICTIONARY:
				squirrels = loaded_data.get("squirrels", 0.0)
				squirrels_per_click = loaded_data.get("squirrels_per_click", 1)
				buildings = loaded_data.get("buildings", [])
				
				# --- OFFLINE PROGRESS CALCULATION ---
				recalculate_sps() # Must calculate SPS before finding offline earnings
				var saved_time = loaded_data.get("save_timestamp", 0)
				if saved_time > 0:
					var current_time = Time.get_unix_time_from_system()
					offline_seconds_passed = current_time - saved_time
					# We cap offline time to 7 days to prevent exploitation
					offline_seconds_passed = min(offline_seconds_passed, 7 * 24 * 60 * 60)
					
					offline_squirrels_earned = offline_seconds_passed * squirrels_per_second
					squirrels += offline_squirrels_earned
				# --- END OF CALCULATION ---
				
				print("Game Loaded!")
			else:
				print("Error: Save file is corrupted.")
		else:
			print("Error reading save file: ", file_path)

# This function lets the UI grab the offline progress info once.
func get_and_clear_offline_progress() -> Dictionary:
	var progress = {
		"seconds": offline_seconds_passed,
		"squirrels": offline_squirrels_earned
	}
	# Clear the values so the toast doesn't appear again if you revisit the scene
	offline_seconds_passed = 0
	offline_squirrels_earned = 0.0
	return progress
