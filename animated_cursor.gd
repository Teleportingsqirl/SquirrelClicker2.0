# animated_cursor.gd
extends AnimatedSprite2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	play("idle")
	animation_finished.connect(_on_animation_finished)

func _process(_delta):
	if not is_inside_tree():
		return
	global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		if event.is_pressed():
			play("clickDown")
			
		# If the button was just RELEASED
		else:
			# Play the "click_up" animation once.
			play("clickUp")

# This function is called automatically when any non-looping animation finishes.
func _on_animation_finished():
	# If the animation that just finished was our "click_up" animation...
	if animation == "clickUp":
		# ...then it's time to go back to the idle state.
		play("idle")
