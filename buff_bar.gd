# BuffBar.gd
extends Control

const FILL_START_X = 94
const MAX_FILL_WIDTH = 196

@onready var fill_rect: TextureRect = $FillRect
@onready var name_label: Label = $NameLabel
@onready var time_label: Label = $TimeLabel
@onready var background_rect: TextureRect = $BackgroundRect

func update_display(display_name: String, remaining: int, max_duration: int, color: Color, show_minutes: bool):
	
	name_label.text = display_name + ":"
	
	var time_text: String
	if not show_minutes:
		time_text = "%ds" % remaining
	else:
		time_text = "%dm" % (int(remaining / 60.0) + 1)
	time_label.text = time_text
	
	if color == Color.RED:
		fill_rect.texture = load("res://sqrlart/Sprite-redbar.png")
	else:
		fill_rect.texture = load("res://sqrlart/Sprite-greenbar.png")

	var ratio = clampf(float(remaining) / max_duration, 0.0, 1.0)
	fill_rect.position.x = FILL_START_X
	fill_rect.size.x = ratio * MAX_FILL_WIDTH
	
	fill_rect.position.y = (background_rect.size.y - fill_rect.texture.get_height()) / 2
	fill_rect.size.y = fill_rect.texture.get_height()
