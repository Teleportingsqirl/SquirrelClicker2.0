# SceneTransitioner.gd (Upgraded Version)
extends CanvasLayer

# NEW: An enum to define our different transition styles.
# This is clean and prevents typos.
enum TransitionMode {
	SLIDE_LEFT, # New scene comes from the right
	SLIDE_RIGHT # New scene comes from the left
}

var current_scene: Node = null
var is_transitioning = false

func _ready():
	current_scene = get_tree().current_scene

# MODIFIED: The function now accepts an animation_mode parameter.
# We give it a default value so old code doesn't break.
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
	
	# Add the new scene to the tree before animating
	get_tree().root.add_child(next_scene)

	# --- NEW: Use a match statement to handle the different modes ---
	match animation_mode:
		TransitionMode.SLIDE_LEFT:
			# New scene starts on the RIGHT, old scene slides OFF to the LEFT.
			next_scene.position = Vector2(viewport_width, 0)
			tween.tween_property(current_scene, "position:x", -viewport_width, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		TransitionMode.SLIDE_RIGHT:
			# New scene starts on the LEFT, old scene slides OFF to the RIGHT.
			next_scene.position = Vector2(-viewport_width, 0)
			tween.tween_property(current_scene, "position:x", viewport_width, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished

	# --- Cleanup (this part is the same) ---
	current_scene.queue_free()
	current_scene = next_scene
	is_transitioning = false
