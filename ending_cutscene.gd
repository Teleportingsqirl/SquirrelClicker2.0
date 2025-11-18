# ending_cutscene.gd
extends Control

@onready var ending_animation: AnimatedSprite2D = $EndingAnimation
@onready var credits_text: RichTextLabel = $CreditsText

func _ready() -> void:
	credits_text.visible = false
	ending_animation.position = get_viewport_rect().size / 2
	var anim_name = "Animation" 
	if ending_animation.sprite_frames.has_animation(anim_name):
		ending_animation.sprite_frames.set_animation_loop(anim_name, false)

	ending_animation.animation_finished.connect(_on_ending_animation_finished)

	ending_animation.play(anim_name)

func _on_ending_animation_finished():
	ending_animation.visible = false
	_start_credits_scroll()

func _start_credits_scroll():
	credits_text.visible = true
	var viewport_height = get_viewport_rect().size.y
	credits_text.position.y = viewport_height
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var end_y = -credits_text.get_content_height()
	var scroll_duration = 30.0
	
	tween.tween_property(credits_text, "position:y", end_y, scroll_duration)
	tween.finished.connect(func():
		get_tree().change_scene_to_file("res://mainmenu.tscn")
)
