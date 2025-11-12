extends Control

const UpgradeNodeScene = preload("res://upgrade_node.tscn")

@onready var scroll_container = $ScrollContainer
@onready var background = $ScrollContainer/Background
@onready var web_container = $ScrollContainer/Background/WebContainer
@onready var info_label: RichTextLabel = $CanvasLayer/InfoPanel/InfoLabel
@onready var back_button = $CanvasLayer/backButton

var node_instances = {}
var is_dragging = false
var drag_start_position = Vector2.ZERO
const DRAG_THRESHOLD = 10 

func _ready():
	scroll_container.gui_input.connect(_on_scroll_container_gui_input)
	back_button.pressed.connect(_on_back_button_pressed)
	
	await get_tree().process_frame

	var bg_texture = load("res://sqrlart/upgradewebart/Sprite-upgradeweb.png")
	background.texture = bg_texture
	
	var texture_size = bg_texture.get_size()
	var viewport_size = get_viewport_rect().size
	
	var width_ratio = viewport_size.x / texture_size.x
	var height_ratio = viewport_size.y / texture_size.y
	var scale_factor = max(width_ratio, height_ratio)
	
	var final_bg_size = texture_size * scale_factor
	background.custom_minimum_size = final_bg_size
	
	populate_web(scale_factor)
	
	await get_tree().process_frame

	var h_bar = scroll_container.get_h_scroll_bar()
	var v_bar = scroll_container.get_v_scroll_bar()
	
	scroll_container.scroll_horizontal = (h_bar.max_value - h_bar.page) / 2
	scroll_container.scroll_vertical = v_bar.max_value
	
	info_label.clear()
	update_all_nodes()
	draw_all_lines()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func _on_scroll_container_gui_input(event):
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		accept_event()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		is_dragging = false
		drag_start_position = event.position

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		is_dragging = false
		
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		if not is_dragging and event.position.distance_to(drag_start_position) > DRAG_THRESHOLD:
			is_dragging = true
		
		if is_dragging:
			scroll_container.scroll_horizontal -= event.relative.x
			scroll_container.scroll_vertical -= event.relative.y

func _on_back_button_pressed():
	SceneTransitioner.transition_to_scene("res://squirrelclicker.tscn", SceneTransitioner.TransitionMode.SLIDE_RIGHT)
	
func populate_web(scale_factor: float):
	for upgrade_id in GameState.all_upgrades:
		var upgrade_data = GameState.all_upgrades[upgrade_id]
		upgrade_data["id"] = upgrade_id
		var scaled_data = upgrade_data.duplicate()
		scaled_data.position *= scale_factor
		var node = UpgradeNodeScene.instantiate()
		web_container.add_child(node)
		node.set_data(scaled_data)
		node.hovered.connect(_on_node_hovered)
		node.unhovered.connect(_on_node_unhovered)
		node.purchased.connect(_on_node_purchased)
		node_instances[upgrade_id] = node
func update_all_nodes():
	for node in node_instances.values():
		node.update_status(GameState.owned_upgrade_ids)
func draw_all_lines():
	await get_tree().process_frame
	for node in node_instances.values():
		node.draw_dependency_lines(node_instances)
func _on_node_hovered(data):
	var cost_text = GameState.format_number(data.cost)
	var can_afford = GameState.squirrels >= data.cost
	var color = "lime" if can_afford else "red"
	info_label.clear()
	info_label.append_text("[b]" + data.name + "[/b]\n")
	info_label.append_text(data.description + "\n\n")
	info_label.append_text("[color=" + color + "]Cost: " + cost_text + " Squirrels[/color]")
func _on_node_unhovered():
	info_label.clear()
func _on_node_purchased(data):
	if GameState.squirrels >= data.cost:
		GameState.squirrels -= data.cost
		GameState.owned_upgrade_ids.append(data.id)
		GameState.apply_upgrade_effect(data.id)
		update_all_nodes()
		_on_node_hovered(data) 
	else:
		print("Not enough squirrels!")
