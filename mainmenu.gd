extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var options: Panel = $options

@onready var start_button = $mainbuttons/start
@onready var animated_cursor = $AnimatedCursor
@onready var reset_button = $"mainbuttons/reset save"

var confirm_reset = false


func _ready() -> void:
	mainbuttons.visible = true
	options.visible = false



func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	start_button.disabled = true
	await animated_cursor.animation_finished
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")


func _on_options_pressed() -> void:
	mainbuttons.visible = false
	options.visible = true
	

func _on_reset_pressed() -> void:
	if confirm_reset == true:
		var file_path = "user://savegame.dat"
		var dir = DirAccess.open("user://")
		if dir.file_exists("savegame.dat"):
			DirAccess.remove_absolute(file_path)
			print("Save file deleted.")
			reset_button.text = "Save Reset!"
			reset_button.release_focus()
		else:
			print("No save file to delete.")
			reset_button.text = "No Save Found"
			confirm_reset = false
			reset_button.release_focus()

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
	$"mainbuttons/reset save".text = "reset save"
	
