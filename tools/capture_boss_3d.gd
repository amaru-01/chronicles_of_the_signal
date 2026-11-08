extends SceneTree
## Dev tool: screenshots of the Curator fight and the Neon Market.
##   godot --path . --script res://tools/capture_boss_3d.gd -- <output_dir>
## Uses a throwaway save file. Untyped on purpose (autoloads).

var _scene: Node
var _frame: int = 0
var _out: String = "."
var _stage: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	_scene = (load("res://scenes3d/relay_tower_3d.tscn") as PackedScene).instantiate()
	root.add_child(_scene)
	current_scene = _scene


func _process(_delta: float) -> bool:
	_frame += 1
	var state: Node = root.get_node("GameState")
	if _stage == 0:
		match _frame:
			5:
				var boss: Node3D = null
				for e: Node in get_nodes_in_group("enemy3d"):
					if e.get_script().get_global_name() == "Curator3D":
						boss = e as Node3D
				for e: Node in get_nodes_in_group("enemy3d"):
					if e != boss:
						e.queue_free()
				var p: Node3D = _scene._player
				p.global_position = boss.global_position + Vector3(2.0, 0.0, 9.0)
				_scene._rig.global_position = p.global_position
				boss._attack_timer = 0.4
			40:
				state.player_health = 100
				root.get_texture().get_image().save_png("%s/boss_physical.png" % _out)
				_scene._swap()
				for e: Node in get_nodes_in_group("enemy3d"):
					if e.get_script().get_global_name() == "Curator3D":
						e._form_timer = 0.01
			140:
				state.player_health = 100
				state.player_signal_integrity = 100
				root.get_texture().get_image().save_png("%s/boss_digital.png" % _out)
				_stage = 1
				_frame = 0
				_scene.queue_free()
				var d03: Node = (load("res://scenes3d/district_03_3d.tscn") as PackedScene).instantiate()
				root.add_child(d03)
				current_scene = d03
				_scene = d03
	else:
		if _frame == 60:
			var p2: Node3D = _scene._player
			p2.global_position = _scene._layers.cell_to_world(Vector2(8, 15))
			_scene._rig.global_position = p2.global_position
		if _frame == 100:
			root.get_texture().get_image().save_png("%s/market.png" % _out)
			state.delete_save()
			quit()
	return false
