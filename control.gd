extends Control
var count: float = 0.0
@onready var label = $"sqirl base/clicksqrltext" 
@onready var texture_button = $"sqirl base/sqrlcontainer/sqrlbutton"

var idle_float_tween: Tween
var idle_wobble_tween: Tween
var click_tween: Tween

@onready var building_price_label = $"sqirl buildings/building price"
@onready var building_ad_button = $"sqirl buildings/buildingads"
@onready var building_ad_texture = $"sqirl buildings/buildingads"
@onready var next_button = $"sqirl buildings/nextpagebuildings"
@onready var prev_button = $"sqirl buildings/lastpagebuildings"


var buildings = []
var current_building_index = 0
var squirrels_per_second: float = 0.0

func _ready():
	texture_button.pivot_offset = texture_button.size / 2
	create_idle_animation()
	
	setup_buildings()
	
	next_button.pressed.connect(_on_next_building_pressed)
	prev_button.pressed.connect(_on_prev_building_pressed)
	building_ad_button.pressed.connect(_on_purchase_building_pressed)
	
	update_text()
	update_building_display()

func _process(delta):
	if squirrels_per_second > 0:
		count += squirrels_per_second * delta
		update_text()


func _on_texture_button_pressed():
	count += 1
	update_text()
	create_click_animation()

func update_text():
	label.text = "Squirrels: " + str(int(count))

func create_idle_animation():
	if idle_float_tween and idle_float_tween.is_valid():
		idle_float_tween.kill()
	if idle_wobble_tween and idle_wobble_tween.is_valid():
		idle_wobble_tween.kill()

	idle_float_tween = create_tween().set_loops()
	idle_float_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y + 15.0, 1.6)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y - 5.0, 1.4)

	idle_wobble_tween = create_tween().set_loops()
	idle_wobble_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", 8.0, 2.0)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", -8.0, 2.0)

func create_click_animation():
	if click_tween and click_tween.is_valid():
		click_tween.kill()
	
	var original_scale = Vector2(1, 1)
	var pop_scale = Vector2(1.15, 1.15)
	
	click_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(texture_button, "scale", pop_scale, 0.08)
	click_tween.tween_property(texture_button, "scale", original_scale, 0.12)

func setup_buildings():
	buildings = [
		# format is  name : nuts, base_cost, sps, owned, texturepath
		{"name": "Nuts", "base_cost": 10, "sps": 0.1, "owned": 0, "texture_path": "res://sqrlart/Sprite-sqrladdnuts.png"},
		{"name": "Trees", "base_cost": 100, "sps": 1, "owned": 0, "texture_path": "res://sqrlart/Sprite-adfortree.png"},
		{"name": "Arboretums", "base_cost": 1000, "sps": 10, "owned": 0, "texture_path": "res://path/to/arboretums_image.png"}
	]

func update_building_display():
	var current_building = buildings[current_building_index]
	var cost = calculate_cost(current_building)
	
	building_price_label.text = "Cost: " + str(cost)
	var new_texture = load(current_building.texture_path)
	building_ad_texture.texture_normal = new_texture

func calculate_cost(building):
	return int(ceil(building.base_cost * pow(1.1, building.owned)))

func recalculate_sps():
	squirrels_per_second = 0.0
	for building in buildings:
		squirrels_per_second += building.owned * building.sps


func _on_next_building_pressed():
	current_building_index = (current_building_index + 1) % buildings.size()
	update_building_display()

func _on_prev_building_pressed():
	current_building_index = (current_building_index - 1 + buildings.size()) % buildings.size()
	update_building_display()

func _on_purchase_building_pressed():
	var building = buildings[current_building_index]
	var cost = calculate_cost(building)
	
	if count >= cost:
		count -= cost
		building.owned += 1
		
		recalculate_sps()
		update_text()
		update_building_display()
