# upgrade_web.gd
extends Control

# --- THIS IS THE NEW, DIRECT METHOD ---
# Instead of exporting, we load the scene directly.
# This bypasses the editor bug. Make sure your file is named "upgrade_node.tscn".
var upgrade_node_scene = load("res://upgrade_node.tscn")
# ------------------------------------

@export var strands: int = 3 # You can still change this in the Inspector

# --- Layout Configuration ---
const COLUMN_SPACING = 200
const ROW_SPACING = 120

var upgrade_data = UpgradeData.new().upgrades
var node_instances = {} # Stores a reference to each created node instance

func _ready():
	generate_web()

func _draw():
	# This function draws the connecting lines
	for id in upgrade_data:
		var upgrade = upgrade_data[id]
		if upgrade.purchased and node_instances.has(id):
			var start_pos = node_instances[id].position
			for next_id in upgrade.unlocks:
				if node_instances.has(next_id):
					var end_pos = node_instances[next_id].position
					draw_line(start_pos, end_pos, Color.AQUAMARINE, 2.0, true)

func generate_web():
	# Clear any existing nodes
	for child in get_children():
		child.queue_free()
	node_instances.clear()
	
	var viewport_center = get_viewport_rect().size / 2
	
	# 1. Create the starting node
	var start_node = create_upgrade_node("start_node", viewport_center + Vector2(0, -200))
	
	# 2. Create the first level of branching nodes
	var first_level_ids = upgrade_data["start_node"].unlocks
	for i in range(first_level_ids.size()):
		var id = first_level_ids[i]
		var angle = (PI * 2 / first_level_ids.size()) * i - (PI/2)
		# Use the 'position' of the created start_node
		var spawn_pos = start_node.position + Vector2(cos(angle), sin(angle)) * COLUMN_SPACING
		create_upgrade_node(id, spawn_pos)

# CORRECTED: Renamed 'position' to 'spawn_pos' to avoid the shadowing warning
# In upgrade_web.gd

func create_upgrade_node(id, spawn_pos):
	if upgrade_node_scene:
		var instance = upgrade_node_scene.instantiate()
		
		# --- THIS IS THE FIX ---
		# 1. Add the node to the scene tree FIRST.
		#    This will trigger its _ready() function, which sets up all its internal variables.
		add_child(instance)
		
		# 2. NOW it is safe to call setup(), because we know _ready() has finished.
		instance.setup(id, upgrade_data[id])
		# --------------------

		instance.position = spawn_pos - (instance.size / 2) # Center it
		instance.purchase_attempted.connect(_on_purchase_attempted)
		node_instances[id] = instance
		return instance
	return null

func _on_purchase_attempted(id):
	var upgrade = upgrade_data[id]
	if GameState.squirrels >= upgrade.cost:
		print("Purchasing: ", upgrade.name)
		GameState.squirrels -= upgrade.cost
		upgrade.purchased = true
		_apply_upgrade_effect(id)
		
		# Refresh the visuals
		generate_web()
		queue_redraw() # Tells Godot to call _draw() again
	else:
		print("Not enough squirrels!")

# THIS IS THE PLACEHOLDER FOR YOUR CUSTOM CODE
func _apply_upgrade_effect(id):
	match id:
		"sharp_claws":
			GameState.squirrels_per_click += 1
		"better_nuts":
			GameState.nut_sps_bonus += 0.1
			# Now you need to make your control.gd use this bonus
		"unlock_forest":
			print("The Forest is now unlocked!")
			# Here you would maybe set a global flag, e.g., GameState.forest_unlocked = true
