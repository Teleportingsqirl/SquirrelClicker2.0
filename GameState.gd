# GameState.gd
extends Node

var squirrels: float = 0.0
var squirrels_per_click: int = 1
var squirrels_per_second: float = 0.0
var buildings: Array = []

func _ready():
	load_game() 
	if buildings.is_empty():
		setup_buildings()
	recalculate_sps()

func _process(delta):
	squirrels += squirrels_per_second * delta
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mainmenu.tscn")


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
			"buildings": buildings
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
				print("Game Loaded!")
			else:
				print("Error: Save file is corrupted.")
		else:
			print("Error reading save file: ", file_path)
