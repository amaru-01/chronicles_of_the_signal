extends SceneTree
## Dev tool: runs the 3D district windowed, drives a short scripted session and saves
## screenshots. Usage:
##   godot --path . --script res://tools/capture_3d.gd -- <output_dir>
## Not part of the game; not exported. Deliberately untyped: a --script SceneTree is
## compiled before autoloads exist, so it must not reference game classes by name.

var _scene: Node
var _frame: int = 0
var _out: String = ""
var _log: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://dev_test_save.json"  # never touch the real save
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "."
	_scene = (load("res://scenes3d/district_01_3d.tscn") as PackedScene).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frame += 1
	var player: Node = _scene._player
	var state: Node = root.get_node("GameState")
	match _frame:
		60:
			_shot("1_physical")
		61:
			_scene._swap()
		70:
			_shot("2_wipe_mid")
		110:
			_shot("3_digital")
			_log.append("layer after swap = %s (1 = digital)" % state.current_layer)
		111:
			var drone: Node3D = get_nodes_in_group("enemy3d")[0]
			player.global_position = drone.global_position - Vector3(1.6, drone.global_position.y, 0.0)
			player._facing = Vector3(1, 0, 0)
		115:
			var drone2: Node3D = get_nodes_in_group("enemy3d")[0]
			_log.append("drone hp before strike = %d" % drone2._hp)
			player.attack()
			_log.append("drone hp after strike = %d" % drone2._hp)
		120:
			_shot("4_strike_flash")
		200:
			_shot("4_strike_settled")
			var pos: Vector3 = player.global_position
			_log.append("would trap in physical at %s = %s (expected true: inside the P wall)" % [pos, _scene._layers._would_trap(0, pos)])
			player.global_position = _scene._layers.cell_to_world(Vector2(24, 14))
			_scene._swap()
			_log.append("layer after swap-back = %s (0 = physical)" % state.current_layer)
		210:
			var term: Node3D = _scene.get_node("PixelViewport/GateTerminal")
			player.global_position = term.global_position + Vector3(1.0, 0.0, 0.0)
		300:
			_log.append("interact target = %s" % str(player.get_target()))
			_shot("5_terminal")
			print("\n".join(_log))
			quit()
	return false


func _shot(shot_name: String) -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png("%s/%s.png" % [_out, shot_name])
