# GameState.gd
extends Node

# --- Player Stats ---
var squirrels: float = 0.0
var squirrels_per_click: int = 1

# --- Building Modifiers ---
# We'll use these later to apply upgrades like "Better Nuts"
var nut_sps_bonus: float = 0.0
var tree_sps_bonus: float = 0.0
# ... add more for other buildings
