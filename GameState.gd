# GameState.gd
extends Node

var game_is_ready: bool = false
var active_scene_path: String = ""
var squirrels: float = 0.0
var squirrels_per_click: float = 1
var squirrels_per_second: float = 0.0
var buildings: Array = []
var all_items = {}
var owned_item_ids = []
var total_clicks: int = 0
var total_squirrels_earned: float = 0.0

var sps_multiplier = 1.0
var click_multiplier = 1.0
var temporary_sps_debuff = 1.0
var temporary_sps_buff = 1.0
var fazcoin_count = 0
var gyoza_debuff_multiplier = 1.0
var test_debuff_multiplier = 1.0

var steroid_end_time: float = 0.0
var tapeworm_end_time: float = 0.0
var pie_end_time: float = 0.0
var gyoza_end_time: float = 0.0
var test_end_time: float = 0.0

var steroid_timer: Timer
var tapeworm_timer: Timer
var gyoza_timer: Timer
var test_timer: Timer
var pie_timer: Timer
var autosave_timer: Timer

var is_in_shop = false
var current_shop_items = []

var offline_seconds_passed: float = 0.0
var offline_squirrels_earned: float = 0.0

var toast_mailbox = []
var sps_change_mailbox = []
var scene_change_mailbox = ""
var death_mailbox = false
var building_unlocked_mailbox = []

var all_upgrades = {}
var owned_upgrade_ids: Array = []


var config = ConfigFile.new()
var config_path = "user://settings.cfg"
var volume_db = 0.0
var is_fullscreen = false
var use_antialiasing = false

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
	setup_upgrades()
	load_game()
	if buildings.is_empty(): setup_buildings()
	_check_persistent_timers()
	recalculate_sps()

func _process(delta):
	var earned_this_frame = squirrels_per_second * delta
	squirrels += earned_this_frame
	total_squirrels_earned += earned_this_frame
	check_unlock_conditions()


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
		"HR": { "name": "Human Resources", "description": "A team of investigators has levied claims againts your squirrels for professional indecency and nudity in the workplace. They fire 3 random buildings.", "texture_path": "res://sqrlart/shopart/Sprite-humanresources.png", "is_spawnable": true, "type": "evil" },
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
		{"name": "Nuts", "base_cost": 10.0, "sps": 0.1, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-sqrladdfornuts.png", "unlocked": true},
		{"name": "Trees", "base_cost": 100.0, "sps": 1.0, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adfortree.png", "unlocked": true},
		{"name": "Arboretums", "base_cost": 1000.0, "sps": 10.0, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-arboretum.png", "unlocked": true},
		{"name": "Montreal", "base_cost": 1.0e4, "sps": 100.0, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adformontreal.png", "unlocked": false, 
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e3, "unlock_condition_text": "Earn 1k total squirrels"},
		{"name": "Grandfather Paradox", "base_cost": 1.0e5, "sps": 1.0e3, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforgrandfatherparadox.png", "unlocked": false,
		 "unlock_condition_type": "upgrade_owned", "unlock_condition_target": "egg", "unlock_condition_text": "Requires the 'Stop-&-Swap Egg' upgrade"},
		{"name": "Free Healthcare", "base_cost": 1.0e6, "sps": 1.0e4, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforfreehealthcare.png", "unlocked": false,
		 "unlock_condition_type": "total_clicks", "unlock_condition_value": 10000, "unlock_condition_text": "Click the squirrel 10,000 times"},
		{"name": "Persona", "base_cost": 1.0e7, "sps": 1.0e5, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforpersona.png", "unlocked": false,
		 "unlock_condition_type": "upgrade_owned", "unlock_condition_target": "jokers_mask", "unlock_condition_text": "Requires the 'Mask of Rebellion' upgrade"},
		{"name": "Foxes", "base_cost": 1.0e8, "sps": 1.0e6, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforherdingfoxes.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e8, "unlock_condition_text": "Earn 100 million total squirrels"},
		{"name": "Dogs", "base_cost": 1.0e10, "sps": 1.0e7, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-dogstoherdfoxes.png", "unlocked": false,
		 "unlock_condition_type": "upgrade_owned", "unlock_condition_target": "dogs", "unlock_condition_text": "Requires the 'Herding Dogs' upgrade"},
		{"name": "Cats", "base_cost": 1.0e12, "sps": 1.0e9, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-catstoherddogs.png", "unlocked": false,
		 "unlock_condition_type": "upgrade_owned", "unlock_condition_target": "cats", "unlock_condition_text": "Requires the 'Herding Cats' upgrade"},
		{"name": "Futility", "base_cost": 1.0e14, "sps": 1.0e11, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-conceptoffutiilitytoherdcats.png", "unlocked": false,
		 "unlock_condition_type": "upgrade_owned", "unlock_condition_target": "futility", "unlock_condition_text": "Requires the 'Concept of Futility' upgrade"},
		{"name": "Chainsaw", "base_cost": 1.0e15, "sps": 1.0e12, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforchainsaws.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e15, "unlock_condition_text": "Earn 1Qa total squirrels"},
		{"name": "Nuclear Bombs", "base_cost": 1.0e17, "sps": 1.0e15, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adfornucelear.png", "unlocked": false,
		 "unlock_condition_type": "item_owned", "unlock_condition_target": "Liquid Pain", "unlock_condition_text": "Become death, destroyer of worlds, by dying"},
		{"name": "Dead End Job", "base_cost": 1.0e20, "sps": 1.0e18, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adfordeadendjob.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e20, "unlock_condition_text": "Earn 100Qi total squirrels"},
		{"name": "Heavy Rain", "base_cost": 1.0e23, "sps": 1.0e21, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforheavyrain.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e23, "unlock_condition_text": "Earn 100Sx total squirrels"},
		{"name": "Abandoned Flower", "base_cost": 1.0e26, "sps": 1.0e24, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforflower.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e26, "unlock_condition_text": "Earn 100Sp total squirrels"},
		{"name": "Empty Corner", "base_cost": 1.0e29, "sps": 1.0e27, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforemptycorner.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e29, "unlock_condition_text": "Earn 100Oc total squirrels"},
		{"name": "Forest Fire", "base_cost": 1.0e32, "sps": 1.0e30, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforforestfires.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e32, "unlock_condition_text": "Earn 100No total squirrels"},
		{"name": "Hiding Place", "base_cost": 1.0e35, "sps": 1.0e33, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-addforhidingspot.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e35, "unlock_condition_text": "Earn 100Dc total squirrels"},
		{"name": "White Ferrari", "base_cost": 1.0e38, "sps": 1.0e36, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforwhiteferrari.png", "unlocked": false,
		 "unlock_condition_type": "upgrade_owned", "unlock_condition_target": "note", "unlock_condition_text": "Requires the 'Music Note' upgrade"},
		{"name": "Wildfire in my sock drawer", "base_cost": 1.0e41, "sps": 1.0e39, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforsockdrawer.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e41, "unlock_condition_text": "Earn 100Dd total squirrels"},
		{"name": "Tree of Life", "base_cost": 1.0e44, "sps": 1.0e42, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-treeoflifead.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e44, "unlock_condition_text": "Earn 100Td total squirrels"},
		{"name": "The House", "base_cost": 1.0e49, "sps": 1.0e47, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-adforthehouse.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e49, "unlock_condition_text": "Earn 100Qid total squirrels"},
		{"name": "Moose in Alaska", "base_cost": 1.0e100, "sps": 1.0e98, "owned": 0, "texture_path": "res://sqrlart/ads/Sprite-mooseinalaskaad.png", "unlocked": false,
		 "unlock_condition_type": "total_squirrels_earned", "unlock_condition_value": 1.0e100, "unlock_condition_text": "Earn a Googol total squirrels"}
	]

func setup_upgrades():
	var start_pos = Vector2(736, 1746) 
	var v_space = 180.0
	var h_space = 240.0
	
	all_upgrades = {
		"first_click":   { "name": "First Place Medal", "description": "Maybe now your father will be proud. Grants +1 squirrel per click.", 
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-firstplacemedal.png", "cost": 50.0,
						   "effect_type": "click_flat", "effect_value": 1.0, 
						   "dependencies": [], "position": start_pos },

		"second_click":  { "name": "Second Place", "description": "Your father is not proud. Grants another +4 squirrels per click.", 
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-secondplaceupgrade.png", "cost": 300.0,
						   "effect_type": "click_flat", "effect_value": 4.0, 
						   "dependencies": ["first_click"], "position": start_pos + Vector2(0, -v_space) },
		
		"shirt":         { "name": "Red & Blue Shirt", "description": "A slightly sticky blue and red shirt. It has a strange medallion. Global SPS is permanently increased by 10%.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-blueandredshirtupgrade.png", "cost": 2500.0,
						   "effect_type": "sps_multiplier", "effect_value": 0.10,
						   "dependencies": ["second_click"], "position": start_pos + Vector2(-h_space * 1.5, -v_space * 2) },
						   
		"tall":          { "name": "Tall Squirrels", "description": "Taller squirrels can reach higher branches to get more squirrels. Triples the effectiveness of all Trees.", 
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-tallsquirrel.png", "cost": 15000.0,
						   "effect_type": "building_sps_multiplier", "effect_target": "Trees", "effect_value": 3.0, 
						   "dependencies": ["shirt"], "position": start_pos + Vector2(-h_space * 1.5, -v_space * 3) },
						   
		"arrow":         { "name": "Stand Arrow", "description": "You feel more motivated to click. Grants +25 squirrels per click.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-standarrowupgrade.png", "cost": 5.0e5,
						   "effect_type": "click_flat", "effect_value": 25.0,
						   "dependencies": ["tall"], "position": start_pos + Vector2(-h_space * 1.5, -v_space * 4) },

		"white_mask":    { "name": "Health Mask", "description": "The Health Mask is a representation of your squirrels health. This new one gives you +10% production for everything.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-maskupgrade.png", "cost": 5.0e6,
						   "effect_type": "sps_multiplier", "effect_value": 0.10,
						   "dependencies": ["arrow"], "position": start_pos + Vector2(-h_space * 1.5, -v_space * 5) },
		
		"negative_squirrel":   { "name": "Negative Squirrels", "description": "Through forbidden science, you create anti-squirrels. Each click now also generates 2% of your SPS.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-negativesquirrel.png", "cost": 1.0e8,
						   "effect_type": "click_from_sps", "effect_value": 0.02,
						   "dependencies": ["white_mask"], "position": start_pos + Vector2(-h_space * 1.5, -v_space * 6) },
						   
		"bomb_head":     { "name": "Hybrid Heart", "description": "A contract is made. Your clicks now rip and tear, adding 0.1% of your total SPS to each click.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-bombupgrade.png", "cost": 1.0e16,
						   "effect_type": "click_from_sps", "effect_value": 0.001, 
						   "dependencies": ["negative"], "position": start_pos + Vector2(-h_space * 1.5, -v_space * 7) },

		"nubby":         { "name": "Nubby Squirrels", "description": "Nubby likes trees, and brings his own fake plastic ones. Each Tree you own provides an additional +2 SPS.", 
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-nubbyupgrade.png", "cost": 1500.0,
						   "effect_type": "building_sps_flat", "effect_target": "Trees", "effect_value": 2.0, 
						   "dependencies": ["second_click"], "position": start_pos + Vector2(-h_space * 0.5, -v_space * 2) },

		"jokers_mask":   { "name": "Mask of Rebellion", "description": "Embrace your inner self. Unlocks the persona building and increases total SPS by 2% for each distinct type of building you own at least one of.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-pesonaupgrade.png", "cost": 7.5e5,
						   "effect_type": "sps_per_building_type_and_unlock", "effect_value": 0.02, "unlock_target": "Persona",
						   "dependencies": ["nubby"], "position": start_pos + Vector2(-h_space * 0.5, -v_space * 3) },
						   
		"feather":       { "name": "Golden Feather", "description": "Your clicks become invincible, but were never in danger. Still, all click gains are doubled.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-featherupgrade.png", "cost": 5.0e7,
						   "effect_type": "click_multiplier", "effect_value": 1.0,
						   "dependencies": ["jokers_mask"], "position": start_pos + Vector2(-h_space * 0.5, -v_space * 4) },
						   
		"wheatley":      { "name": "Wheat Companion", "description": "This is the part where he gets squirrels. All building production is doubled.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-wheatlyupgrade.png", "cost": 1.0e9,
						   "effect_type": "sps_multiplier", "effect_value": 1.0,
						   "dependencies": ["feather"], "position": start_pos + Vector2(-h_space * 0.5, -v_space * 5) },

		"rhinestone_eyes":{ "name": "Rhinestone Eyes", "description": "You see the value in everything. Global SPS multiplier is increased by a flat +0.25.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-rhinestoneeyesupgrade.png", "cost": 5.0e9,
						   "effect_type": "sps_multiplier", "effect_value": 0.25, 
						   "dependencies": ["wheatley"], "position": start_pos + Vector2(-h_space * 0.5, -v_space * 6) },

		"runners_vision":{ "name": "Runner's Vision", "description": "The world slows down, and the path becomes clear. Every click permanently increases your base SPS by a minuscule amount (+0.01).",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-reddoorupgrade.png", "cost": 1.0e12,
						   "effect_type": "sps_per_click", "effect_value": 0.01, 
						   "dependencies": ["rhinestone_eyes"], "position": start_pos + Vector2(-h_space * 0.5, -v_space * 7) },
						
		"strawberry":    { "name": "A Single Strawberry", "description": "You could make a pie out of these. All click gains are boosted by 25%.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-strawberryupgrade.png", "cost": 1000.0,
						   "effect_type": "click_multiplier", "effect_value": 0.25,
						   "dependencies": ["second_click"], "position": start_pos + Vector2(h_space * 0.5, -v_space * 2) },

		"egg":           { "name": "Stop-&-Swap Egg", "description": "About time! We’ve been waiting over ten years for this thing! Grants a massive flat bonus of +1,000 SPS and unlocks the Grandfather Paradox building.", 
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-questionmarkeggupgrade.png", "cost": 1.0e5,
						   "effect_type": "sps_flat_and_unlock", "effect_value": 1000.0, "unlock_target": "Grandfather Paradox",
						   "dependencies": ["strawberry"], "position": start_pos + Vector2(h_space * 0.5, -v_space * 3) },

		"note":          { "name": "Music Note", "description": "It's a Note, one of a hundred on each world. Unlocks the White Ferrari building.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-musicnoteupgrade.png", "cost": 1.0e37,
						   "effect_type": "unlock_building", "effect_value": "White Ferrari",
						   "dependencies": ["egg"], "position": start_pos + Vector2(h_space * 0.5, -v_space * 4) },

		"cuphead":       { "name": "Soul Contract", "description": "You sell your soul for more squirrels. Doubles the production of all buildings with two-word names, but makes them 10% more expensive.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-cuphead.png", "cost": 1.0e40,
						   "effect_type": "conditional_building_multiplier", "effect_value": 2.0, 
						   "dependencies": ["note"], "position": start_pos + Vector2(h_space * 0.5, -v_space * 5) },

		"algebra":       { "name": "Squirrel Algebra", "description": "Your squirrels learn to count themselves properly. Global SPS is permanently increased by 15%.", 
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-algebraupgrade.png", "cost": 50000.0,
						   "effect_type": "sps_multiplier", "effect_value": 0.15, 
						   "dependencies": ["strawberry"], "position": start_pos + Vector2(h_space * 1.5, -v_space * 3) },

		"scintillation": { "name": "Scintillation", "description": "Everything is just a little bit brighter. All global SPS percentage multiplier upgrades (like this one!) are 5% more effective.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-fancysparklesupgrade.png", "cost": 1.0e8,
						   "effect_type": "meta_multiplier", "effect_value": 0.05, 
						   "dependencies": ["algebra"], "position": start_pos + Vector2(h_space * 1.5, -v_space * 4) },

		"knight_magic":  { "name": "Knight's Magic", "description": "The knight uses magic, permanantly doubling the output of nuts, trees, arboretums, and montreals.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-castlecrasher.png", "cost": 1.0e10,
						   "effect_type": "early_building_doubler", "effect_value": 0, 
						   "dependencies": ["scintillation"], "position": start_pos + Vector2(h_space * 1.5, -v_space * 5) },

		"kadir":         { "name": "The Kadir", "description": "A powerful symbol that resonates with your squirrels' ambition. Global SPS is permanently increased by 25%.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-kadirupgrade.png", "cost": 5.0e7,
						   "effect_type": "sps_multiplier", "effect_value": 0.25,
						   "dependencies": ["second_click"], "position": start_pos + Vector2(h_space * 2.0, -v_space * 2) },

		"dogs":          { "name": "Herding Dogs", "description": "You need dogs to herd the foxes. Unlocks the Dogs building.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-herdingdogupgrade.png", "cost": 1.0e9,
						   "effect_type": "unlock_building", "effect_value": "Dogs",
						   "dependencies": ["kadir"], "position": start_pos + Vector2(h_space * 2.0, -v_space * 3) },
						
		"cats":          { "name": "Herding Cats", "description": "The dogs are out of hand. Cats will keep them in line. Unlocks the Cats building.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-herdingcatupgrade.png", "cost": 1.0e11,
						   "effect_type": "unlock_building", "effect_value": "Cats",
						   "dependencies": ["dogs"], "position": start_pos + Vector2(h_space * 2.5, -v_space * 4) },
						   
		"futility":      { "name": "Concept of Futility", "description": "You can't herd cats. Unlocks the Futility building.",
						   "texture_path": "res://sqrlart/upgradewebart/Sprite-conceptoffutilityupgrade.png", "cost": 1.0e13,
						   "effect_type": "unlock_building", "effect_value": "Futility",
						   "dependencies": ["cats"], "position": start_pos + Vector2(h_space * 3.0, -v_space * 5) },
	}

func check_unlock_conditions():
	for building in buildings:
		if not building.unlocked:
			var condition_met = false
			match building.unlock_condition_type:
				"total_squirrels_earned":
					if total_squirrels_earned >= building.unlock_condition_value: condition_met = true
				"total_clicks":
					if total_clicks >= building.unlock_condition_value: condition_met = true
				"building_owned":
					var target_building = buildings.filter(func(b): return b.name == building.unlock_condition_target)
					if not target_building.is_empty() and target_building[0].owned >= building.unlock_condition_value:
						condition_met = true
				"item_owned":
					if owned_item_ids.has(building.unlock_condition_target): condition_met = true
				"upgrade_owned":
					if owned_upgrade_ids.has(building.unlock_condition_target): condition_met = true

			if condition_met:
				building.unlocked = true
				building_unlocked_mailbox.append(building.name)

func recalculate_sps():
	var old_sps = squirrels_per_second
	var base_sps: float = 0.0
	
	var final_sps_multiplier = sps_multiplier
	if owned_upgrade_ids.has("scintillation"):
		var meta_bonus = 0.0
		for upgrade_id in owned_upgrade_ids:
			if all_upgrades.has(upgrade_id):
				var upgrade = all_upgrades[upgrade_id]
				if upgrade.effect_type == "sps_multiplier" or upgrade.effect_type == "sps_per_building_type_and_unlock":
					meta_bonus += upgrade.effect_value * 0.05
		final_sps_multiplier += meta_bonus

	if owned_upgrade_ids.has("jokers_mask"):
		var owned_types = 0
		for building in buildings:
			if building.owned > 0:
				owned_types += 1
		final_sps_multiplier += owned_types * all_upgrades.jokers_mask.effect_value
		
	for b_idx in range(buildings.size()):
		var building = buildings[b_idx]
		var building_sps = building.sps
		
		if owned_upgrade_ids.has("knight_magic") and b_idx < 4:
			building_sps *= 2.0
			
		if owned_upgrade_ids.has("cuphead") and building.name.split(" ").size() == 2:
			building_sps *= 2.0
			
		base_sps += float(building.owned) * building_sps

	if owned_upgrade_ids.has("egg"):
		base_sps += all_upgrades.egg.effect_value
		
	if owned_upgrade_ids.has("runners_vision"):
		base_sps += all_upgrades.runners_vision.effect_value * total_clicks
	
	squirrels_per_second = base_sps * final_sps_multiplier * temporary_sps_debuff * temporary_sps_buff * gyoza_debuff_multiplier * test_debuff_multiplier
	if not is_equal_approx(old_sps, squirrels_per_second):
		sps_change_mailbox.append({"old": old_sps, "new": squirrels_per_second})

func calculate_building_cost(building_index: int) -> float:
	if building_index >= 0 and building_index < buildings.size():
		var building = buildings[building_index]
		var cost_multiplier = 1.0
		if owned_upgrade_ids.has("cuphead") and building.name.split(" ").size() == 2:
			cost_multiplier = 1.1
		
		return ceil(building.base_cost * pow(1.1, float(building.owned)) * cost_multiplier)
	return 0.0

func apply_item_effect(item_id: String):
	if not all_items.has(item_id): return
	var item_data = all_items[item_id]
	match item_id:
		"tapeworm":
			var earnings = squirrels_per_second * 10800
			squirrels += earnings
			total_squirrels_earned += earnings
			toast_mailbox.append("Gained %s squirrels!" % format_number(earnings, true))
			_apply_tapeworm_debuff()
		"Clock":
			var earnings = squirrels_per_second * 3600
			squirrels += earnings
			total_squirrels_earned += earnings
			toast_mailbox.append("Gained %s squirrels!" % format_number(earnings, true))
		"steroids": _apply_steroid_buff()
		"pill": sps_multiplier *= 2.0
		"brain": sps_multiplier += 0.10
		"mr_primal": sps_multiplier += 0.05
		"bandaid": sps_multiplier += 0.10
		"ButtsPie": _apply_pie_buff()
		"Wheat":
			var earned_from_wheat = squirrels
			squirrels *= 2
			total_squirrels_earned += earned_from_wheat
		"Fazcoin":
			fazcoin_count += 1
			if fazcoin_count >= 5: scene_change_mailbox = "res://3d squirrel.tscn"
		"HR": _fire_random_buildings(3)
		"Gyoza": _apply_gyoza_debuff()
		"The Plant": _remove_best_building()
		"Liquid Pain":
			is_in_shop = false
			death_mailbox = true
			if not owned_item_ids.has(item_id): owned_item_ids.append(item_id)
			return 
		"Loss": squirrels = 0
		"Pregnancy test": _apply_test_debuff()

	if item_data.type == "permanent" or item_data.type == "cosmetic":
		if not owned_item_ids.has(item_id): owned_item_ids.append(item_id)
	recalculate_sps()

func apply_upgrade_effect(upgrade_id: String):
	if not all_upgrades.has(upgrade_id): return
	
	var upgrade = all_upgrades[upgrade_id]
	match upgrade.effect_type:
		"click_flat":
			squirrels_per_click += upgrade.effect_value
		"click_multiplier":
			click_multiplier += upgrade.effect_value
		"sps_multiplier":
			sps_multiplier += upgrade.effect_value
		"sps_flat_and_unlock":
			for building in buildings:
				if building.name == upgrade.unlock_target:
					if not building.unlocked:
						building.unlocked = true
						building_unlocked_mailbox.append(building.name)
					break
			pass
		"sps_per_building_type_and_unlock":
			for building in buildings:
				if building.name == upgrade.unlock_target:
					if not building.unlocked:
						building.unlocked = true
						building_unlocked_mailbox.append(building.name)
					break
			pass
		"building_sps_flat":
			for building in buildings:
				if building.name == upgrade.effect_target:
					building.sps += upgrade.effect_value
					break
		"building_sps_multiplier":
			for building in buildings:
				if building.name == upgrade.effect_target:
					building.sps *= upgrade.effect_value
					break
		"unlock_building":
			for building in buildings:
				if building.name == upgrade.effect_value:
					if not building.unlocked:
						building.unlocked = true
						building_unlocked_mailbox.append(building.name)
					break
		"click_from_sps":
			pass
		"sps_per_building_type":
			pass
		"sps_per_click":
			pass
		"conditional_building_multiplier":
			pass
		"meta_multiplier":
			pass
		"early_building_doubler":
			pass
	
	recalculate_sps()
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save_game(); get_tree().quit()

func save_game():
	var file_path = "user://savegame.dat"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var buildings_to_save = []
		for b in buildings:
			buildings_to_save.append({"name": b.name, "owned": b.owned, "unlocked": b.get("unlocked", true)})

		var save_data = {
			"squirrels": squirrels, "squirrels_per_click": squirrels_per_click, "buildings": buildings_to_save,
			"save_timestamp": Time.get_unix_time_from_system(), "owned_item_ids": owned_item_ids,
			"sps_multiplier": sps_multiplier, "click_multiplier": click_multiplier,
			"fazcoin_count": fazcoin_count,
			"is_in_shop": is_in_shop, "current_shop_items": current_shop_items,
			"steroid_end_time": steroid_end_time, "tapeworm_end_time": tapeworm_end_time, "pie_end_time": pie_end_time,
			"gyoza_end_time": gyoza_end_time, "test_end_time": test_end_time,
			"total_clicks": total_clicks, "total_squirrels_earned": total_squirrels_earned,
			"owned_upgrade_ids": owned_upgrade_ids
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
				var saved_buildings = loaded_data.get("buildings", []); 
				var saved_progress = {}
				for b_saved in saved_buildings: 
					saved_progress[b_saved.name] = {"owned": b_saved.owned, "unlocked": b_saved.get("unlocked", true)}

				for b_game in buildings:
					if saved_progress.has(b_game.name):
						b_game.owned = saved_progress[b_game.name].owned
						if saved_progress[b_game.name].unlocked:
							b_game.unlocked = true
				
				squirrels = loaded_data.get("squirrels", 0.0);
				squirrels_per_click = loaded_data.get("squirrels_per_click", 0.0)
				owned_item_ids = loaded_data.get("owned_item_ids", []); 
				sps_multiplier = loaded_data.get("sps_multiplier", 1.0)
				click_multiplier = loaded_data.get("click_multiplier", 1.0)
				fazcoin_count = loaded_data.get("fazcoin_count", 0)
				is_in_shop = loaded_data.get("is_in_shop", false); current_shop_items = loaded_data.get("current_shop_items", [])
				steroid_end_time = loaded_data.get("steroid_end_time", 0); tapeworm_end_time = loaded_data.get("tapeworm_end_time", 0)
				pie_end_time = loaded_data.get("pie_end_time", 0); gyoza_end_time = loaded_data.get("gyoza_end_time", 0)
				test_end_time = loaded_data.get("test_end_time", 0); total_clicks = loaded_data.get("total_clicks", 0)
				total_squirrels_earned = loaded_data.get("total_squirrels_earned", 0.0)
				owned_upgrade_ids = loaded_data.get("owned_upgrade_ids", [])
				
				var saved_time = loaded_data.get("save_timestamp", 0)
				if saved_time > 0:
					recalculate_sps()
					var current_time = Time.get_unix_time_from_system(); offline_seconds_passed = current_time - saved_time
					offline_squirrels_earned = offline_seconds_passed * squirrels_per_second; squirrels += offline_squirrels_earned
				print("Game Loaded!")
			else: print("Error: Save file is corrupted.")
		else: print("Error reading save file: ", file_path)

func reset_game_state():
	squirrels = 0.0; squirrels_per_click = 1.0; sps_multiplier = 1.0; click_multiplier = 1.0
	offline_seconds_passed = 0; offline_squirrels_earned = 0.0
	owned_item_ids = []; fazcoin_count = 0
	temporary_sps_buff = 1.0; temporary_sps_debuff = 1.0
	is_in_shop = false; current_shop_items = []
	steroid_end_time = 0; tapeworm_end_time = 0; pie_end_time = 0
	gyoza_debuff_multiplier = 1.0; test_debuff_multiplier = 1.0
	gyoza_end_time = 0; test_end_time = 0
	total_clicks = 0; total_squirrels_earned = 0.0
	owned_upgrade_ids = []
	setup_buildings();
	recalculate_sps()
	
func get_and_clear_offline_progress() -> Dictionary:
	var progress = { "seconds": offline_seconds_passed, "squirrels": offline_squirrels_earned }
	offline_seconds_passed = 0; offline_squirrels_earned = 0.0
	return progress

func _apply_steroid_buff():
	if not is_instance_valid(steroid_timer):
		steroid_timer = Timer.new(); steroid_timer.one_shot = true
		steroid_timer.timeout.connect(_on_steroid_timer_timeout); add_child(steroid_timer)
	click_multiplier = 4.0; steroid_end_time = Time.get_unix_time_from_system() + 30.0; steroid_timer.start(30.0)

func _on_steroid_timer_timeout():
	click_multiplier = 1.0; steroid_end_time = 0

func _apply_tapeworm_debuff():
	if not is_instance_valid(tapeworm_timer):
		tapeworm_timer = Timer.new(); tapeworm_timer.one_shot = true
		tapeworm_timer.timeout.connect(_on_tapeworm_timer_timeout); add_child(tapeworm_timer)
	temporary_sps_debuff = 0.8; tapeworm_end_time = Time.get_unix_time_from_system() + 30.0; tapeworm_timer.start(30.0); recalculate_sps()

func _on_tapeworm_timer_timeout():
	temporary_sps_debuff = 1.0; tapeworm_end_time = 0; recalculate_sps()

func _apply_pie_buff():
	if not is_instance_valid(pie_timer):
		pie_timer = Timer.new(); pie_timer.one_shot = true
		pie_timer.timeout.connect(_on_pie_timer_timeout); add_child(pie_timer)
	temporary_sps_buff = 2.0; pie_end_time = Time.get_unix_time_from_system() + 600.0; pie_timer.start(600.0); recalculate_sps()

func _on_pie_timer_timeout():
	temporary_sps_buff = 1.0; pie_end_time = 0; recalculate_sps()
	
func _apply_gyoza_debuff():
	if not is_instance_valid(gyoza_timer):
		gyoza_timer = Timer.new(); gyoza_timer.one_shot = true
		gyoza_timer.timeout.connect(_on_gyoza_timer_timeout); add_child(gyoza_timer)
	gyoza_debuff_multiplier = 0.85; gyoza_end_time = Time.get_unix_time_from_system() + 900.0
	gyoza_timer.start(900.0); recalculate_sps()

func _on_gyoza_timer_timeout():
	gyoza_debuff_multiplier = 1.0; gyoza_end_time = 0; recalculate_sps()

func _apply_test_debuff():
	if not is_instance_valid(test_timer):
		test_timer = Timer.new(); test_timer.one_shot = true
		test_timer.timeout.connect(_on_test_timer_timeout); add_child(test_timer)
	test_debuff_multiplier = 0.90; test_end_time = Time.get_unix_time_from_system() + 300.0
	test_timer.start(300.0); recalculate_sps()

func _on_test_timer_timeout():
	test_debuff_multiplier = 1.0; test_end_time = 0; recalculate_sps()

func _remove_best_building():
	if buildings.is_empty(): return
	var best_building_index = -1; var highest_yield: float = -1.0
	for i in range(buildings.size()):
		var building = buildings[i]
		if building.owned > 0:
			var building_yield: float = float(building.owned) * building.sps
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
	if is_equal_approx(number, 1.0e100): return "Googol!"
	if number < 1000.0:
		if allow_decimals:
			if fmod(number, 1.0) == 0: return str(int(number))
			else: return "%.1f" % number
		else: return str(int(number))
	const SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ocvg", "Novg", "Tg", "Utg", "Dtg"]
	var magnitude = int(floor(log(number) / log(1000)))
	var abbreviated_num: float
	var suffix: String
	if magnitude < SUFFIXES.size():
		abbreviated_num = number / pow(1000, magnitude)
		suffix = SUFFIXES[magnitude]
	else:
		const LETTERS = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
		abbreviated_num = number / pow(1000, magnitude)
		var index = magnitude - SUFFIXES.size() + SUFFIXES.size() * 2
		var first_letter_index = float(floor(index / float(LETTERS.size())))
		var second_letter_index = index % LETTERS.size()
		if first_letter_index < LETTERS.size():
			suffix = LETTERS[first_letter_index] + LETTERS[second_letter_index]
		else:
			return "%.2e" % number

	var formatted_string: String
	if fmod(abbreviated_num, 1.0) == 0: formatted_string = "%d" % int(abbreviated_num)
	elif abbreviated_num < 10: formatted_string = "%.2f" % abbreviated_num
	elif abbreviated_num < 100: formatted_string = "%.1f" % abbreviated_num
	else: formatted_string = "%d" % int(abbreviated_num)
	return formatted_string + suffix

func update_spawnable_items():
	if all_items.has("Fazcoin"):
		if fazcoin_count < 5: all_items.Fazcoin.is_spawnable = true
		else: all_items.Fazcoin.is_spawnable = false
