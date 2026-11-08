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

	# ---- fresh install: no Continue, New Game is focused
	var title: Node = await _title()
	var new_game: Button = title.get_node("Center/VBox/NewGameButton")
	var cont: Button = title.get_node("Center/VBox/ContinueButton")
	_check("title: 'New Game' button exists and is visible", new_game.visible and new_game.text == "New Game")
	_check("title: there is no 2D start button any more", title.get_node_or_null("Center/VBox/StartButton") == null)
	_check("title: no Continue without a save", not cont.visible)
	_check("title: focus starts on New Game when there is no save", new_game.has_focus())

	# ---- a save from the old 2D game falls back to the hub
	_state.current_district = "district_02"
	_state.save_game()
	title = await _title()
	cont = title.get_node("Center/VBox/ContinueButton")
	_check("title: an old save shows 'Continue'", cont.visible and cont.text == "Continue")
	cont.pressed.emit()
	await _wait(1.3)
	_check("an unknown (old 2D) district resumes in the hub",
		current_scene != null and current_scene.get("district_id") == "3d_hub")

	# ---- a 3D save -> Continue resumes that district
	_state.reset()
	_state.current_district = "3d_district_02"
	_state.save_game()
	title = await _title()
	cont = title.get_node("Center/VBox/ContinueButton")
	_check("title: a 3D save shows 'Continue'", cont.visible and cont.text == "Continue")
	cont.pressed.emit()
	await _wait(1.3)
	_check("Continue resumes District 02",
		current_scene != null and current_scene.get("district_id") == "3d_district_02")

	# ---- Start 3D: clean slate, lands in the hub, old save deleted
	_state.flags["picked_fragment_01"] = true
	_state.save_game()
	title = await _title()
	title.get_node("Center/VBox/NewGameButton").pressed.emit()
	await _wait(1.3)
	_check("New Game plays the intro cinematic first",
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
	_check("New Game wipes the previous progress",
		not _state.flags.has("picked_fragment_01") and _state.inventory.is_empty()
		and not str(_state.saved_district()).begins_with("district_"))
	var spawn: Vector3 = current_scene._layers.cell_to_world(Vector2(22, 22))
	_check("New Game spawns at the hub's start point", current_scene._player.global_position.distance_to(spawn) < 0.5)

	_state.delete_save()
	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	_state.delete_save()
	quit(1 if _failed else 0)
