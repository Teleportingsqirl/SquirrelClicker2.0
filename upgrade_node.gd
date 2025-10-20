# upgrade_node.gd
extends Control

signal purchase_attempted(upgrade_id)

# --- We declare the variables here, but DO NOT assign them yet ---
var texture_button: TextureButton
var cost_label: Label
var tooltip: PanelContainer
var tooltip_label: RichTextLabel 

var upgrade_id: String
var upgrade_data: Dictionary

# The _ready() function is the safest place to get node references.
func _ready():
	# --- THIS IS THE FIX ---
	# We find all our child nodes here, after they are guaranteed to exist.
	texture_button = get_node("TextureButton")
	cost_label = get_node("Label")
	tooltip = get_node("PanelContainer")
	tooltip_label = tooltip.get_node("RichTextLabel") # Find the grandchild
	# --------------------
	
	tooltip.visible = false
	
	# Connect signals from the button
	texture_button.mouse_entered.connect(_on_mouse_entered)
	texture_button.mouse_exited.connect(_on_mouse_exited)
	texture_button.pressed.connect(_on_pressed)

# The setup function is called AFTER _ready, so the variables will be ready.
func setup(id, data):
	self.upgrade_id = id
	self.upgrade_data = data
	
	# These lines will now work correctly
	cost_label.text = str(data.cost)
	tooltip_label.text = "[center][b]%s[/b]\n%s[/center]" % [data.name, data.description]
	
	# You can uncomment this line to load the texture for the upgrade icon
	texture_button.texture_normal = load(data.icon_path)
	
	# If already purchased, make it look different
	if data.purchased:
		modulate = Color(0.5, 0.5, 0.5) # Gray it out
		texture_button.disabled = true

func _on_mouse_entered():
	tooltip.visible = true

func _on_mouse_exited():
	tooltip.visible = false

func _on_pressed():
	# Tell the main web that this was clicked
	purchase_attempted.emit(upgrade_id)
