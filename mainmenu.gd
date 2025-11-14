#mainmenu.gd
extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var options: Panel = $options

var mainbuttons_onscreen_pos: Vector2
var mainbuttons_offscreen_pos: Vector2
var options_onscreen_pos: Vector2
var options_offscreen_pos: Vector2

var is_options_open = false
var confirm_reset = false

@onready var start_button = $mainbuttons/start
@onready var options_button = $mainbuttons/options
@onready var reset_button = $"mainbuttons/reset save"
@onready var animated_cursor = $AnimatedCursor
@onready var fullscreen_btn = $options/MarginContainer/VBoxContainer/FullscreenBtn
@onready var antialias_btn = $options/MarginContainer/VBoxContainer/AntialiasBtn
@onready var volume_slider = $options/MarginContainer/VBoxContainer/HSlider
@onready var language_btn = $options/MarginContainer/VBoxContainer/LanguageBtn
@onready var resolution_btn: OptionButton = $options/MarginContainer/VBoxContainer/ResolutionBtn

var available_resolutions: Array[Vector2i] = []
const MIN_DB = -40.0
const MAX_DB = 0.0

func _value_to_db(value: float) -> float:
	if value < 0.001:
		return -80.0
	return lerp(MIN_DB, MAX_DB, value)
	
func _db_to_value(db: float) -> float:
	if db < MIN_DB:
		return 0.0
	return remap(db, MIN_DB, MAX_DB, 0.0, 1.0)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().quit()

func _ready() -> void:
	mainbuttons_onscreen_pos = mainbuttons.position; options_onscreen_pos = options.position
	mainbuttons_offscreen_pos = mainbuttons_onscreen_pos - Vector2(0, 400)
	options_offscreen_pos = options_onscreen_pos + Vector2(options.size.x, 0)
	options.position = options_offscreen_pos; mainbuttons.position = mainbuttons_offscreen_pos
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(mainbuttons, "position", mainbuttons_onscreen_pos, 0.6)
	language_btn.clear(); language_btn.add_item("English (CA)"); language_btn.add_item("Français")
	
	_populate_resolutions()
	
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	antialias_btn.toggled.connect(_on_antialias_toggled)
	volume_slider.value_changed.connect(_on_volume_value_changed)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
	language_btn.item_selected.connect(_on_language_selected)
	resolution_btn.item_selected.connect(_on_resolution_selected)

func _populate_resolutions():
	resolution_btn.clear()
	available_resolutions.clear()

	var standard_resolutions = [
		Vector2i(1280, 720),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
	]

	var native_res = DisplayServer.screen_get_size()
	
	if not standard_resolutions.has(native_res):
		standard_resolutions.append(native_res)
	
	for res in standard_resolutions:
		if res.x <= native_res.x and res.y <= native_res.y:
			available_resolutions.append(res)
	available_resolutions.sort()

	var current_res_index = -1
	for i in range(available_resolutions.size()):
		var res = available_resolutions[i]
		var text = "%d x %d" % [res.x, res.y]
		resolution_btn.add_item(text, i)
		if res == GameState.window_resolution:
			current_res_index = i
			
	if current_res_index == -1 and GameState.window_resolution != Vector2i.ZERO:
		available_resolutions.append(GameState.window_resolution)
		var custom_res_text = "%d x %d (Custom)" % [GameState.window_resolution.x, GameState.window_resolution.y]
		resolution_btn.add_item(custom_res_text, available_resolutions.size() - 1)
		current_res_index = available_resolutions.size() - 1

	if current_res_index != -1:
		resolution_btn.select(current_res_index)

func _on_options_pressed() -> void:
	is_options_open = not is_options_open
	var tween = create_tween()
	if is_options_open:
		fullscreen_btn.set_pressed_no_signal(GameState.is_fullscreen)
		antialias_btn.set_pressed_no_signal(GameState.use_antialiasing)
		volume_slider.set_value_no_signal(_db_to_value(GameState.music_volume_db))
		
		resolution_btn.disabled = GameState.is_fullscreen

		var current_selected_index = -1
		for i in range(available_resolutions.size()):
			if available_resolutions[i] == GameState.window_resolution:
				current_selected_index = i
				break
		if current_selected_index != -1:
			resolution_btn.select(current_selected_index)
		
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(options, "position", options_onscreen_pos, 0.5)
	else:
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(options, "position", options_offscreen_pos, 0.5)
	options_button.release_focus()

func _on_back_pressed() -> void:
	if is_options_open: _on_options_pressed()
	confirm_reset = false; reset_button.text = "RESET SAVE"

func _on_fullscreen_toggled(toggled_on): 
	GameState.is_fullscreen = toggled_on
	resolution_btn.disabled = toggled_on
	GameState.apply_settings()
	GameState.save_settings()

func _on_antialias_toggled(toggled_on): GameState.use_antialiasing = toggled_on; GameState.apply_settings(); GameState.save_settings()

func _on_volume_value_changed(value): 
	GameState.music_volume_db = _value_to_db(value)
	GameState.apply_settings()
	
func _on_volume_drag_ended(value_changed):
	if value_changed: GameState.save_settings()
	
func _on_language_selected(index):
	if index == 1: get_tree().quit()

func _on_resolution_selected(index: int):
	if index >= 0 and index < available_resolutions.size():
		var selected_res = available_resolutions[index]
		if selected_res != GameState.window_resolution:
			GameState.window_resolution = selected_res
			GameState.apply_settings()
			GameState.save_settings()

func _on_start_pressed() -> void:
	start_button.disabled = true
	if GameState.is_in_shop:
		SceneTransitioner.transition_to_scene("res://sqirlparts.tscn", SceneTransitioner.TransitionMode.SLIDE_LEFT)
	else:
		SceneTransitioner.transition_to_scene("res://squirrelclicker.tscn", SceneTransitioner.TransitionMode.SLIDE_LEFT)

func _on_reset_pressed() -> void:
	if confirm_reset == true:
		if FileAccess.file_exists("user://savegame.dat"):
			DirAccess.remove_absolute("user://savegame.dat")
			reset_button.text = "Save Reset!"; GameState.reset_game_state()
		else: reset_button.text = "No Save Found"
		confirm_reset = false
	else: reset_button.text = "Are you sure?"; confirm_reset = true
	reset_button.release_focus()

func _on_exit_pressed() -> void: get_tree().quit()
