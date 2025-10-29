extends Control

# --- Container References ---
@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var options: Panel = $options

# --- Animation Position Variables ---
var mainbuttons_onscreen_pos: Vector2
var mainbuttons_offscreen_pos: Vector2
var options_onscreen_pos: Vector2
var options_offscreen_pos: Vector2

# --- State Tracking ---
var is_options_open = false
var confirm_reset = false

# --- UI Element References ---
@onready var start_button = $mainbuttons/start
@onready var options_button = $mainbuttons/options
@onready var reset_button = $"mainbuttons/reset save"
@onready var animated_cursor = $AnimatedCursor
@onready var fullscreen_btn = $options/MarginContainer/VBoxContainer/FullscreenBtn
@onready var antialias_btn = $options/MarginContainer/VBoxContainer/AntialiasBtn
@onready var volume_slider = $options/MarginContainer/VBoxContainer/HSlider
@onready var language_btn = $options/MarginContainer/VBoxContainer/LanguageBtn

func _ready() -> void:
	# --- 1. Calculate Positions for Animation (Corrected Logic) ---
	mainbuttons_onscreen_pos = mainbuttons.position
	options_onscreen_pos = options.position # Capture editor position
	mainbuttons_offscreen_pos = mainbuttons_onscreen_pos - Vector2(0, 400)
	options_offscreen_pos = options_onscreen_pos + Vector2(options.size.x, 0) # Move off-screen by its own width

	# --- 2. Initial State & Startup Animation ---
	options.position = options_offscreen_pos
	mainbuttons.position = mainbuttons_offscreen_pos
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(mainbuttons, "position", mainbuttons_onscreen_pos, 0.6)
	
	# --- 3. Setup Settings UI ---
	language_btn.clear(); language_btn.add_item("English (CA)"); language_btn.add_item("Français")
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	antialias_btn.toggled.connect(_on_antialias_toggled)
	volume_slider.value_changed.connect(_on_volume_value_changed)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
	language_btn.item_selected.connect(_on_language_selected)

func _on_options_pressed() -> void:
	is_options_open = not is_options_open
	var tween = create_tween()
	
	if is_options_open:
		fullscreen_btn.set_pressed_no_signal(GameState.is_fullscreen)
		antialias_btn.set_pressed_no_signal(GameState.use_antialiasing)
		volume_slider.set_value_no_signal(db_to_linear(GameState.volume_db))
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(options, "position", options_onscreen_pos, 0.5)
	else:
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(options, "position", options_offscreen_pos, 0.5)
	
	# FIX: Release focus to fix "stuck" button look
	options_button.release_focus()

func _on_back_pressed() -> void:
	if is_options_open:
		_on_options_pressed()
	
	confirm_reset = false
	reset_button.text = "RESET SAVE"

# --- (The rest of your script is unchanged and correct) ---

func _on_fullscreen_toggled(toggled_on):
	GameState.is_fullscreen = toggled_on; GameState.apply_settings(); GameState.save_settings()

func _on_antialias_toggled(toggled_on):
	GameState.use_antialiasing = toggled_on; GameState.apply_settings(); GameState.save_settings()

func _on_volume_value_changed(value):
	GameState.volume_db = linear_to_db(value); GameState.apply_settings()

func _on_volume_drag_ended(value_changed):
	if value_changed: GameState.save_settings()

func _on_language_selected(index):
	if index == 1: get_tree().quit()

func _on_start_pressed() -> void:
	start_button.disabled = true
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")

func _on_reset_pressed() -> void:
	if confirm_reset == true:
		if FileAccess.file_exists("user://savegame.dat"):
			DirAccess.remove_absolute("user://savegame.dat")
			reset_button.text = "Save Reset!"; GameState.reset_game_state()
		else:
			reset_button.text = "No Save Found"
		confirm_reset = false
	else:
		reset_button.text = "Are you sure?"; confirm_reset = true
	
	reset_button.release_focus()

func _on_exit_pressed() -> void:
	get_tree().quit()
