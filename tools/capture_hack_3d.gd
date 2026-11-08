extends SceneTree
## Dev tool: screenshot of the hacking minigame opened from a 3D terminal. Usage:
##   godot --path . --script res://tools/capture_hack_3d.gd -- <output_dir>
## Uses a throwaway save. Untyped on purpose (autoloads do not exist at compile time).

var _out: String = "."
var _scene: Node
var _frame: int = 0


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_scene = (load("res://scenes3d/district_01_3d.tscn") as PackedScene).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 30:
		for n: Node in get_nodes_in_group("interactable3d"):
			if n.get_script().get_global_name() == "Terminal3D" and n.terminal_id == "term_south":
				_scene._player.global_position = n.global_position + Vector3(1.2, 0.0, 0.0)
				n.interact(_scene._player)
	elif _frame == 110:
		root.get_texture().get_image().save_png("%s/hack_3d.png" % _out)
		root.get_node("GameState").delete_save()
		quit()
	return false
