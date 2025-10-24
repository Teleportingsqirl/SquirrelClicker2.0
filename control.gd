# Control.gd
extends Control

# In Control.gd
@onready var label = $"sqirl base/clicksqrltext"
@onready var sps_label: Label = $SPSLabel
@onready var texture_button = $"sqirl base/sqrlcontainer/sqrlbutton"
@onready var building_price_label = $"sqirl buildings/building price"
@onready var building_ad_button = $"sqirl buildings/buildingads"
@onready var building_ad_texture = $"sqirl buildings/buildingads"
@onready var next_button = $"sqirl buildings/nextpagebuildings"
@onready var prev_button = $"sqirl buildings/lastpagebuildings"
@onready var toast_popup = $ToastPopup
@onready var toast_label = $ToastPopup/ToastLabel
@onready var toast_timer = $ToastTimer



var current_building_index = 0


var idle_float_tween: Tween
var idle_wobble_tween: Tween
var click_tween: Tween


func _ready():
	texture_button.pivot_offset = texture_button.size / 2
	create_idle_animation()

	next_button.pressed.connect(_on_next_building_pressed)
	prev_button.pressed.connect(_on_prev_building_pressed)
	building_ad_button.pressed.connect(_on_purchase_building_pressed)

	
	update_text()
	update_sps_display() 
	update_building_display()
	

	show_offline_progress_toast() 


func _process(_delta):
	update_text()


func _on_texture_button_pressed():
	GameState.squirrels += GameState.squirrels_per_click
	create_click_animation()

func _on_next_building_pressed():
	current_building_index = (current_building_index + 1) % GameState.buildings.size()
	update_building_display()

func _on_prev_building_pressed():
	current_building_index = (current_building_index - 1 + GameState.buildings.size()) % GameState.buildings.size()
	update_building_display()

func _on_purchase_building_pressed():
	var cost = GameState.calculate_building_cost(current_building_index)

	if GameState.squirrels >= cost:
		GameState.squirrels -= cost
		GameState.buildings[current_building_index].owned += 1
		GameState.recalculate_sps()
		
		update_building_display()
		update_sps_display() 

func update_text():
	label.text = "Squirrels: " + format_number(int(GameState.squirrels))

func update_sps_display():
	sps_label.text = "SPS: " + format_number(GameState.squirrels_per_second)

func update_building_display():
	var current_building = GameState.buildings[current_building_index]
	var cost = GameState.calculate_building_cost(current_building_index)
	building_price_label.text = "Cost: " + format_number(cost)
	var new_texture = load(current_building.texture_path)
	building_ad_texture.texture_normal = new_texture


func show_offline_progress_toast():
	var progress = GameState.get_and_clear_offline_progress()
	
	if progress.seconds > 1 and progress.squirrels > 0.1:
		var time_text = format_seconds_to_string(progress.seconds)
		var squirrels_text = format_number(progress.squirrels)
		
		toast_label.text = "While you were away for %s \n you earned %s squirrels!" % [time_text, squirrels_text]
		toast_popup.visible = true
		toast_timer.start()

func _on_toast_timer_timeout():
	toast_popup.visible = false


func format_seconds_to_string(total_seconds: int) -> String:
	if total_seconds < 60:
		return "%d seconds" % [total_seconds]
	elif total_seconds < 3600:
		var minutes = total_seconds / 60
		return "%d minutes" % [minutes]
	elif total_seconds < 86400:
		var hours = total_seconds / 3600
		return "%d hours" % [hours]
	else:
		var days = total_seconds / 86400
		return "%d days" % [days]

# (Your existing helper functions below)
func _on_3d_button_pressed(): get_tree().change_scene_to_file("res://3d squirrel.tscn")
func create_idle_animation():
	if idle_float_tween and idle_float_tween.is_valid(): idle_float_tween.kill()
	if idle_wobble_tween and idle_wobble_tween.is_valid(): idle_wobble_tween.kill()
	idle_float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y + 15.0, 1.6)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y - 5.0, 1.4)
	idle_wobble_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", 8.0, 2.0)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", -8.0, 2.0)
func create_click_animation():
	if click_tween and click_tween.is_valid(): click_tween.kill()
	var original_scale = Vector2(1, 1); var pop_scale = Vector2(1.15, 1.15)
	click_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(texture_button, "scale", pop_scale, 0.08)
	click_tween.tween_property(texture_button, "scale", original_scale, 0.12)
func format_number(number: float) -> String:
	if number < 10000.0: return str(int(number))
	const SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var magnitude = int(floor(log(number) / log(1000)))
	var divisor = pow(1000, magnitude)
	var abbreviated_num = number / divisor
	var suffix = SUFFIXES[magnitude]
	var formatted_string: String
	if abbreviated_num < 10: formatted_string = "%.2f" % abbreviated_num
	elif abbreviated_num < 100: formatted_string = "%.1f" % abbreviated_num
	else: formatted_string = "%d" % abbreviated_num
	return formatted_string + suffix
