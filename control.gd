extends Control

var count = 0
# IMPORTANT: Update these paths to match your new scene tree!
@onready var label = $clicksqrltext
@onready var texture_button = $sqrlcontainer/sqrlbutton

func _ready():
	# Set the button's pivot to its center at the start of the game.
	# Doing it here is more stable than doing it during the click animation.
	texture_button.pivot_offset = texture_button.size / 2
	update_text()

func _on_texture_button_pressed():
	count += 1
	update_text()
	create_click_animation()

func update_text():
	# Now we just set the text directly, no BBCode needed.
	label.text = "Squirrel Clicked:\n" + str(count)

func create_click_animation():
	var original_scale = Vector2(1, 1)
	var pop_scale = Vector2(1.15, 1.15)
	
	# The tween animates the button's scale property for a "pop" effect.
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# Animate the scale up to pop_scale
	tween.tween_property(texture_button, "scale", pop_scale, 0.06)
	# Animate the scale back down to the original size
	tween.tween_property(texture_button, "scale", original_scale, 0.1)
