extends Control

signal hovered(data)
signal unhovered()
signal purchased(data)

var upgrade_data: Dictionary
var status = "locked"

@onready var line_drawer: Line2D = $Line2D
@onready var color_rect: TextureRect = $ColorRect
@onready var icon_button: TextureButton = $IconButton
@onready var lock_icon: TextureRect = $IconButton/LockIcon

const ICON_SIZE = 96.0
const BACKGROUND_PADDING = 8.0

func _ready():
	self.z_index = 1 
	line_drawer.z_index = 0
	line_drawer.width = 8.0 
	line_drawer.show_behind_parent = true 

	move_child(icon_button, get_child_count() - 1)

	icon_button.mouse_entered.connect(func(): emit_signal("hovered", upgrade_data))
	icon_button.mouse_exited.connect(func(): emit_signal("unhovered"))
	icon_button.pressed.connect(func():
		if status == "available":
			emit_signal("purchased", upgrade_data)
	)

func set_data(data: Dictionary):
	upgrade_data = data
	icon_button.texture_normal = load(upgrade_data.texture_path)

	custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	position = data.position - (custom_minimum_size / 2)

	var bg_size = ICON_SIZE + BACKGROUND_PADDING * 2
	color_rect.size = Vector2(bg_size, bg_size)
	color_rect.position = (custom_minimum_size - color_rect.size) / 2

	icon_button.ignore_texture_size = true
	icon_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

func update_status(owned_upgrades: Array):
	if owned_upgrades.has(upgrade_data.get("id")):
		status = "purchased"
	else:
		var dependencies_met = true
		for dep_id in upgrade_data.dependencies:
			if not owned_upgrades.has(dep_id):
				dependencies_met = false
				break
		if dependencies_met:
			status = "available"
		else:
			status = "locked"
	
	lock_icon.hide()

	match status:
		"purchased":
			icon_button.self_modulate = Color(0.6, 0.6, 0.6)
			color_rect.self_modulate = Color(0.5, 0.5, 0.5)
			icon_button.disabled = true
		"available":
			icon_button.self_modulate = Color.WHITE
			color_rect.self_modulate = Color.WHITE
			icon_button.disabled = false
		"locked":
			icon_button.self_modulate = Color(0.2, 0.2, 0.2)
			color_rect.self_modulate = Color(0.3, 0.3, 0.3)
			lock_icon.show()
			icon_button.disabled = true

func draw_dependency_lines(all_nodes: Dictionary):
	line_drawer.clear_points()
	
	var start_center = size / 2
	var node_radius = (ICON_SIZE + BACKGROUND_PADDING * 2) / 2.0
	line_drawer.add_point(start_center)
	
	for dep_id in upgrade_data.dependencies:
		if all_nodes.has(dep_id):
			var dependency_node = all_nodes[dep_id]
			
			var end_center = (dependency_node.position - self.position) + (dependency_node.size / 2)
			var direction = (end_center - start_center).normalized()
			
			var adjusted_end_point = end_center - direction * node_radius
			line_drawer.add_point(adjusted_end_point)
			line_drawer.add_point(start_center)

	if status == "available":
		line_drawer.default_color = Color.WHITE
	elif status == "purchased":
		line_drawer.default_color = Color("808080")
	else:
		line_drawer.default_color = Color("404040")
