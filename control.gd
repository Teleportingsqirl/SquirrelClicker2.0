extends Control

var count = 0
@onready var label = $clicksqrltext
@onready var texture_button = $sqrlcontainer/sqrlbutton
@onready var upgrade_text: Label = $"upgrade text"


var idle_float_tween: Tween
var idle_wobble_tween: Tween
var click_tween: Tween

func _ready():
	texture_button.pivot_offset = texture_button.size / 2
	update_text()
	create_idle_animation()

func _on_texture_button_pressed():
	count += 1
	update_text()
	create_click_animation()

func update_text():
	label.text = "Squirrel Clicked:\n" + str(count)

func create_idle_animation():
	if idle_float_tween and idle_float_tween.is_valid():
		idle_float_tween.kill()
	if idle_wobble_tween and idle_wobble_tween.is_valid():
		idle_wobble_tween.kill()

	idle_float_tween = create_tween().set_loops()
	idle_float_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y + 15.0, 1.6)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y - 5.0, 1.4)

	idle_wobble_tween = create_tween().set_loops()
	idle_wobble_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", 8.0, 2.0)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", -8.0, 2.0)



func create_click_animation():
	if click_tween and click_tween.is_valid():
		click_tween.kill()
	
	var original_scale = Vector2(1, 1)
	var pop_scale = Vector2(1.15, 1.15) # change this for pop scale stuff
	
	click_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	click_tween.tween_property(texture_button, "scale", pop_scale, 0.08)
	click_tween.tween_property(texture_button, "scale", original_scale, 0.12)
