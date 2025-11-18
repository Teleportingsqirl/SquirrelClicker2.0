# ending_cutscene.gd
#simple code to play the final cutscene, and then scroll the credits.
#KNOWN ISSUE!!!!! THERE IS AN ERROR WHEN THE GAME CLOSES AFTER YOU WIN! 
#it does not seem to do anything, and its definitly because of a missmatch with the scene transition code
#i did not have time to fix it
extends Control

@onready var ending_animation: AnimatedSprite2D = $EndingAnimation
@onready var credits_text: RichTextLabel = $CreditsText

func _ready() -> void:
	await get_tree().process_frame

	credits_text.visible = false
	ending_animation.position = get_viewport_rect().size / 2
	
	var anim_name = "default" 

	if ending_animation.sprite_frames.has_animation(anim_name):
		ending_animation.sprite_frames.set_animation_loop(anim_name, false)
	else:
		print("ERROR: Could not find animation '", anim_name, "'")
		return

	ending_animation.animation_finished.connect(_on_ending_animation_finished)
	ending_animation.play(anim_name)

func _on_ending_animation_finished():
	ending_animation.visible = false
	_start_credits_scroll()

func _start_credits_scroll():
	credits_text.visible = true
	
	var viewport_height = get_viewport_rect().size.y
	credits_text.position.y = viewport_height
	
	await get_tree().process_frame

	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	
	var end_y = -credits_text.size.y
	
	var scroll_duration = 126.0
	
	tween.tween_property(credits_text, "position:y", end_y, scroll_duration)
	
	tween.finished.connect(func():
		get_tree().quit()
)
#this blocks you from pressing escape during the cutscene or credits
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
