extends AnimatedSprite2D

func _ready():
	# This function runs once when the cursor is created.
	
	# 1. Hide the computer's default mouse cursor.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# 2. Play the "idle" animation by default.
	play("idle")
	
	# 3. Connect a signal that tells us when a non-looping animation is finished.
	# We need this to know when to switch back to idle after a click.
	animation_finished.connect(_on_animation_finished)


func _process(_delta):
	# This function runs on every single frame.
	
	# Make this animated sprite's position follow the actual mouse position.
	global_position = get_global_mouse_position()


func _input(event):
	# This function runs whenever any input happens (mouse click, key press, etc.).
	
	# Check if the input was a mouse button event and if it was the left button.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		# Check if the button was just pressed down.
		if event.is_pressed():
			# If it was, play our one-shot "click" animation.
			play("click")


func _on_animation_finished():
	# This function is called automatically when the "click" animation is done.
	
	# CORRECTED LINE: Check the 'animation' property instead of 'animation_name'.
	if animation == "click":
		# Switch back to the "idle" animation.
		play("idle")
