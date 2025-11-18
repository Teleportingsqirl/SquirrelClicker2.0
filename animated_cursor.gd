# animated_cursor.gd
# this file simply displays an animated sprite on top of the mouse, with a click animation for when you click, and sfx.
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

		else:
			play("clickUp")


func _on_animation_finished():
	if animation == "clickUp":
		play("idle")
