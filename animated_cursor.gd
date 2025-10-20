# animated_cursor.gd
extends AnimatedSprite2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	play("idle")
	animation_finished.connect(_on_animation_finished)

func _process(delta):
	# ADD THIS CHECK: Prevents a crash when the scene is changing
	if not is_inside_tree():
		return
	
	global_position = get_global_mouse_position()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			play("click")

func _on_animation_finished():
	if animation == "click":
		play("idle")
