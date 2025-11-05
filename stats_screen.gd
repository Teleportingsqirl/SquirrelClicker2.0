extends Control

@onready var stats_container: VBoxContainer = $ScrollContainer/StatsContainer
@onready var back_button: Button = $Back 

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	populate_stats()

func populate_stats():
	for child in stats_container.get_children():
		child.queue_free()

	add_stat_header("General")
	add_stat("Total Squirrels Earned:", GameState.format_number(GameState.total_squirrels_earned, true))
	add_stat("Current Squirrels:", GameState.format_number(GameState.squirrels, true))
	add_stat("Squirrels Per Second:", GameState.format_number(GameState.squirrels_per_second, true))
	add_stat("Squirrels Per Click:", GameState.format_number(GameState.squirrels_per_click * GameState.click_multiplier, true))
	add_stat("Total Clicks On The Squirrel:", str(GameState.total_clicks))
	
	var total_buildings = 0
	for b in GameState.buildings:
		total_buildings += b.owned
	
	add_stat_header("Buildings")
	add_stat("Total Buildings Owned:", str(total_buildings))
	for building in GameState.buildings:
		if building.owned > 0:
			add_stat(building.name + " Owned:", str(building.owned))

	add_stat_header("Items Owned")
	if GameState.owned_item_ids.is_empty():
		add_stat("None yet!", "")
	else:
		for item_id in GameState.owned_item_ids:
			if GameState.all_items.has(item_id):
				add_stat(GameState.all_items[item_id].name, "")

func add_stat(stat_name: String, value: String):
	var label = Label.new()
	label.text = stat_name + " " + value
	stats_container.add_child(label)

func add_stat_header(text: String):
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	stats_container.add_child(spacer)
	var header_label = RichTextLabel.new()
	stats_container.add_child(header_label)
	header_label.fit_content = true
	header_label.add_theme_font_size_override("normal_font_size", 24)
	header_label.append_text("[u]" + text + "[/u]")

func _on_back_pressed():
	SceneTransitioner.transition_to_scene("res://squirrelclicker.tscn", SceneTransitioner.TransitionMode.SLIDE_RIGHT)
