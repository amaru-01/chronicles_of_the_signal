extends SceneTree
## Dev tool: screenshots of an Enforcer and a pulse in flight (camera snapped, no lag).
##   godot --path . --script res://tools/capture_combat_3d.gd -- <output_dir>
## Untyped on purpose (see test_combat_3d.gd).

var _scene: Node
var _frame: int = 0
var _out: String = "."


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_scene = (load("res://scenes3d/district_01_3d.tscn") as PackedScene).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frame += 1
	var player: Node3D = _scene._player
	match _frame:
		5:
			var enforcer: Node3D = null
			for e: Node in get_nodes_in_group("enemy3d"):
				if e.get_script().get_global_name() == "Enforcer3D":
					enforcer = e as Node3D
					break
			enforcer.speed = 0.0
			enforcer.chase_speed = 0.0
			enforcer.alert_radius = 0.0
			player.global_position = enforcer.global_position + Vector3(-6.0, 0.0, 0.0)
			player._facing = Vector3(1, 0, 0)
			_scene._rig.global_position = player.global_position + Vector3(3.0, 0.0, 0.0)
		30:
			player.fire_pulse()
		34:
			_shot("combat_enforcer_pulse")
		40:
			quit()
	return false


func _shot(shot_name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
