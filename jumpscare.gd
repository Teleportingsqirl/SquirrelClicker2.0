extends Control

func _ready():
  var timer = get_tree().create_timer(10.0)
  await timer.timeout
  get_tree().change_scene_to_file("res://squirrelclicker.tscn")
