# GameState.gd (Complete, Final Version with All Item Effects)
extends Node

# --- Core Game Data ---
var squirrels: float = 0.0
var squirrels_per_click: int = 1
var squirrels_per_second: float = 0.0
var buildings: Array = []
var all_items = {}
var owned_item_ids = []

# --- Buff/Multiplier Variables ---
var sps_multiplier = 1.0
var click_multiplier = 1.0
var temporary_sps_debuff = 1.0
var temporary_sps_buff = 1.0
var fazcoin_count = 0
var gyoza_debuff_multiplier = 1.0
var test_debuff_multiplier = 1.0

# --- Persistent Timer End Times ---
var steroid_end_time: int = 0
var tapeworm_end_time: int = 0
var pie_end_time: int = 0
var gyoza_end_time: int = 0
var test_end_time: int = 0

# --- Timers (for in-game use) ---
var steroid_timer: Timer
var tapeworm_timer: Timer
var gyoza_timer: Timer
var test_timer: Timer
var pie_timer: Timer
var autosave_timer: Timer

# --- Shop "Trap" System ---
var is_in_shop = false
var current_shop_items = []

# --- Offline Progress ---
var offline_seconds_passed: int = 0
var offline_squirrels_earned: float = 0.0

# --- "Mailbox" UI Communication System ---
var toast_mailbox = []
var sps_change_mailbox = []
var scene_change_mailbox = ""
var death_mailbox = false

# --- Settings ---
var config = ConfigFile.new()
var config_path = "user://settings.cfg"
var volume_db = 0.0
var is_fullscreen = false
var use_antialiasing = false

# --- CONSTANTS ---
const FAZCOIN_DESCRIPTIONS = [
	"Please deposit five coins.", "You are attempting to trick Freddy.",
	"You are attempting to trick Freddy.", "Freddy is the best. You are the best.",
	"Thank you for depositing five coins."
]

func _ready():
	load_settings()
	autosave_timer = Timer.new(); autosave_timer.wait_time = 5.0; autosave_timer.one_shot = false
	autosave_timer.timeout.connect(save_game); add_child(autosave_timer); autosave_timer.start()
	setup_items()
	load_game()
	if buildings.is_empty(): setup_buildings()
	_check_persistent_timers()
	recalculate_sps()

func _process(delta):
	squirrels += squirrels_per_second * delta
	if Input.is_action_just_pressed("ui_cancel") and not is_in_shop:
		SceneTransitioner.transition_to_scene("res://mainmenu.tscn", SceneTransitioner.TransitionMode.SLIDE_RIGHT)

func save_settings():
	config.set_value("audio", "volume_db", volume_db); config.set_value("graphics", "fullscreen", is_fullscreen)
	config.set_value("graphics", "antialiasing", use_antialiasing); config.save(config_path); print("Settings saved.")

func load_settings():
	var error = config.load(config_path)
	if error != OK: print("No settings file found. Saving defaults."); save_settings(); return
	volume_db = config.get_value("audio", "volume_db", 0.0)
	is_fullscreen = config.get_value("graphics", "fullscreen", false)
	use_antialiasing = config.get_value("graphics", "antialiasing", false)
	apply_settings()

func apply_settings():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	if is_fullscreen: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var new_fxaa_mode = Viewport.SCREEN_SPACE_AA_FXAA if use_antialiasing else Viewport.SCREEN_SPACE_AA_DISABLED
	if get_viewport().screen_space_aa != new_fxaa_mode:
		print("Applying new FXAA setting."); get_viewport().screen_space_aa = new_fxaa_mode

func setup_items():
	all_items = {
		"tapeworm": { "name": "A Tapeworm", "description": "It appears your squirrel was attempting to lose some weight. Gives you 3 hours of offline earnings instantly, but -20% sps for 30 seconds.", "texture_path": "res://sqrlart/shopart/Sprite-wormshopitem.png", "is_spawnable": true, "type": "powerup" },
		"steroids": { "name": "Squirrel Steroids", "description": "Taking steroids is just like pretending to be handicapped at the Special Olympics. Quadruples squirrels-per-click for 30 seconds.", "texture_path": "res://sqrlart/shopart/Sprite-sqrlsteriods.png", "is_spawnable": true, "type": "powerup" },
		"washing_machine": { "name": "A Washing Machine Heart", "description": "it seems to have a pair of dirty shoes in it. its all banged up inside.", "texture_path": "res://sqrlart/shopart/Sprite-washingmachineheart.png", "is_spawnable": true, "type": "cosmetic" },
		"Clock": { "name": "A Ticking Clock", "description": "It seems this squirrel has swallowed a ticking clock, and potentially developed a taste for human. Gives 1 hour of offline earnings instantly.", "texture_path": "res://sqrlart/shopart/Sprite-clockitem.png", "is_spawnable": true, "type": "powerup" },
		"pill": { "name": "A Pill", "description": "a strange blue pill that accentuates your squirrel's favorite features. x2 current sps permanantly due to gender euphoria.", "texture_path": "res://sqrlart/shopart/Sprite-pillshopitem.png", "is_spawnable": true, "type": "powerup" },
		"brain": { "name": "A Brain", "description": "Maybe a little inteligence would help your squirrels make the most of themselves. +10% permenant sps due to self actualisation. ", "texture_path": "res://sqrlart/shopart/Sprite-sqrlbrain.png", "is_spawnable": true, "type": "powerup" },
		"A Single Rose": { "name": "A Single Rose", "description": "A perfect looking single rose, sitting alone in the gaping cavity of the squirrel. It's beauty rivals that of the stars.", "texture_path": "res://sqrlart/shopart/Sprite-roseshopitem.png", "is_spawnable": true, "type": "permanent" },
		"3D Glasses": { "name": "3D Glasses", "description": "experience the wonder of squirrel clicker in 3D (3D Effects not included)", "texture_path": "res://sqrlart/shopart/Sprite-3dglassesitem.png", "is_spawnable": true, "type": "cosmetic" },
		"Letter From Dad": { "name": "A Letter From Your Father.", "description": "Seems to do nothing, but you feel a stir in your file directory.", "texture_path": "res://sqrlart/shopart/Sprite-letterfromdad.png", "is_spawnable": true, "type": "permanent" },
		"Christmas tree": { "name": "Christmas Tree", "description": "Celebrate your holiday cheer! Base of tree is appropriately flared so as to prevent injury or loss.", "texture_path": "res://sqrlart/shopart/Sprite-christmas tree.png", "is_spawnable": true, "type": "cosmetic" },
		"mr_primal": { "name": "Mr. Primal Instinct", "description": "A mysterious gentleman. He offers you +5% sps. Surely nothing will come of his involvement.", "texture_path": "res://sqrlart/shopart/Sprite-mr.png", "is_spawnable": true, "type": "permanent" },
		"bandaid": { "name": "A Bandaid", "description": "Heals your wounded squirrels so they can be further injured at a later date. +10% of your sps permenantly.", "texture_path": "res://sqrlart/shopart/Sprite-bandaid.png", "is_spawnable": true, "type": "powerup" },
		"ButtsPie": { "name": "A Pie", "description": "Butterscotch-cinnamon pie, one slice. The smell reminded SQUIRRELS of something. x2 sps for 10 minutes.", "texture_path": "res://sqrlart/shopart/Sprite-cinnamonbutterscotchpie.png", "is_spawnable": true, "type": "powerup" },
		"Companion Cube": { "name": "A Companion", "description": "If it could talk - and the Enrichment Center takes this opportunity to remind you that it cannot - it would tell you to get more squirrels.", "texture_path": "res://sqrlart/shopart/Sprite-companioncude.png", "is_spawnable": true, "type": "cosmetic" },
		"Fazcoin": { "name": "A Fazcoin", "description": "Please deposit five coins.", "texture_path": "res://sqrlart/shopart/Sprite-fazcoin.png", "is_spawnable": true, "type": "powerup" },
		"HR": { "name": "Human Resources", "description": "A team of investigators has levied claims againts your squirrels for professional indecency and nudity in the workplace. They fire 3 random different buildings (if possible).", "texture_path": "res://sqrlart/shopart/Sprite-humanresources.png", "is_spawnable": true, "type": "evil" },
		"Wheat": { "name": "A bundle of wheat", "description": "A small bundle of wheat to be fed to the squirrels. This will put them in love mode, meaning even more squirrels. Doubles your current squirrel count.", "texture_path": "res://sqrlart/shopart/Sprite-wheatitem.png", "is_spawnable": true, "type": "powerup" },
		"Gyoza": { "name": "A Gyoza", "description": "It tastes the same as the gyoza you have been eating for 15 years. -15% sps for 15 minutes", "texture_path": "res://sqrlart/shopart/Sprite-goyzaitem.png", "is_spawnable": true, "type": "evil" },
		"The Plant": { "name": "The Plant", "description": "The Plant breaks buildings because plants do not have buildings. Lose 1 of your highest yielding building.", "texture_path": "res://sqrlart/shopart/Sprite-theplantitem.png", "is_spawnable": true, "type": "evil" },
		"Liquid Pain": { "name": "Object 12: Liquid Pain", "description": "Liquid Pain is capable of dissolving flesh and other soft substances. Due to this, it is highly unadvised to make contact with it.", "texture_path": "res://sqrlart/shopart/Sprite-liquidpainitem.png", "is_spawnable": true, "type": "evil" },
		"Loss": { "name": "Loss", "description": "Im at a loss for words. Lose all your squirrels.", "texture_path": "res://sqrlart/shopart/Sprite-lossitem.png", "is_spawnable": true, "type": "evil" },
		"Pregnancy test": { "name": "A negative pregnancy test.", "description": "mass squirrel infertility leads to less squirrels. -10% sps for 5 minutes", "texture_path": "res://sqrlart/shopart/Sprite-testitem.png", "is_spawnable": true, "type": "evil" },
		"A NICE ICE KEY": { "name": "Ice Key", "description": "NOW YOU CAN SEE A NICE ICE KEY WHICH YOU CAN HAVE FOR FREE", "texture_path": "res://sqrlart/shopart/Sprite-icekey.png", "is_spawnable": true, "type": "cosmetic" }
	}

func setup_buildings():
	buildings = [
		{"name": "Nuts", "base_cost": 10, "sps": 0.1, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-sqrladdfornuts.png"},
		{"name": "Trees", "base_cost": 100, "sps": 1, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adfortree.png"},
		{"name": "Arboretums", "base_cost": 1000, "sps": 10, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-arboretum.png"},
		{"name": "Montreal", "base_cost": 10000, "sps": 100, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adformontreal.png"},
		{"name": "Grandfather Paradox", "base_cost": 100000, "sps": 1000, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforgrandfatherparadox.png"},
		{"name": "Free Healthcare", "base_cost": 1000000, "sps": 10000, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforfreehealthcare.png"},
		{"name": "Persona", "base_cost": 10000000, "sps": 100000, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforpersona.png"},
		{"name": "Foxes", "base_cost": 100000000, "sps": 1000000, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforherdingfoxes.png"}
	]

func recalculate_sps():
	var old_sps = squirrels_per_second
	var base_sps = 0.0
	for building in buildings: base_sps += building.owned * building.sps
	squirrels_per_second = base_sps * sps_multiplier * temporary_sps_debuff * temporary_sps_buff * gyoza_debuff_multiplier * test_debuff_multiplier
	if not is_equal_approx(old_sps, squirrels_per_second):
		sps_change_mailbox.append({"old": old_sps, "new": squirrels_per_second})

func calculate_building_cost(building_index: int) -> int:
	if building_index >= 0 and building_index < buildings.size():
		var building = buildings[building_index]
		return int(ceil(building.base_cost * pow(1.1, building.owned)))
	return 0

func apply_item_effect(item_id: String):
	if not all_items.has(item_id): return
	var item_data = all_items[item_id]
	match item_id:
		"tapeworm":
			var earnings = squirrels_per_second * 10800; squirrels += earnings
			toast_mailbox.append("Gained %s squirrels!" % format_number(earnings, true)); _apply_tapeworm_debuff()
		"Clock":
			var earnings = squirrels_per_second * 3600; squirrels += earnings
			toast_mailbox.append("Gained %s squirrels!" % format_number(earnings, true))
		"steroids": _apply_steroid_buff()
		"pill": sps_multiplier *= 2.0
		"brain": sps_multiplier += 0.10
		"mr_primal": sps_multiplier += 0.05
		"bandaid": sps_multiplier += 0.10
		"ButtsPie": _apply_pie_buff()
		"Wheat": squirrels *= 2
		"Fazcoin":
			fazcoin_count += 1
			if fazcoin_count >= 5: scene_change_mailbox = "res://3d squirrel.tscn"
		"HR": _fire_random_buildings(3)
		"Gyoza": _apply_gyoza_debuff()
		"The Plant": _remove_best_building()
		"Liquid Pain":
			is_in_shop = false
			death_mailbox = true
		"Loss": squirrels = 0
		"Pregnancy test": _apply_test_debuff()

	if item_data.type == "permanent" or item_data.type == "cosmetic":
		if not owned_item_ids.has(item_id): owned_item_ids.append(item_id)
	recalculate_sps()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_game(); get_tree().quit()

func save_game():
	var file_path = "user://savegame.dat"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"squirrels": squirrels, "squirrels_per_click": squirrels_per_click, "buildings": buildings,
			"save_timestamp": Time.get_unix_time_from_system(), "owned_item_ids": owned_item_ids,
			"sps_multiplier": sps_multiplier, "fazcoin_count": fazcoin_count,
			"is_in_shop": is_in_shop, "current_shop_items": current_shop_items,
			"steroid_end_time": steroid_end_time, "tapeworm_end_time": tapeworm_end_time, "pie_end_time": pie_end_time,
			"gyoza_end_time": gyoza_end_time, "test_end_time": test_end_time
		}
		file.store_var(save_data); print("Game Saved!")
	else: print("Error writing save file: ", file_path)

func load_game():
	var file_path = "user://savegame.dat"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var loaded_data = file.get_var()
			if typeof(loaded_data) == TYPE_DICTIONARY:
				setup_buildings()
				var saved_buildings = loaded_data.get("buildings", []); var saved_progress = {}; for b in saved_buildings: saved_progress[b.name] = b.owned
				for b in buildings:
					if saved_progress.has(b.name): b.owned = saved_progress[b.name]
				squirrels = loaded_data.get("squirrels", 0.0); squirrels_per_click = loaded_data.get("squirrels_per_click", 1)
				owned_item_ids = loaded_data.get("owned_item_ids", []); sps_multiplier = loaded_data.get("sps_multiplier", 1.0)
				fazcoin_count = loaded_data.get("fazcoin_count", 0)
				is_in_shop = loaded_data.get("is_in_shop", false); current_shop_items = loaded_data.get("current_shop_items", [])
				steroid_end_time = loaded_data.get("steroid_end_time", 0); tapeworm_end_time = loaded_data.get("tapeworm_end_time", 0)
				pie_end_time = loaded_data.get("pie_end_time", 0)
				gyoza_end_time = loaded_data.get("gyoza_end_time", 0)
				test_end_time = loaded_data.get("test_end_time", 0)
				
				var saved_time = loaded_data.get("save_timestamp", 0)
				if saved_time > 0:
					var temp_sps = 0.0
					for b in buildings: temp_sps += b.owned * b.sps
					temp_sps *= sps_multiplier
					var current_time = Time.get_unix_time_from_system(); offline_seconds_passed = current_time - saved_time
					offline_squirrels_earned = offline_seconds_passed * temp_sps; squirrels += offline_squirrels_earned
				print("Game Loaded!")
			else: print("Error: Save file is corrupted.")
		else: print("Error reading save file: ", file_path)

func reset_game_state():
	squirrels = 0.0; squirrels_per_click = 1; sps_multiplier = 1.0
	offline_seconds_passed = 0; offline_squirrels_earned = 0.0
	owned_item_ids = []; fazcoin_count = 0
	temporary_sps_buff = 1.0; temporary_sps_debuff = 1.0
	is_in_shop = false; current_shop_items = []
	steroid_end_time = 0; tapeworm_end_time = 0; pie_end_time = 0
	gyoza_debuff_multiplier = 1.0; test_debuff_multiplier = 1.0
	gyoza_end_time = 0; test_end_time = 0
	setup_buildings(); recalculate_sps()

func get_and_clear_offline_progress() -> Dictionary:
	var progress = { "seconds": offline_seconds_passed, "squirrels": offline_squirrels_earned }
	offline_seconds_passed = 0; offline_squirrels_earned = 0.0
	return progress

func _apply_steroid_buff():
	if not is_instance_valid(steroid_timer):
		steroid_timer = Timer.new(); steroid_timer.one_shot = true
		steroid_timer.timeout.connect(_on_steroid_timer_timeout); add_child(steroid_timer)
	click_multiplier = 4.0; steroid_end_time = Time.get_unix_time_from_system() + 30; steroid_timer.start(30.0)

func _on_steroid_timer_timeout():
	click_multiplier = 1.0; steroid_end_time = 0

func _apply_tapeworm_debuff():
	if not is_instance_valid(tapeworm_timer):
		tapeworm_timer = Timer.new(); tapeworm_timer.one_shot = true
		tapeworm_timer.timeout.connect(_on_tapeworm_timer_timeout); add_child(tapeworm_timer)
	temporary_sps_debuff = 0.8; tapeworm_end_time = Time.get_unix_time_from_system() + 30; tapeworm_timer.start(30.0); recalculate_sps()

func _on_tapeworm_timer_timeout():
	temporary_sps_debuff = 1.0; tapeworm_end_time = 0; recalculate_sps()

func _apply_pie_buff():
	if not is_instance_valid(pie_timer):
		pie_timer = Timer.new(); pie_timer.one_shot = true
		pie_timer.timeout.connect(_on_pie_timer_timeout); add_child(pie_timer)
	temporary_sps_buff = 2.0; pie_end_time = Time.get_unix_time_from_system() + 600; pie_timer.start(600.0); recalculate_sps()

func _on_pie_timer_timeout():
	temporary_sps_buff = 1.0; pie_end_time = 0; recalculate_sps()
	
func _apply_gyoza_debuff():
	if not is_instance_valid(gyoza_timer):
		gyoza_timer = Timer.new(); gyoza_timer.one_shot = true
		gyoza_timer.timeout.connect(_on_gyoza_timer_timeout); add_child(gyoza_timer)
	gyoza_debuff_multiplier = 0.85
	gyoza_end_time = Time.get_unix_time_from_system() + 900
	gyoza_timer.start(900.0); recalculate_sps()

func _on_gyoza_timer_timeout():
	gyoza_debuff_multiplier = 1.0; gyoza_end_time = 0; recalculate_sps()

func _apply_test_debuff():
	if not is_instance_valid(test_timer):
		test_timer = Timer.new(); test_timer.one_shot = true
		test_timer.timeout.connect(_on_test_timer_timeout); add_child(test_timer)
	test_debuff_multiplier = 0.90
	test_end_time = Time.get_unix_time_from_system() + 300
	test_timer.start(300.0); recalculate_sps()

func _on_test_timer_timeout():
	test_debuff_multiplier = 1.0; test_end_time = 0; recalculate_sps()

func _remove_best_building():
	if buildings.is_empty(): return
	var best_building_index = -1; var highest_yield = -1.0
	for i in range(buildings.size()):
		var building = buildings[i]
		if building.owned > 0:
			var building_yield = building.owned * building.sps
			if building_yield > highest_yield:
				highest_yield = building_yield; best_building_index = i
	if best_building_index != -1:
		buildings[best_building_index].owned -= 1
		toast_mailbox.append("The Plant destroyed one %s!" % buildings[best_building_index].name)
		recalculate_sps()

func _fire_random_buildings(count: int):
	var owned_buildings_indices = []
	for i in range(buildings.size()):
		if buildings[i].owned > 0:
			owned_buildings_indices.append(i)
	
	var buildings_fired = 0
	while not owned_buildings_indices.is_empty() and buildings_fired < count:
		owned_buildings_indices.shuffle()
		var index_to_fire = owned_buildings_indices.pop_front()
		buildings[index_to_fire].owned -= 1
		toast_mailbox.append("HR fired one %s!" % buildings[index_to_fire].name)
		buildings_fired += 1
	
	if buildings_fired > 0:
		recalculate_sps()
	
func _check_persistent_timers():
	var current_time = Time.get_unix_time_from_system()
	if steroid_end_time > current_time:
		var remaining = steroid_end_time - current_time
		if not is_instance_valid(steroid_timer): steroid_timer = Timer.new(); steroid_timer.one_shot = true; steroid_timer.timeout.connect(_on_steroid_timer_timeout); add_child(steroid_timer)
		click_multiplier = 4.0; steroid_timer.start(float(remaining))
	if tapeworm_end_time > current_time:
		var remaining = tapeworm_end_time - current_time
		if not is_instance_valid(tapeworm_timer): tapeworm_timer = Timer.new(); tapeworm_timer.one_shot = true; tapeworm_timer.timeout.connect(_on_tapeworm_timer_timeout); add_child(tapeworm_timer)
		temporary_sps_debuff = 0.8; tapeworm_timer.start(float(remaining))
	if pie_end_time > current_time:
		var remaining = pie_end_time - current_time
		if not is_instance_valid(pie_timer): pie_timer = Timer.new(); pie_timer.one_shot = true; pie_timer.timeout.connect(_on_pie_timer_timeout); add_child(pie_timer)
		temporary_sps_buff = 2.0; pie_timer.start(float(remaining))
	if gyoza_end_time > current_time:
		var remaining = gyoza_end_time - current_time
		if not is_instance_valid(gyoza_timer): gyoza_timer = Timer.new(); gyoza_timer.one_shot = true; gyoza_timer.timeout.connect(_on_gyoza_timer_timeout); add_child(gyoza_timer)
		gyoza_debuff_multiplier = 0.85; gyoza_timer.start(float(remaining))
	if test_end_time > current_time:
		var remaining = test_end_time - current_time
		if not is_instance_valid(test_timer): test_timer = Timer.new(); test_timer.one_shot = true; test_timer.timeout.connect(_on_test_timer_timeout); add_child(test_timer)
		test_debuff_multiplier = 0.90; test_timer.start(float(remaining))
	
func format_number(number: float, allow_decimals: bool = false) -> String:
	if number < 1000.0:
		if allow_decimals:
			if fmod(number, 1.0) == 0: return str(int(number))
			else: return "%.1f" % number
		else: return str(int(number))
	const SUFFIXES = ["", "K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc","Ud","Dd","Td","Qad","Qid","Sxd","Spd","Ocd","Nod","Vg","Uvg","Dvg","Tvg","Qavg","Qivg","Sxvg","Spvg","Ocvg","Novg","Tg","Utg","Dtg","Goog"];
	var magnitude = int(floor(log(number) / log(1000))); if magnitude >= SUFFIXES.size(): magnitude = SUFFIXES.size() - 1
	var divisor = pow(1000, magnitude); var abbreviated_num = number / divisor; var suffix = SUFFIXES[magnitude]; var formatted_string: String
	if fmod(abbreviated_num, 1.0) == 0: formatted_string = "%d" % int(abbreviated_num)
	elif abbreviated_num < 10: formatted_string = "%.2f" % abbreviated_num
	elif abbreviated_num < 100: formatted_string = "%.1f" % abbreviated_num
	else: formatted_string = "%d" % int(abbreviated_num)
	return formatted_string + suffix

func update_spawnable_items():
	if all_items.has("Fazcoin"):
		if fazcoin_count < 5: all_items.Fazcoin.is_spawnable = true
		else: all_items.Fazcoin.is_spawnable = false
