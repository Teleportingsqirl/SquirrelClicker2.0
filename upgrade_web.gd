# UpgradeWeb.gd
extends Node2D

@export var zoom_level = 1.4
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
	if not background_texture: return # Safety check
	
	var scaled_size = background_texture.get_size() * self.scale

	min_clamp.x = min(0, viewport_size.x - scaled_size.x)
	min_clamp.y = min(0, viewport_size.y - scaled_size.y)
	max_clamp.x = 0
	max_clamp.y = 0
	back_button.text = "Back"
	back_button.pressed.connect(_on_back_button_pressed)

# This function is called for every input event (mouse, keyboard, etc.)
func _input(event):
	# Event 1: The user presses the left mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		is_dragging = true
		# Record where the mouse was when the drag started
		drag_start_position = get_global_mouse_position()
		# Record where the node was when the drag started
		drag_start_node_position = self.position

	# Event 2: The user releases the left mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		is_dragging = false

	# Event 3: The mouse moves
	if event is InputEventMouseMotion:
		# Only do this if we are currently in a drag operation
		if is_dragging:
			# Calculate the difference between the current mouse position
			# and where the drag started.
			var mouse_delta = get_global_mouse_position() - drag_start_position
			
			# Set this node's position to be its original position plus the mouse movement
			self.position = (drag_start_node_position + mouse_delta).clamp(min_clamp, max_clamp)

# This function is called when the BackButton is pressed
func _on_back_button_pressed():
	# Change this to the path of your main squirrel clicker scene
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")
