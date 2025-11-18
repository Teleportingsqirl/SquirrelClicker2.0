# SceneTransitioner.gd
extends CanvasLayer
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
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func transition_to_scene(scene_path: String, animation_mode: TransitionMode = TransitionMode.SLIDE_LEFT):
	if is_transitioning:
		return

	is_transitioning = true
	
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = SQUIRREL_SWISH_SFX
	sfx_player.bus = "SFX"
	sfx_player.volume_db = -10.0
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)
	
	var next_scene_res = load(scene_path)
	if not next_scene_res:
		print("Scene transition failed: Could not load scene at path ", scene_path)
		is_transitioning = false
		return

	var next_scene = next_scene_res.instantiate()
	var tween = create_tween()
	var viewport_size = get_viewport().size
	
	get_tree().root.add_child(next_scene)

	match animation_mode:
		TransitionMode.SLIDE_LEFT:
			next_scene.position = Vector2(viewport_size.x, 0)
			tween.tween_property(current_scene, "position:x", -viewport_size.x, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		TransitionMode.SLIDE_RIGHT:
			next_scene.position = Vector2(-viewport_size.x, 0)
			tween.tween_property(current_scene, "position:x", viewport_size.x, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		TransitionMode.SLIDE_UP:
			next_scene.position = Vector2(0, viewport_size.y)
			tween.tween_property(current_scene, "position:y", -viewport_size.y, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:y", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		TransitionMode.SLIDE_DOWN:
			next_scene.position = Vector2(0, -viewport_size.y)
			tween.tween_property(current_scene, "position:y", viewport_size.y, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:y", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		TransitionMode.FADE:
			var rect = ColorRect.new()
			rect.color = Color(0, 0, 0, 0)
			add_child(rect)
			rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tween.tween_property(rect, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
			await tween.finished
			
			get_tree().change_scene_to_file(scene_path)
			
			current_scene = get_tree().current_scene
			
			var tween_out = create_tween().set_ease(Tween.EASE_OUT)
			tween_out.tween_property(rect, "color:a", 0.0, 0.5) # Fade back to transparent
			await tween_out.finished
			
			rect.queue_free()
			
			if is_instance_valid(current_scene):
				current_scene.queue_free()
			
			current_scene = next_scene
	if animation_mode != TransitionMode.FADE:
		await tween.finished
		if is_instance_valid(current_scene):
			current_scene.queue_free()
		current_scene = next_scene
	
	is_transitioning = false
