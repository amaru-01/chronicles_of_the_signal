extends SceneTree
## Dev tool: checks the title screen's 3D entry. Usage:
##   godot --path . --script res://tools/test_title_3d.gd -- <output_dir>
## Uses a throwaway save file (user://dev_test_save.json), never the real save.
## Untyped on purpose (autoloads).

var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false
var _out: String = "."
var _state: Node
const TITLE: String = "res://ui/title_screen.tscn"


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


func _title() -> Node:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	var scene: Node = (load(TITLE) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _key(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _run() -> void:
	_state.reset()
	_state.delete_save()

	# ---- fresh install: no Continue, 3D start offered
	var title: Node = await _title()
	var start_3d: Button = title.get_node("Center/VBox/Start3DButton")
	var start_2d: Button = title.get_node("Center/VBox/StartButton")
	var cont: Button = title.get_node("Center/VBox/ContinueButton")
	_check("title: 'Start 3D' button exists and is visible on desktop", start_3d.visible and start_3d.text.contains("3D"))
	_check("title: 'Start 2D' button still exists", start_2d.visible and start_2d.text.contains("2D"))
	_check("title: no Continue without a save", not cont.visible)
	_check("title: focus starts on Start 3D when there is no save", start_3d.has_focus())

	# ---- a 2D save -> plain Continue
	_state.current_district = "district_02"
	_state.save_game()
	title = await _title()
	cont = title.get_node("Center/VBox/ContinueButton")
	_check("title: 2D save shows plain 'Continue'", cont.visible and cont.text == "Continue")
	_check("saved_district() reads the 2D id", _state.saved_district() == "district_02")

	# ---- a 3D save -> 'Continue (3D)', and it resumes the 3D district
	_state.reset()
	_state.current_district = "3d_district_02"
	_state.save_game()
	title = await _title()
	cont = title.get_node("Center/VBox/ContinueButton")
	_check("title: 3D save shows 'Continue (3D)'", cont.visible and cont.text == "Continue (3D)")
	cont.pressed.emit()
	await _wait(1.3)
	_check("Continue (3D) resumes District 02 in 3D",
		current_scene != null and current_scene.get("district_id") == "3d_district_02")

	# ---- Start 3D: clean slate, lands in the hub, old save deleted
	_state.flags["picked_fragment_01"] = true
	_state.save_game()
	title = await _title()
	title.get_node("Center/VBox/Start3DButton").pressed.emit()
	await _wait(1.3)
	_check("Start 3D plays the intro cinematic first",
		current_scene != null and current_scene.scene_file_path == "res://scenes3d/intro_3d.tscn")
	var intro: Node = current_scene
	_check("intro: starts on shot 0 and the shots are all defined", intro._shot == 0 and intro.SHOTS.size() == 7)
	intro._unhandled_input(_key("ui_accept"))  # first press completes the typed line
	_check("intro: Enter finishes the line being typed", intro._chars >= str(intro.SHOTS[0]["text"]).length())
	intro._unhandled_input(_key("ui_accept"))  # second press moves on (after the fade)
	await _wait(1.2)
	_check("intro: Enter moves to the next shot", intro._shot == 1)
	intro._unhandled_input(_key("ui_cancel"))
	_check("intro: Esc skips ahead to the controls card", intro._shot == intro.SHOTS.size() - 1)
	intro._unhandled_input(_key("ui_accept"))
	await _wait(2.5)
	_check("intro: finishing it loads the hub", current_scene != null and current_scene.get("district_id") == "3d_hub")
	_check("intro: marks itself as seen", _state.flags.get("intro_seen", false))
	# (The quest log autosaves its fresh state a moment after a new game starts, so a save
	# file may exist again. What matters is that the old progress is gone.)
	_check("Start 3D wipes the previous progress",
		not _state.flags.has("picked_fragment_01") and _state.inventory.is_empty()
		and not str(_state.saved_district()).begins_with("district_"))
	var spawn: Vector3 = current_scene._layers.cell_to_world(Vector2(22, 22))
	_check("Start 3D spawns at the hub's start point", current_scene._player.global_position.distance_to(spawn) < 0.5)

	# ---- Start 2D still works
	title = await _title()
	title.get_node("Center/VBox/StartButton").pressed.emit()
	await _wait(1.3)
	_check("Start 2D still loads the classic District 01",
		current_scene != null and current_scene.scene_file_path == "res://scenes/world/district_01.tscn")

	_state.delete_save()
	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	_state.delete_save()
	quit(1 if _failed else 0)
