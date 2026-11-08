extends SceneTree
## Dev tool: checks the GPS arrow. Usage:
##   godot --path . --script res://tools/test_gps_3d.gd -- <output_dir>
## Runs in a window (it needs a rendered camera). Uses a throwaway save file. Untyped on
## purpose (a --script SceneTree compiles before autoloads exist).

var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false
var _out: String = "."
var _state: Node


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_state = root.get_node("GameState")
	_state.save_path = "user://dev_test_save.json"
	_run()


func _check(label: String, condition: bool) -> void:
	_results.append("%s  %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		_failed = true


func _load_scene(path: String) -> Node:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await process_frame
	var scene: Node = (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	for i: int in 4:
		await process_frame
	return scene


func _near(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() < 0.6


func _run() -> void:
	_state.reset()
	_state.delete_save()

	# ---- hub: points at Static Row until the first gate is open
	var hub: Node = await _load_scene("res://scenes3d/hub_3d.tscn")
	var goal: Dictionary = hub._gps_target()
	var d01_exit: Vector3 = hub._layers.cell_to_world(Vector2(3, 14))
	_check("hub: GPS points at the Static Row exit at the start", not goal.is_empty() and _near(goal["pos"], d01_exit))
	_check("hub: the arrow is showing and the minimap marks the goal", hub._gps.is_showing() and hub._minimap.gps_target is Vector3)
	var screen_dir: Vector2 = hub._gps._direction
	_check("hub: the arrow points left on screen (the exit is to the west)", screen_dir.x < -0.3)
	_check("hub: the label has a distance and a name", hub._gps._text.contains(" m ") and hub._gps._text.contains("Static Row"))
	root.get_texture().get_image().save_png("%s/gps_hub.png" % _out)

	hub._player.global_position = d01_exit + Vector3(0.0, 0.0, 1.5)
	await process_frame
	await process_frame
	_check("hub: the arrow hides once you arrive", not hub._gps.is_showing())

	hub._player.global_position = hub._layers.cell_to_world(Vector2(22, 22))
	await process_frame
	await process_frame
	_check("hub: it comes back when you walk away", hub._gps.is_showing())
	hub._unhandled_input(_action("gps"))
	await process_frame
	_check("G turns the GPS off", not hub._gps.is_showing() and not hub._gps_on)
	hub._unhandled_input(_action("gps"))
	await process_frame
	_check("G turns it back on", hub._gps.is_showing() and hub._gps_on)

	_state.hack_terminal("term_gate")
	_check("hub: after the first gate, GPS points at the Archive exit",
		_near(hub._gps_target()["pos"], hub._layers.cell_to_world(Vector2(40, 14))))
	_state.hack_terminal("term_core")
	_check("hub: after the core, GPS points at the Relay Tower",
		_near(hub._gps_target()["pos"], hub._layers.cell_to_world(Vector2(22, 3))))
	_state.flags["curator_defeated"] = true
	_check("hub: nothing to point at once the Curator is beaten", hub._gps_target().is_empty())

	# ---- District 01: Fixer first, then the terminals in order, then the way on
	_state.reset()
	var d01: Node = await _load_scene("res://scenes3d/district_01_3d.tscn")
	_check("d01: first it points at the Fixer", _near(d01._gps_target()["pos"], d01._px_offset(Vector2(176, 176))))
	_state.flags["talked_fixer"] = true
	_check("d01: then the gate terminal", _near(d01._gps_target()["pos"], d01._px_offset(Vector2(976, 304))))
	_state.hack_terminal("term_gate")
	d01._player.global_position = d01._px_offset(Vector2(880, 200))
	_check("d01: of the two key terminals it picks the nearer (north relay)",
		_near(d01._gps_target()["pos"], d01._px_offset(Vector2(880, 176))))
	_state.hack_terminal("term_relay")
	_check("d01: then the south terminal", _near(d01._gps_target()["pos"], d01._px_offset(Vector2(912, 592))))
	_state.hack_terminal("term_south")
	_check("d01: then the timed lever", _near(d01._gps_target()["pos"], d01._px_offset(Vector2(1232, 176))))
	_state.hack_terminal("sw_timed")
	var archive_exit: Dictionary = d01._gps_target()
	_check("d01: finally the Archive exit", not archive_exit.is_empty() and str(archive_exit["label"]).contains("Archive"))
	d01._gps_on = true
	d01._player.global_position = d01._px_offset(Vector2(400, 500))
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/gps_d01.png" % _out)

	# ---- every district has a goal at the start of its story
	for path: String in ["res://scenes3d/district_02_3d.tscn", "res://scenes3d/district_03_3d.tscn", "res://scenes3d/relay_tower_3d.tscn"]:
		_state.reset()
		var scene: Node = await _load_scene(path)
		_check("%s: GPS has a first goal" % path.get_file(), not scene._gps_target().is_empty())

	_state.delete_save()
	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	quit(1 if _failed else 0)


func _action(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
