# sqirlparts.gd
extends Node2D
const ITEM_DISPLAY_SIZE = Vector2(48, 48)
const MAX_TOOLTIP_FONT_SIZE = 16
const MIN_TOOLTIP_FONT_SIZE = 8

@onready var item_container = $ItemContainer
@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip/Label
@onready var slots_animation = $background/SlotsAnimation

var item_slots = []

func _ready():
	GameState.is_in_shop = true
	item_container.visible = false
	slots_animation.animation_finished.connect(_on_slots_animation_finished)
	if not is_instance_valid(item_container): print("ERROR: ItemContainer node not found!"); return
	for child in item_container.get_children():
		if child is Marker2D: item_slots.append(child.position)
	tooltip.visible = false
	slots_animation.play("open_slots")

func _on_slots_animation_finished():
	var anim_name = slots_animation.animation
	if anim_name == "open_slots":
		clear_shop(); populate_shop(); item_container.visible = true
	elif anim_name == "close_slots":
		SceneTransitioner.transition_to_scene("res://squirrelclicker.tscn", SceneTransitioner.TransitionMode.SLIDE_RIGHT)

func clear_shop():
	if is_instance_valid(item_container):
		for child in item_container.get_children():
			if child is TextureButton: child.queue_free()

func populate_shop():
	if not GameState.current_shop_items.is_empty():
		_generate_buttons_from_list(GameState.current_shop_items)
		return
	var good_items = []
	var evil_items = []
	for item_id in GameState.all_items:
		var item_data = GameState.all_items[item_id]
		if not item_data.is_spawnable: continue
		
		item_data["id"] = item_id
		
		if item_data.type == "evil":
			evil_items.append(item_data)
		elif item_data.type == "powerup" or not GameState.owned_item_ids.has(item_id):
			good_items.append(item_data)
	
	good_items.shuffle()
	evil_items.shuffle()
	
	var items_for_this_shop = []
	var num_evil_to_spawn = randi_range(2, 6)
	num_evil_to_spawn = min(num_evil_to_spawn, evil_items.size())
	var num_good_to_spawn = item_slots.size() - num_evil_to_spawn
	num_good_to_spawn = min(num_good_to_spawn, good_items.size())
	for i in range(num_good_to_spawn):
		items_for_this_shop.append(good_items[i])
	
	for i in range(num_evil_to_spawn):
		items_for_this_shop.append(evil_items[i % evil_items.size()])
	items_for_this_shop.shuffle()
	GameState.current_shop_items = items_for_this_shop
	_generate_buttons_from_list(items_for_this_shop)

func _generate_buttons_from_list(item_list: Array):
	item_slots.shuffle()
	var num_items_to_spawn = min(item_list.size(), item_slots.size())
	for i in range(num_items_to_spawn):
		var item_data = item_list[i]
		var slot_position = item_slots[i]
		var item_button = TextureButton.new()
		item_button.texture_normal = load(item_data.texture_path)
		item_button.ignore_texture_size = true
		item_button.custom_minimum_size = ITEM_DISPLAY_SIZE
		item_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		item_button.position = slot_position - (ITEM_DISPLAY_SIZE / 2)
		var description = item_data.description
		if item_data.id == "Fazcoin":
			description = GameState.FAZCOIN_DESCRIPTIONS[GameState.fazcoin_count]
		item_button.set_meta("description", description); item_button.set_meta("name", item_data.name); item_button.set_meta("id", item_data.id)
		item_button.mouse_entered.connect(_on_item_mouse_entered.bind(item_button))
		item_button.mouse_exited.connect(_on_item_mouse_exited)
		item_button.pressed.connect(_on_item_button_pressed.bind(item_button))
		item_container.add_child(item_button)

func _on_item_button_pressed(item_button):
	GameState.is_in_shop = false
	GameState.current_shop_items = []
	var item_id = item_button.get_meta("id")
	GameState.apply_item_effect(item_id)
	GameState.update_spawnable_items()
	if GameState.scene_change_mailbox != "":
		var scene_to_load = GameState.scene_change_mailbox
		GameState.scene_change_mailbox = ""
		if GameState.scene_change_mailbox == "res://3d squirrel.tscn":
			get_tree().change_scene_to_file(scene_to_load)
		else:
			SceneTransitioner.transition_to_scene(scene_to_load)
	else:
		item_container.visible = false
		tooltip.visible = false
		slots_animation.play("close_slots")

func _adjust_tooltip_font_size():
	var container_height = tooltip.size.y - 10
	var current_font_size = MAX_TOOLTIP_FONT_SIZE
	while current_font_size > MIN_TOOLTIP_FONT_SIZE:
		tooltip_label.add_theme_font_size_override("font_size", current_font_size)
		await get_tree().process_frame
		var text_height = tooltip_label.get_line_count() * tooltip_label.get_line_height()
		if text_height <= container_height: break
		else: current_font_size -= 1
	tooltip_label.add_theme_font_size_override("font_size", current_font_size)

func _on_item_mouse_entered(item_button):
	var item_name = item_button.get_meta("name"); var desc = item_button.get_meta("description")
	tooltip_label.text = item_name + ": " + desc
	_adjust_tooltip_font_size(); tooltip.visible = true

func _on_item_mouse_exited():
	tooltip.visible = false
