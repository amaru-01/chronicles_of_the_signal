extends SceneTree
## Dev tool: screenshot of the title screen with the 3D entry. Usage:
##   godot --path . --script res://tools/capture_title_3d.gd -- <output_dir>
## Uses a throwaway save path so the real save is never read or changed.

var _out: String = "."
var _frame: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	root.get_node("GameState").delete_save()
	root.add_child((load("res://ui/title_screen.tscn") as PackedScene).instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 90:
		root.get_texture().get_image().save_png("%s/title_3d.png" % _out)
		quit()
	return false
