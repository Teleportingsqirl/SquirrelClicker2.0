# UpgradeWeb.gd
extends Node2D

# We need to keep track of a few things while dragging.
var is_dragging = false
var drag_start_position = Vector2.ZERO
var drag_start_node_position = Vector2.ZERO

@onready var back_button = %backButton

func _ready():
	# Configure the back button when the scene starts
	back_button.text = "Back"
	# Connect the button's "pressed" signal to our function
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
			self.position = drag_start_node_position + mouse_delta

# This function is called when the BackButton is pressed
func _on_back_button_pressed():
	# Change this to the path of your main squirrel clicker scene
	get_tree().change_scene_to_file("res://squirrelclicker.tscn")
