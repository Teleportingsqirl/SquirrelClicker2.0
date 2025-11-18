# SceneTransitioner.gd
#surprisingly simple script that just slides from one scene to another.
#also handles the end credits fade out.
extends CanvasLayer
#these are all the options other scenes can ask for, i tried to keep it consistant so it felt like a real physical space.
enum TransitionMode {
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	FADE
}

var current_scene: Node = null
var is_transitioning: bool = false
const SQUIRREL_SWISH_SFX = preload("res://audios/squirrelswish.wav")

func _ready():
	current_scene = get_tree().current_scene
	get_tree().scene_changed.connect(func(new_scene): current_scene = new_scene)

func transition_to_scene(scene_path: String, animation_mode: TransitionMode = TransitionMode.SLIDE_LEFT):
	if is_transitioning:
		return

	is_transitioning = true
	
	var next_scene_res = load(scene_path)
	if not next_scene_res:
		is_transitioning = false
		return

	match animation_mode:
		TransitionMode.FADE:
			var rect = ColorRect.new()
			rect.color = Color(0, 0, 0, 0)
			add_child(rect)
			rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var tween_in = create_tween()
			await tween_in.tween_property(rect, "color:a", 1.0, 0.5).finished
			if scene_path != "Animation":
				get_tree().change_scene_to_file(scene_path)
			var tween_out = create_tween()
			await tween_out.tween_property(rect, "color:a", 0.0, 0.5).finished
			rect.queue_free()

		_:
			var sfx_player = AudioStreamPlayer.new()
			sfx_player.stream = SQUIRREL_SWISH_SFX
			sfx_player.bus = "SFX"
			sfx_player.volume_db = -10.0
			add_child(sfx_player)
			sfx_player.play()
			sfx_player.finished.connect(sfx_player.queue_free)

			var next_scene = next_scene_res.instantiate()
			var tween = create_tween()
			var viewport_size = get_viewport().size
			get_tree().root.add_child(next_scene)
			get_tree().root.move_child(next_scene, 0)

			match animation_mode:
				TransitionMode.SLIDE_LEFT:
					next_scene.position = Vector2(viewport_size.x, 0)
					tween.tween_property(current_scene, "position", Vector2(-viewport_size.x, 0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
					tween.parallel().tween_property(next_scene, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				TransitionMode.SLIDE_RIGHT:
					next_scene.position = Vector2(-viewport_size.x, 0)
					tween.tween_property(current_scene, "position", Vector2(viewport_size.x, 0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
					tween.parallel().tween_property(next_scene, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				TransitionMode.SLIDE_UP:
					next_scene.position = Vector2(0, viewport_size.y)
					tween.tween_property(current_scene, "position", Vector2(0, -viewport_size.y), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
					tween.parallel().tween_property(next_scene, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				TransitionMode.SLIDE_DOWN:
					next_scene.position = Vector2(0, -viewport_size.y)
					tween.tween_property(current_scene, "position", Vector2(0, viewport_size.y), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
					tween.parallel().tween_property(next_scene, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
			await tween.finished
			if is_instance_valid(current_scene):
				current_scene.queue_free()
			current_scene = next_scene

	is_transitioning = false
