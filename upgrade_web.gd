# UpgradeWeb.gd
extends Node2D

@export var zoom_level = 1.2
var min_clamp = Vector2.ZERO
var max_clamp = Vector2.ZERO

var is_dragging = false
var drag_start_position = Vector2.ZERO
var drag_start_node_position = Vector2.ZERO

@onready var back_button = %backButton

func _ready():
	self.scale = Vector2(zoom_level, zoom_level)


	var viewport_size = get_viewport_rect().size

	var background_texture = $Background.texture
	if not background_texture: return
	
	var scaled_size = background_texture.get_size() * self.scale

	min_clamp.x = min(0, viewport_size.x - scaled_size.x)
	min_clamp.y = min(0, viewport_size.y - scaled_size.y)
	max_clamp.x = 0
	max_clamp.y = 0
	back_button.text = "Back"
	back_button.pressed.connect(_on_back_button_pressed)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		is_dragging = true
		drag_start_position = get_global_mouse_position()
		drag_start_node_position = self.position

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		is_dragging = false

	if event is InputEventMouseMotion:
		if is_dragging:
			var mouse_delta = get_global_mouse_position() - drag_start_position
			
			self.position = (drag_start_node_position + mouse_delta).clamp(min_clamp, max_clamp)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")
