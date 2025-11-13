#control.gd
extends Control

const BuffBarScene = preload("res://BuffBar.tscn")
const SQUIRREL_CLICK_SFX = preload("res://audios/sqirlclick.wav")

@onready var label = $clicksqrltext
@onready var sps_label: Label = $SPSLabel
@onready var sps_change_label: Label = $SpsChangeLabel
@onready var texture_button = $"sqrlcontainer/sqrlbutton"
@onready var sqirlparts_tooltip = $"../sqirlpartstooltip"
@onready var close_tooltip_button = $"../sqirlpartstooltip/closetooltip"

@onready var building_price_label = $"sqirl buildings/building price"
@onready var building_ad_button = $"sqirl buildings/buildingads"
@onready var building_ad_texture = $"sqirl buildings/buildingads"
@onready var next_button = $"sqirl buildings/nextpagebuildings"
@onready var prev_button = $"sqirl buildings/lastpagebuildings"
@onready var boxes_label: Label = $"../sqirlParts/tv_texture/boxes label"

@onready var lock_overlay = $"sqirl buildings/LockOverlay"
@onready var lock_title_label = $"sqirl buildings/LockOverlay/LockTitleLabel"
@onready var lock_condition_label = $"sqirl buildings/LockOverlay/LockConditionLabel"
@onready var tv_texture: TextureRect = $"../sqirlParts/tv_texture"

@onready var toast_popup = $ToastPopup
@onready var toast_label = $ToastPopup/ToastLabel
@onready var toast_timer = $ToastTimer
@onready var buff_container = $BuffsBox/MarginContainer/BuffContainer
@onready var effects_layer = $"../EffectsLayer"

@onready var stats_button = $"sqirl buildings/Stats"
@onready var upgrade_button = $"../upgradeButton"

var current_building_index = 0
var idle_float_tween: Tween; var idle_wobble_tween: Tween; var click_tween: Tween
var buff_ui_nodes = {}
var on_texture = preload("res://sqrlart/shopart/Sprite-shopcountdisplay.png")
var off_texture = preload("res://sqrlart/shopart/Sprite-shopcountdisplayempty.png")

func _ready():
	texture_button.pivot_offset = texture_button.size / 2
	create_idle_animation()
	next_button.pressed.connect(_on_next_building_pressed)
	prev_button.pressed.connect(_on_prev_building_pressed)
	building_ad_button.pressed.connect(_on_purchase_building_pressed)
	
	stats_button.pressed.connect(_on_stats_button_pressed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	sqirlparts_tooltip.visible = false
	close_tooltip_button.pressed.connect(_on_close_parts_tooltip_pressed)
	
	update_text(); update_sps_display(); update_building_display()
	show_offline_progress_toast() 

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not GameState.is_in_shop:
		get_viewport().set_input_as_handled()
		SceneTransitioner.transition_to_scene("res://mainmenu.tscn", SceneTransitioner.TransitionMode.SLIDE_RIGHT)

func _process(_delta):
	if GameState.death_mailbox:
		_start_death_sequence()
		return

	if not GameState.toast_mailbox.is_empty(): _show_toast(GameState.toast_mailbox.pop_front())
	if not GameState.sps_change_mailbox.is_empty():
		var change = GameState.sps_change_mailbox.pop_front(); _handle_sps_change(change.old, change.new)
	if not GameState.building_unlocked_mailbox.is_empty():
		var unlocked_building_name = GameState.building_unlocked_mailbox.pop_front()
		_show_toast("New Building Unlocked: %s!" % unlocked_building_name)
		update_building_display()
	if GameState.squirrelboxes <= 0 :
		tv_texture.texture = off_texture
		boxes_label.text = str("")
	else:
		tv_texture.texture = on_texture
		boxes_label.text = str(GameState.squirrelboxes)
	
	update_text(); update_sps_display(); _update_buff_display()
	texture_button.position = texture_button.position.round()

func _start_death_sequence():
	GameState.death_mailbox = false
	
	var flash_rect = ColorRect.new()
	flash_rect.color = Color(1.0, 0, 0, 0)
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.add_child(flash_rect)
	
	var flash_tween = create_tween().set_trans(Tween.TRANS_QUINT)
	var chain = flash_tween.chain()
	chain.tween_property(flash_rect, "color:a", 0.7, 0.1)
	chain.tween_property(flash_rect, "color:a", 0.0, 0.4)
	await flash_tween.finished
	flash_rect.queue_free()

	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.add_child(fade_rect)
	
	var death_tween = create_tween()
	death_tween.tween_property(fade_rect, "color:a", 1.0, 1.5).set_ease(Tween.EASE_IN)
	await death_tween.finished
	
	GameState.save_game()
	get_tree().quit()

func _update_buff_display():
	var current_time = Time.get_unix_time_from_system()
	
	_update_single_buff("steroids", "Steroids", int(GameState.steroid_end_time - current_time), 30, Color.LIGHT_GREEN, false)
	_update_single_buff("tapeworm", "Tapeworm", int(GameState.tapeworm_end_time - current_time), 30, Color.RED, false)
	_update_single_buff("pie", "Nostalgia", int(GameState.pie_end_time - current_time), 600, Color.LIGHT_GREEN, true)
	_update_single_buff("gyoza", "Gyoza", int(GameState.gyoza_end_time - current_time), 900, Color.RED, true)
	_update_single_buff("test", "Infertility", int(GameState.test_end_time - current_time), 300, Color.RED, true)

func _update_single_buff(id: String, display_name: String, remaining: int, max_duration: int, color: Color, show_minutes: bool):
	if remaining > 0:
		var buff_bar: Control
		if not buff_ui_nodes.has(id):
			buff_bar = BuffBarScene.instantiate()
			buff_container.add_child(buff_bar)
			buff_ui_nodes[id] = buff_bar
		
		buff_bar = buff_ui_nodes[id]
		buff_bar.update_display(display_name, remaining, max_duration, color, show_minutes)

	elif buff_ui_nodes.has(id):
		buff_ui_nodes[id].queue_free()
		buff_ui_nodes.erase(id)

func _handle_sps_change(old_sps, new_sps):
	var diff = new_sps - old_sps
	if abs(diff) < 0.01: return
	var change_text = "+%.1f SPS" % diff if diff >= 0 else "%.1f SPS" % diff
	sps_change_label.text = change_text; sps_change_label.modulate = Color.GREEN if diff > 0 else Color.RED
	var start_pos_y = sps_change_label.position.y; var tween = create_tween()
	sps_change_label.modulate.a = 1.0
	tween.tween_property(sps_change_label, "position:y", start_pos_y - 20, 2.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sps_change_label, "modulate:a", 0.0, 2.5)
	await tween.finished; sps_change_label.position.y = start_pos_y

func _show_toast(message: String):
	toast_label.text = message; toast_popup.visible = true; toast_timer.start()

func show_offline_progress_toast():
	var progress = GameState.get_and_clear_offline_progress()
	if progress.seconds > 1 and progress.squirrels > 0.1:
		var time_text = format_seconds_to_string(progress.seconds)
		var squirrels_text = GameState.format_number(progress.squirrels, true)
		var message = "While you were away for %s \n you earned %s squirrels!" % [time_text, squirrels_text]
		_show_toast(message)

func _on_toast_timer_timeout():
	toast_popup.visible = false

func _on_texture_button_pressed():
	var click_gain = GameState.squirrels_per_click * GameState.click_multiplier
	if GameState.owned_upgrade_ids.has("negative_squirrel"):
		click_gain += GameState.squirrels_per_second * 0.01
	GameState.squirrels += click_gain
	GameState.total_clicks += 1
	GameState.total_squirrels_earned += click_gain
	create_click_animation()
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = SQUIRREL_CLICK_SFX
	sfx_player.volume_db = -45.0
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _on_next_building_pressed():
	current_building_index = (current_building_index + 1) % GameState.buildings.size(); update_building_display()

func _on_prev_building_pressed():
	current_building_index = (current_building_index - 1 + GameState.buildings.size()) % GameState.buildings.size(); update_building_display()

func _on_purchase_building_pressed():
	if not GameState.buildings[current_building_index].unlocked:
		return
	
	var cost = GameState.calculate_building_cost(current_building_index)
	if GameState.squirrels >= cost:
		GameState.squirrels -= cost; GameState.buildings[current_building_index].owned += 1
		GameState.recalculate_sps(); update_building_display()

func update_text():
	label.text = "Squirrels: " + GameState.format_number(GameState.squirrels)

func update_sps_display():
	sps_label.text = "SPS: " + GameState.format_number(GameState.squirrels_per_second, true)

func update_building_display():
	var current_building = GameState.buildings[current_building_index]
	var new_texture = load(current_building.texture_path)
	building_ad_texture.texture_normal = new_texture

	if current_building.unlocked:
		lock_overlay.visible = false
		building_ad_button.disabled = false
		building_price_label.visible = true
		var cost: float = GameState.calculate_building_cost(current_building_index)
		building_price_label.text = "Cost: " + GameState.format_number(cost)
	else:
		lock_overlay.visible = true
		building_ad_button.disabled = true
		building_price_label.visible = false
		lock_title_label.text = "LOCKED"
		lock_condition_label.text = current_building.unlock_condition_text

func format_seconds_to_string(total_seconds: int) -> String:
	if total_seconds < 60: return "%d seconds" % [total_seconds]
	elif total_seconds < 3600: return "%d minutes" % [int(total_seconds / 60.0)]
	elif total_seconds < 86400: return "%d hours" % [int(total_seconds / 3600.0)]
	else: return "%d days" % [int(total_seconds / 86400.0)]

func _on_3d_button_pressed():
	get_tree().change_scene_to_file("res://3d squirrel.tscn")

func _on_upgrade_button_pressed():
	SceneTransitioner.transition_to_scene("res://upgrade_web.tscn", SceneTransitioner.TransitionMode.SLIDE_LEFT)

func _on_stats_button_pressed():
	SceneTransitioner.transition_to_scene("res://stats_screen.tscn", SceneTransitioner.TransitionMode.SLIDE_DOWN)

func _on_sqirlparts_button_pressed():
	if GameState.squirrelboxes > 0:
		if not GameState.has_seen_parts_tooltip:
			sqirlparts_tooltip.visible = true
			GameState.has_seen_parts_tooltip = true
			return
		GameState.squirrelboxes -= 1
		SceneTransitioner.transition_to_scene("res://sqirlparts.tscn", SceneTransitioner.TransitionMode.SLIDE_LEFT)
	else:
		return
		
func _on_close_parts_tooltip_pressed():
	sqirlparts_tooltip.visible = false

func create_idle_animation():
	if (idle_float_tween and idle_float_tween.is_running()) or \
	   (idle_wobble_tween and idle_wobble_tween.is_running()): return
	if idle_float_tween and idle_float_tween.is_valid(): idle_float_tween.kill()
	if idle_wobble_tween and idle_wobble_tween.is_valid(): idle_wobble_tween.kill()
	idle_float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y + 15.0, 1.6)
	idle_float_tween.tween_property(texture_button, "position:y", texture_button.position.y - 5.0, 1.4)
	idle_wobble_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", 8.0, 2.0)
	idle_wobble_tween.tween_property(texture_button, "rotation_degrees", -8.0, 2.0)

func create_click_animation():
	if click_tween and click_tween.is_valid(): click_tween.kill()
	var original_scale = Vector2(1, 1); var pop_scale = Vector2(1.15, 1.15)
	click_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(texture_button, "scale", pop_scale, 0.08)
	click_tween.tween_property(texture_button, "scale", original_scale, 0.12)
