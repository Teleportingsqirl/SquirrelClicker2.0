extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var options: Panel = $options

@onready var start_button = $mainbuttons/start
@onready var animated_cursor = $AnimatedCursor
@onready var reset_button = $"mainbuttons/reset save"

@onready var fullscreen_btn = $options/MarginContainer/VBoxContainer/FullscreenBtn
@onready var antialias_btn = $options/MarginContainer/VBoxContainer/AntialiasBtn
@onready var volume_slider = $options/MarginContainer/VBoxContainer/HSlider
@onready var language_btn = $options/MarginContainer/VBoxContainer/LanguageBtn

var confirm_reset = false

func _ready() -> void:
	mainbuttons.visible = true
	options.visible = false
	

	language_btn.clear()
	language_btn.add_item("English (CA)")
	language_btn.add_item("Français")
	
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	antialias_btn.toggled.connect(_on_antialias_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	language_btn.item_selected.connect(_on_language_selected)

func _on_options_pressed() -> void:
	fullscreen_btn.set_pressed_no_signal(GameState.is_fullscreen)
	antialias_btn.set_pressed_no_signal(GameState.use_antialiasing)
	volume_slider.value = db_to_linear(GameState.volume_db)
	
	GameState.apply_settings()
	mainbuttons.visible = false
	options.visible = true


func _on_fullscreen_toggled(toggled_on):
	GameState.is_fullscreen = toggled_on
	GameState.apply_settings()
	GameState.save_settings()

func _on_antialias_toggled(toggled_on):
	GameState.use_antialiasing = toggled_on
	GameState.apply_settings()
	GameState.save_settings()

func _on_volume_changed(value):
	GameState.volume_db = linear_to_db(value)
	GameState.apply_settings()
	GameState.save_settings()

func _on_language_selected(index):
	if index == 1:
		get_tree().quit()
		
func _on_start_pressed() -> void:
	start_button.disabled = true
	await animated_cursor.animation_finished
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")

func _on_reset_pressed() -> void:
	if confirm_reset == true:
		var file_path = "user://savegame.dat"
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)
			print("Save file deleted.")
			reset_button.text = "Save Reset!"
			GameState.reset_game_state()
		else:
			reset_button.text = "No Save Found"
			confirm_reset = false
	else:
		reset_button.text = "Are you sure?"
		confirm_reset = true
	
	reset_button.release_focus()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	mainbuttons.visible = true
	options.visible = false
	confirm_reset = false
	reset_button.text = "RESET SAVE"
