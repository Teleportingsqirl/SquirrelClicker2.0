extends Control

@onready var mainbuttons: VBoxContainer = $mainbuttons
@onready var options: Panel = $options



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mainbuttons.visible = true
	options.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")


func _on_options_pressed() -> void:
	print("Options Pressed")
	mainbuttons.visible = false
	options.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	mainbuttons.visible = true
	options.visible = false
