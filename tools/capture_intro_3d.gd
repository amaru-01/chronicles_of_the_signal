extends SceneTree
## Dev tool: screenshots of every shot of the intro cinematic. Usage:
##   godot --path . --script res://tools/capture_intro_3d.gd -- <output_dir>
## Untyped on purpose (autoloads do not exist when a --script SceneTree compiles).

var _out: String = "."
var _intro: Node
var _frame: int = 0
var _shot: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	_intro = (load("res://scenes3d/intro_3d.tscn") as PackedScene).instantiate()
	root.add_child(_intro)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_pose()
	elif _frame == 6:
		root.get_texture().get_image().save_png("%s/intro_%d.png" % [_out, _shot])
		_shot += 1
		_frame = 1
		if _shot >= _intro.SHOTS.size():
			root.get_node("GameState").delete_save()
			quit()
	return false


## Freeze the intro in the middle of the shot being captured, with its text fully typed.
func _pose() -> void:
	_intro._shot = _shot
	_intro._chars = 9999.0
	_intro._hold = -99.0  # never auto-advance while we look at it
	_intro._fade = 0.0
	_intro._fading_out = false
	_intro._clock = 6.0
	# Times chosen so each shot is at its most telling moment.
	var times: Array = [5.0, 4.0, 3.5, 3.6, 5.0, 4.0, 4.0]
	_intro._t = times[_shot]
