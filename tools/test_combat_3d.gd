extends SceneTree
## Dev tool: scripted combat checks for the 3D district. Usage:
##   godot --path . --script res://tools/test_combat_3d.gd -- <output_dir>
## Prints PASS/FAIL lines and exits non-zero on any failure. Untyped on purpose (a
## --script SceneTree compiles before autoloads exist).

var _scene: Node
var _frame: int = 0
var _out: String = "."
var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false
var _state: Node
var _enforcers: Array = []
var _drones: Array = []
var _lost_count: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_scene = (load("res://scenes3d/district_01_3d.tscn") as PackedScene).instantiate()
	root.add_child(_scene)
	_state = root.get_node("GameState")
	_state.signal_lost.connect(func() -> void: _lost_count += 1)


func _check(label: String, condition: bool) -> void:
	_results.append("%s  %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		_failed = true


## An enemy that was destroyed frees itself, so "dead" = freed or inactive.
func _dead(e: Variant) -> bool:
	return not is_instance_valid(e) or not e.active


func _process(_delta: float) -> bool:
	_frame += 1
	var player: Node3D = _scene._player
	match _frame:
		5:
			for e: Node in get_nodes_in_group("enemy3d"):
				if e.get_script().get_global_name() == "Enforcer3D":
					_enforcers.append(e)
				else:
					_drones.append(e)
			_check("2 enforcers + 3 drones spawned", _enforcers.size() == 2 and _drones.size() == 3)
			_check("enforcers active in Physical", _enforcers[0].active and _enforcers[1].active)
			_check("drones hidden in Physical", not _drones[0].active and not _drones[0].visible)
			# Freeze enforcers and put the player at a clear 4 m spot, facing the first one.
			for e: Node in _enforcers:
				e.speed = 0.0
				e.chase_speed = 0.0
			var target: Node3D = _enforcers[0]
			player.global_position = target.global_position + Vector3(-4.0, 0.0, 0.0)
			player._facing = Vector3(1, 0, 0)
		8:
			var target: Node3D = _enforcers[0]
			player.global_position = target.global_position + Vector3(-2.0, 0.0, 0.0)
			player.attack()
			_check("melee does NOT hurt an enforcer (hp stays 4)", _enforcers[0]._hp == 4)
			player.global_position = target.global_position + Vector3(-4.0, 0.0, 0.0)
		12:
			player.fire_pulse()
		12 + 30:
			_shot("combat_pulse")
		12 + 40:
			_check("pulse hurts an enforcer (hp 4 -> 2)", _enforcers[0]._hp == 2)
		12 + 70:
			player.fire_pulse()  # cooldown (0.9 s) has expired by now
		12 + 120:
			_check("second pulse kills the enforcer", _dead(_enforcers[0]))
			_state.player_health = 100
			# Contact: stand on the other enforcer (still frozen, but contact still counts).
			var other: Node3D = _enforcers[1]
			player.global_position = other.global_position
			other._cooldown = 0.0
		12 + 135:
			_check("enforcer contact costs 20 HP", _state.player_health == 80)
			# Let it hit until HP runs out: expect a signal_lost reboot trigger.
			_state.player_health = 15
			_enforcers[1]._cooldown = 0.0
		12 + 150:
			_check("0 HP triggers signal_lost and counts a death", _lost_count >= 1 and _state.deaths >= 1)
			_state.player_health = 100
			# The reboot opened its "SIGNAL LOST" dialogue; attacks are blocked while one is
			# open (correct). Close it by hand so the test can continue.
			root.get_node("Dialogue").is_active = false
			player.global_position = _scene._layers.cell_to_world(Vector2(3, 3))
			_scene._swap()
		12 + 160:
			_check("now in Digital", _state.current_layer == 1)
			_check("drones active in Digital", _drones[0].active)
			_check("enforcers hidden in Digital", not _enforcers[1].active and not _enforcers[1].visible)
			var drone: Node3D = _drones[0]
			for d: Node in _drones:
				d.speed = 0.0
			player.global_position = drone.global_position + Vector3(-1.8, 0.0, 0.0)
			player._facing = Vector3(1, 0, 0)
			player._attack_timer = 0.0
			player.attack()
			_check("melee hurts a drone (hp 3 -> 2)", drone._hp == 2)
		12 + 175:
			var drone2: Node3D = _drones[0]
			player.global_position = drone2.global_position + Vector3(-5.0, 0.0, 0.0)
			player._facing = Vector3(1, 0, 0)
			player._pulse_timer = 0.0
			player.fire_pulse()
		12 + 215:
			_check("pulse destroys a drone (hp 2 -> 0)", _dead(_drones[0]))
			print("\n".join(_results))
			print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
			quit(1 if _failed else 0)
	return false


func _shot(shot_name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
