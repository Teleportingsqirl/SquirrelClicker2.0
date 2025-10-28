# itemshop.gd
extends Node2D

# --- NODE REFERENCES ---
# Use the drag-and-drop method or a %UniqueName to be 100% sure this path is correct.
@onready var item_container = $ItemContainer 
@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip/Label

# An array to hold all our slot positions
var item_slots = []

func _ready():
	# --- CORRECTED SLOT FINDING LOGIC ---
	# We need to look for children inside the item_container node, not the root.
	# First, a safety check to make sure the container was found.
	if not is_instance_valid(item_container):
		print("ERROR: ItemContainer node not found! Check the path in the script.")
		return # Stop the function to prevent further crashes.

	# Now, loop through the children of the correct node.
	for child in item_container.get_children():
		if child is Marker2D:
			item_slots.append(child.position)
	
	# Hide the tooltip initially
	tooltip.visible = false

# This function is called every time the scene is entered
func _enter_tree():
	clear_shop()
	populate_shop()

func clear_shop():
	# Delete any items that were there from the last visit
	if is_instance_valid(item_container): # Safety check
		for child in item_container.get_children():
			# We only want to delete the items (TextureButtons), not the slots (Marker2D)
			if child is TextureButton:
				child.queue_free()

func populate_shop():
	# 1. Get a list of all items that are allowed to spawn
	var spawnable_items = []
	for item_id in GameState.all_items:
		var item_data = GameState.all_items[item_id]
		# Only add it if it's spawnable AND the player doesn't already own it (if it's a cosmetic/permanent)
		if item_data.is_spawnable:
			if item_data.type == "powerup" or not GameState.owned_item_ids.has(item_id):
				# Add the id to the data so we can reference it later
				item_data["id"] = item_id
				spawnable_items.append(item_data)
	
	# Randomize both the items and the slots
	spawnable_items.shuffle()
	item_slots.shuffle()
	
	# 2. Decide how many items to show (e.g., up to 3, or the number of slots available)
	var num_items_to_spawn = min(3, spawnable_items.size(), item_slots.size())
	
	# 3. Create and place the items
	for i in range(num_items_to_spawn):
		var item_data = spawnable_items[i]
		var slot_position = item_slots[i]
		
		# We use a TextureButton so it's clickable and has hover signals
		var item_button = TextureButton.new()
		item_button.texture_normal = load(item_data.texture_path)
		item_button.position = slot_position
		item_button.pivot_offset = item_button.texture_normal.get_size() / 2 # Center the texture
		
		# Store the item's data directly inside the button node for easy access
		item_button.set_meta("description", item_data.description)
		item_button.set_meta("id", item_data.id)
		
		# Connect signals for hover-over tooltips
		item_button.mouse_entered.connect(_on_item_mouse_entered.bind(item_button))
		item_button.mouse_exited.connect(_on_item_mouse_exited)
		
		# Add the finished button to the scene
		item_container.add_child(item_button)

# --- Signal Handlers for Tooltip ---

func _on_item_mouse_entered(item_button):
	# Get the description we stored in the button's metadata
	tooltip_label.text = item_button.get_meta("description")
	# Position the tooltip slightly above and to the right of the mouse
	tooltip.global_position = get_global_mouse_position() + Vector2(20, -30)
	tooltip.visible = true

func _on_item_mouse_exited():
	tooltip.visible = false
