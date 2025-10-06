extends Control

var count = 0

@onready var rich_text_label = $RichTextLabel


func _on_texture_button_pressed():
	count += 1
	rich_text_label.text = "[font_size=70][color=100]Squirrel Clicked:[/color] " + str(count)
