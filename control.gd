# Control.gd (Final Mailbox Version)
extends Control

# --- Node References ---
@onready var label = $"sqirl base/clicksqrltext"
@onready var sps_label: Label = $SPSLabel
@onready var sps_change_label: Label = $SpsChangeLabel
@onready var texture_button = $"sqirl base/sqrlcontainer/sqrlbutton"
@onready var building_price_label = $"sqirl buildings/building price"
@onready var building_ad_button = $"sqirl buildings/buildingads"
@onready var building_ad_texture = $"sqirl buildings/buildingads"
@onready var next_button = $"sqirl buildings/nextpagebuildings"
@onready var prev_button = $"sqirl buildings/lastpagebuildings"
@onready var toast_popup = $ToastPopup
@onready var toast_label = $ToastPopup/ToastLabel
@onready var toast_timer = $ToastTimer
# ... (and any other @onready vars like 3DButton, etc.)

var current_building_index = 0
var idle_float_tween: Tween
var idle_wobble_tween: Tween
var click_tween: Tween

func _ready():
	# We don't need any signal connections here for the mailbox method.
	
	texture_button.pivot_offset = texture_button.size / 2
	create_idle_animation()

	next_button.pressed.connect(_on_next_building_pressed)
	prev_button.pressed.connect(_on_prev_building_pressed)
	building_ad_button.pressed.connect(_on_purchase_building_pressed)
	
	# Initial UI updates are still important.
	update_text()
	update_sps_display() 
	update_building_display()
	show_offline_progress_toast() 

func _process(_delta):
	# --- MAILBOX CHECKING LOGIC ---
	# Check for new toast messages every frame.
	if not GameState.toast_mailbox.is_empty():
		var message = GameState.toast_mailbox.pop_front() # Get and remove the oldest message
		_show_toast(message)

	# Check for new SPS changes every frame.
	if not GameState.sps_change_mailbox.is_empty():
		var change_data = GameState.sps_change_mailbox.pop_front() # Get and remove the oldest change
		_handle_sps_change(change_data.old, change_data.new)

	# --- Regular UI updates ---
	update_text()
	update_sps_display()

# This function creates the animated SPS change text.
func _handle_sps_change(old_sps, new_sps):
	var diff = new_sps - old_sps
	if abs(diff) < 0.01: return # Ignore tiny floating point changes
		
	var change_text = "+%.1f SPS" % diff if diff >= 0 else "%.1f SPS" % diff
	sps_change_label.text = change_text
	
	sps_change_label.modulate = Color.GREEN if diff > 0 else Color.RED
	
	var start_pos_y = sps_change_label.position.y
	
	var tween = create_tween()
	sps_change_label.modulate.a = 1.0 # Instantly appear
	tween.tween_property(sps_change_label, "position:y", start_pos_y - 20, 2.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sps_change_label, "modulate:a", 0.0, 2.5) # Fade out while moving
	
	await tween.finished
	sps_change_label.position.y = start_pos_y # Reset position for next time

# --- Toast Logic ---

func _show_toast(message: String):
	toast_label.text = message
	toast_popup.visible = true
	toast_timer.start()

func show_offline_progress_toast():
	var progress = GameState.get_and_clear_offline_progress()
	if progress.seconds > 1 and progress.squirrels > 0.1:
		var time_text = format_seconds_to_string(progress.seconds)
		var squirrels_text = format_number(progress.squirrels, true)
		var message = "While you were away for %s \n you earned %s squirrels!" % [time_text, squirrels_text]
		_show_toast(message)

func _on_toast_timer_timeout():
	toast_popup.visible = false

# --- The rest of your script ---

func _on_texture_button_pressed():
	GameState.squirrels += GameState.squirrels_per_click * GameState.click_multiplier
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

func update_text():
	label.text = "Squirrels: " + format_number(GameState.squirrels)

func update_sps_display():
	sps_label.text = "SPS: " + format_number(GameState.squirrels_per_second, true)

func update_building_display():
	var current_building = GameState.buildings[current_building_index]
	var cost = GameState.calculate_building_cost(current_building_index)
	building_price_label.text = "Cost: " + format_number(cost)
	var new_texture = load(current_building.texture_path)
	building_ad_texture.texture_normal = new_texture

func format_seconds_to_string(total_seconds: int) -> String:
	if total_seconds < 60: return "%d seconds" % [total_seconds]
	elif total_seconds < 3600: return "%d minutes" % [int(total_seconds / 60.0)]
	elif total_seconds < 86400: return "%d hours" % [int(total_seconds / 3600.0)]
	else: return "%d days" % [int(total_seconds / 86400.0)]

func _on_3d_button_pressed(): get_tree().change_scene_to_file("res://3d squirrel.tscn")
func _on_upgrade_button_pressed(): get_tree().change_scene_to_file("res://upgrade_web.tscn")
func _on_sqirlparts_button_pressed(): get_tree().change_scene_to_file("res://sqirlparts.tscn")
	
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

func format_number(number: float, allow_decimals: bool = false) -> String:
	if number < 1000.0:
		if allow_decimals:
			if fmod(number, 1.0) == 0: return str(int(number))
			else: return "%.1f" % number
		else: return str(int(number))
	const SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var magnitude = int(floor(log(number) / log(1000)))
	if magnitude >= SUFFIXES.size(): magnitude = SUFFIXES.size() - 1
	var divisor = pow(1000, magnitude)
	var abbreviated_num = number / divisor
	var suffix = SUFFIXES[magnitude]
	var formatted_string: String
	if fmod(abbreviated_num, 1.0) == 0: formatted_string = "%d" % int(abbreviated_num)
	elif abbreviated_num < 10: formatted_string = "%.2f" % abbreviated_num
	elif abbreviated_num < 100: formatted_string = "%.1f" % abbreviated_num
	else: formatted_string = "%d" % int(abbreviated_num)
	return formatted_string + suffix
