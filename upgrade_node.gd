# upgrade_node.gd
extends Control

signal purchase_attempted(upgrade_id)

var texture_button: TextureButton
var cost_label: Label
var tooltip: PanelContainer
var tooltip_label: RichTextLabel 

var upgrade_id: String
var upgrade_data: Dictionary

func _ready():
	texture_button = get_node("TextureButton")
	cost_label = get_node("Label")
	tooltip = get_node("PanelContainer")
	tooltip_label = tooltip.get_node("RichTextLabel")
	tooltip.visible = false
	
	texture_button.mouse_entered.connect(_on_mouse_entered)
	texture_button.mouse_exited.connect(_on_mouse_exited)
	texture_button.pressed.connect(_on_pressed)

func setup(id, data):
	self.upgrade_id = id
	self.upgrade_data = data
	
	cost_label.text = str(data.cost)
	tooltip_label.text = "[center][b]%s[/b]\n%s[/center]" % [data.name, data.description]
	
	texture_button.texture_normal = load(data.icon_path)
	
	if data.purchased:
		modulate = Color(0.5, 0.5, 0.5) 
		texture_button.disabled = true

func _on_mouse_entered():
	tooltip.visible = true

func _on_mouse_exited():
	tooltip.visible = false

func _on_pressed():
	purchase_attempted.emit(upgrade_id)
