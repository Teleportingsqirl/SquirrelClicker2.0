# SceneTransitioner.gd
extends CanvasLayer

var current_scene: Node = null
var is_transitioning = false

func _ready():
	# When the game starts, get a reference to the currently loaded scene
	current_scene = get_tree().current_scene

func transition_to_scene(scene_path: String):
	# Prevent starting a new transition while one is already in progress
	if is_transitioning:
		return

	is_transitioning = true

	# Load the new scene resource
	var next_scene_res = load(scene_path)
	if not next_scene_res:
		is_transitioning = false
		return

	# Create an instance of the new scene
	var next_scene = next_scene_res.instantiate()

	# --- The Animation Logic ---
	var tween = create_tween()
	var viewport_width = get_viewport().size.x

	# Position the new scene just off-screen to the right
	next_scene.position = Vector2(viewport_width, 0)
	get_tree().root.add_child(next_scene)

	# Animate the CURRENT scene sliding OFF to the left
	tween.tween_property(current_scene, "position:x", -viewport_width, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Animate the NEXT scene sliding ON to the center, at the same time
	tween.parallel().tween_property(next_scene, "position:x", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Wait for the animation to finish
	await tween.finished

	# --- Cleanup ---
	# Remove the old scene
	current_scene.queue_free()
	# Update our reference to the new current scene
	current_scene = next_scene
	is_transitioning = false
