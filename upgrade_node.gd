extends Control

signal hovered(data)
signal unhovered()
signal purchased(data)

var upgrade_data: Dictionary
var status = "locked"

@onready var line_drawer: Line2D = $Line2D
@onready var background_rect: ColorRect = $ColorRect
@onready var icon_button: TextureButton = $IconButton

const ICON_SIZE = 96.0
const BACKGROUND_PADDING = 8.0

func _ready():
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
	background_rect.size = Vector2(bg_size, bg_size)
	background_rect.position = (custom_minimum_size - background_rect.size) / 2
	
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
	
	match status:
		"purchased":
			icon_button.self_modulate = Color("a0a0a0")
			background_rect.color = Color("252525", 0.8)
			icon_button.disabled = true
		"available":
			icon_button.self_modulate = Color.WHITE
			background_rect.color = Color("606060", 0.7)
			icon_button.disabled = false
		"locked":
			icon_button.self_modulate = Color("404040")
			background_rect.color = Color("000000", 0.5)
			icon_button.disabled = true
			
func draw_dependency_lines(all_nodes: Dictionary):
	line_drawer.clear_points()
	
	var start_point = size / 2
	
	for dep_id in upgrade_data.dependencies:
		if all_nodes.has(dep_id):
			var dependency_node = all_nodes[dep_id]
			
			if status == "available":
				line_drawer.default_color = Color.WHITE
			else:
				line_drawer.default_color = Color("404040")
			
			var end_point = (dependency_node.position - self.position) + (dependency_node.size / 2)
			
			line_drawer.add_point(start_point)
			line_drawer.add_point(end_point)
