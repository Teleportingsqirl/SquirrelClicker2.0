extends Control

var count = 0
@onready var label = $clicksqrltext
@onready var texture_button = $sqrlcontainer/sqrlbutton

# Storing tween references for management
var idle_float_tween: Tween
var idle_wobble_tween: Tween
var click_tween: Tween

func _ready():
	texture_button.pivot_offset = texture_button.size / 2
	update_text()
	create_idle_animation()

func _on_texture_button_pressed():
	count += 1
	update_text()
	create_click_animation()

func update_text():
	label.text = "Squirrel Clicked:\n" + str(count)

# This is the lively idle animation you liked. It remains unchanged.
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


# --- REVISED: The Pop animation no longer stops the idle animation ---
func create_click_animation():
	# If a previous POP animation is still running, we'll stop it to start a new one.
	if click_tween and click_tween.is_valid():
		click_tween.kill()
		
	# --- CHANGE 1: The lines that killed the idle tweens have been REMOVED ---
	# This allows the pop to play on top of the continuous idle motion.
	
	# --- CHANGE 2: The pop effect is now less extreme ---
	var original_scale = Vector2(1, 1)
	var pop_scale = Vector2(1.15, 1.15) # Changed from 1.2 to 1.15 for a subtler effect
	
	# Create the simple pop animation
	click_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	click_tween.tween_property(texture_button, "scale", pop_scale, 0.08)
	click_tween.tween_property(texture_button, "scale", original_scale, 0.12)

	# --- CHANGE 3: The line that restarted the idle animation is REMOVED ---
	# Since we never stop the idle animation, we don't need to restart it.
