# animated_cursor.gd
extends AnimatedSprite2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Start in the idle state
	play("idle")
	# Connect the signal so we know when an animation is done
	animation_finished.connect(_on_animation_finished)

func _process(delta):
	# This part is perfect, keep it as is
	global_position = get_global_mouse_position()

func _input(event):
	# We only care about the left mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		# If the button was just PRESSED
		if event.is_pressed():
			# Play the "click_down" animation once.
			play("click_down")
			
		# If the button was just RELEASED
		else:
			# Play the "click_up" animation once.
			play("click_up")

# This function is called automatically when any non-looping animation finishes.
func _on_animation_finished():
	# If the animation that just finished was our "click_up" animation...
	if animation == "click_up":
		# ...then it's time to go back to the idle state.
		play("idle")
