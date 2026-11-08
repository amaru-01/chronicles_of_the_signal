extends SceneTree
## Dev tool: checks the 3D world structure. Usage:
##   godot --path . --script res://tools/test_world_3d.gd -- <output_dir>
## Loads the hub and both districts, checks what spawns, door logic, the swap-trap rule,
## beacons / fast-travel unlock, locked exits and real scene travel. Prints PASS/FAIL and
## exits non-zero on failure. Untyped on purpose (a --script SceneTree compiles before the
## autoloads exist).

var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false
var _out: String = "."
var _state: Node


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_state = root.get_node("GameState")
	_state.save_path = "user://dev_test_save.json"  # never touch the real save
	_run()


func _check(label: String, condition: bool) -> void:
	_results.append("%s  %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		_failed = true


func _count(group: String) -> int:
	return get_nodes_in_group(group).size()


func _count_class(group: String, class_name_: String) -> int:
	var n: int = 0
	for node: Node in get_nodes_in_group(group):
		if node.get_script() != null and node.get_script().get_global_name() == class_name_:
			n += 1
	return n


func _load_scene(path: String) -> Node:
	var scene: Node = (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	# ------------------------------------------------------------------ hub
	_state.reset()
	var hub: Node = await _load_scene("res://scenes3d/hub_3d.tscn")
	_check("hub: district id", hub.district_id == "3d_hub")
	_check("hub: 3 exits", _count("exit3d") == 3)
	_check("hub: 1 beacon", _count("beacon3d") == 1)
	_check("hub: no enemies (safe zone)", _count("enemy3d") == 0)
	_check("hub: minimap built", hub._minimap != null and hub._minimap._textures.size() == 2)
	_check("hub: weather cycle running", hub._weather_tween != null and hub._weather_tween.is_valid())
	var east: Node = null
	for e: Node in get_nodes_in_group("exit3d"):
		if e.target_district == "3d_district_02":
			east = e
	_check("hub: Archive exit locked at the start", east != null and east.is_locked())
	_state.hack_terminal("term_gate")
	_check("hub: Archive exit unlocks once term_gate is hacked", not east.is_locked())
	_state.reset()
	var tower: Node = null
	for e: Node in get_nodes_in_group("exit3d"):
		if e.target_district == "3d_relay_tower":
			tower = e
	_check("hub: Relay Tower exit stays sealed", tower != null and tower.is_locked())
	_check("hub: only the hub is unlocked for fast travel", root.get_node("GameState") != null
		and _unlocked("3d_hub") and not _unlocked("3d_district_01"))
	var hub_player: Node3D = hub._player
	var hub_spawn: Vector3 = hub._layers.cell_to_world(Vector2(22, 22))
	_check("hub: player spawns at the start cell", hub_player.global_position.distance_to(hub_spawn) < 0.5)

	await _wait(0.8)
	root.get_texture().get_image().save_png("%s/world_hub.png" % _out)

	# beacon unlock + checkpoint
	var beacon: Node = get_nodes_in_group("beacon3d")[0]
	beacon._on_body_entered(hub_player)
	_check("hub: touching the beacon saves a checkpoint", _state.checkpoints.has("3d_hub"))

	# ------------------------------------------------------------------ travel hub -> D01
	WorldMap3D_travel("3d_district_01", "from_hub")
	await _wait(1.2)
	var d01: Node = current_scene
	_check("travel: hub -> District 01 loaded", d01 != null and d01.district_id == "3d_district_01")
	var d01_player: Node3D = d01._player
	var arrive: Vector3 = d01._layers.cell_to_world(Vector2(5, 12))
	_check("travel: arrived at the 'from_hub' entry point", d01_player.global_position.distance_to(arrive) < 1.0)

	# ------------------------------------------------------------------ District 01 contents
	_check("d01: 4 gates", _count("doors3d") == 4)
	_check("d01: 4 terminals (3 puzzle + 1 optional data node)", _count_class("interactable3d", "Terminal3D") == 4)
	_check("d01: 2 levers", _count_class("interactable3d", "Switch3D") == 2)
	_check("d01: 2 memory fragments", _count_class("interactable3d", "Pickup3D") == 2)
	_check("d01: 2 NPCs", _count_class("interactable3d", "Npc3D") == 2)
	_check("d01: 3 drones + 2 enforcers", _count_class("enemy3d", "Drone3D") == 3 and _count_class("enemy3d", "Enforcer3D") == 2)
	_check("d01: 2 beacons, 2 exits", _count("beacon3d") == 2 and _count("exit3d") == 2)

	var timed_gate: Node = null
	var first_gate: Node = null
	for d: Node in get_nodes_in_group("doors3d"):
		if d.required_terminal == "sw_timed":
			timed_gate = d
		if d.required_terminal == "term_gate":
			first_gate = d
	_check("door: timed gate starts closed", not timed_gate._open)
	_state.hack_terminal("sw_timed")
	await process_frame
	_check("door: opens when its switch is on", timed_gate._open)
	# Close while the player stands in the doorway: it must wait.
	d01_player.global_position = timed_gate.global_position
	_state.unhack_terminal("sw_timed")
	await _wait(0.3)
	_check("door: does NOT close on top of the player", timed_gate._open)
	d01_player.global_position = timed_gate.global_position + Vector3(8.0, 0.0, 0.0)
	await _wait(0.3)
	_check("door: closes once the doorway is clear", not timed_gate._open)

	# Swap-trap rule with a door: Physical-only gate is not there in the Grid, so standing
	# in its gap in the Grid must block a swap back to Physical.
	_check("swap-trap: standing in a closed physical gate's gap blocks the swap",
		d01._layers._would_trap(0, first_gate.global_position))
	_state.hack_terminal("term_gate")
	await process_frame
	_check("swap-trap: no block once that gate is open", not d01._layers._would_trap(0, first_gate.global_position))

	# beacon in D01 unlocks fast travel to D01
	var d01_beacon: Node = get_nodes_in_group("beacon3d")[0]
	d01_beacon._on_body_entered(d01_player)
	_check("fast travel: D01 beacon unlocks District 01", _unlocked("3d_district_01"))

	# ------------------------------------------------------------------ D01 -> D02 via the exit
	var to_d02: Node = null
	for e: Node in get_nodes_in_group("exit3d"):
		if e.target_district == "3d_district_02":
			to_d02 = e
	_check("d01: exit to the Archive is open (no lock)", to_d02 != null and not to_d02.is_locked())
	to_d02._on_body_entered(d01_player)
	await _wait(1.2)
	var d02: Node = current_scene
	_check("travel: D01 exit -> District 02 loaded", d02 != null and d02.district_id == "3d_district_02")

	# ------------------------------------------------------------------ District 02 contents
	_check("d02: 3 gates", _count("doors3d") == 3)
	_check("d02: 6 terminals (5 puzzle + 1 optional data node)", _count_class("interactable3d", "Terminal3D") == 6)
	_check("d02: 1 lever, 2 fragments, 1 NPC",
		_count_class("interactable3d", "Switch3D") == 1 and _count_class("interactable3d", "Pickup3D") == 2
		and _count_class("interactable3d", "Npc3D") == 1)
	_check("d02: 7 drones, no enforcers", _count_class("enemy3d", "Drone3D") == 7 and _count_class("enemy3d", "Enforcer3D") == 0)
	_check("d02: 3 beacons, 2 exits", _count("beacon3d") == 3 and _count("exit3d") == 2)
	var core: Node = null
	for t: Node in get_nodes_in_group("interactable3d"):
		if t.get_script().get_global_name() == "Terminal3D" and t.terminal_id == "term_core":
			core = t
	_check("d02: the core terminal exists only in the Grid", core != null and core.realm == 2)
	var gate_b: Node = null
	for d: Node in get_nodes_in_group("doors3d"):
		if d.required_terminal == "term_r1":
			gate_b = d
	_state.hack_terminal("term_r1")
	_state.hack_terminal("term_r2")
	await process_frame
	_check("d02: the 3-key gate stays shut with 2 of 3 keys", not gate_b._open)
	_state.hack_terminal("term_r3")
	await process_frame
	_check("d02: ...and opens with all 3", gate_b._open)
	var arrive2: Vector3 = d02._layers.cell_to_world(Vector2(2, 15))
	_check("travel: arrived at District 02's entry point", d02._player.global_position.distance_to(arrive2) < 1.0)

	# ------------------------------------------------------------------ fast travel menu
	d02._travel_menu.open()
	var buttons: Array = []
	for b: Node in d02._travel_menu._list.get_children():
		buttons.append(b)
	_check("menu: lists all 3 districts", buttons.size() == 3)
	var enabled: int = 0
	for b: Node in buttons:
		if not b.disabled:
			enabled += 1
	_check("menu: hub + District 01 are selectable (current district is not)", enabled == 2)
	d02._travel_menu.close()
	paused = false

	# shot for the record
	root.get_texture().get_image().save_png("%s/world_d02.png" % _out)

	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	_state.delete_save()
	quit(1 if _failed else 0)


func _unlocked(district_id: String) -> bool:
	return district_id == "3d_hub" or _state.flags.has("ft_" + district_id)


## WorldMap3D.travel, looked up at runtime (see the note at the top about autoloads).
func WorldMap3D_travel(district_id: String, spawn: String) -> void:
	var map_script: GDScript = load("res://scripts3d/world_map_3d.gd")
	map_script.travel(district_id, spawn)
