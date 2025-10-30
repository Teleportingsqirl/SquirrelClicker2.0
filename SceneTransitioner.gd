# SceneTransitioner.gd
extends CanvasLayer

enum TransitionMode {
	SLIDE_LEFT,
	SLIDE_RIGHT
}

var current_scene: Node = null
var is_transitioning = false

func _ready():
	current_scene = get_tree().current_scene

func transition_to_scene(scene_path: String, animation_mode: TransitionMode = TransitionMode.SLIDE_LEFT):
	if is_transitioning:
		return

	is_transitioning = true

	var next_scene_res = load(scene_path)
	if not next_scene_res:
		is_transitioning = false
		return

	var next_scene = next_scene_res.instantiate()
	var tween = create_tween()
	var viewport_width = get_viewport().size.x
	
	get_tree().root.add_child(next_scene)

	match animation_mode:
		TransitionMode.SLIDE_LEFT:
			next_scene.position = Vector2(viewport_width, 0)
			tween.tween_property(current_scene, "position:x", -viewport_width, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		TransitionMode.SLIDE_RIGHT:
			next_scene.position = Vector2(-viewport_width, 0)
			tween.tween_property(current_scene, "position:x", viewport_width, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished
	current_scene.queue_free()
	current_scene = next_scene
	is_transitioning = false
