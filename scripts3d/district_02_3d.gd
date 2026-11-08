class_name District02_3D
extends District3D
## District 02 "The Archive" in 3D, ported from the 2D layout (same pixel coordinates):
## alternating-world shelves, three keys for a gate, a timed gate with a drone shortcut,
## and the Curator's core with the final choice.


func _init() -> void:
	district_id = "3d_district_02"
	map_path = "res://scenes3d/maps/district_02.txt"


func _theme() -> Dictionary:  # cold archive: teal and ice blue
	return {
		"neon": [Color(0.1, 0.9, 0.9), Color(0.3, 0.6, 1.0), Color(0.6, 0.4, 1.0), Color(0.2, 1.0, 0.6)] as Array[Color],
		"ambient": Color(0.2, 0.34, 0.55), "fog": Color(0.03, 0.1, 0.16),
		"fog_digital": Color(0.02, 0.1, 0.3), "moon": Color(0.35, 0.6, 0.9),
	}


func _spawn_cells() -> Dictionary:
	return {
		"start": Vector2(2, 15),
		"from_hub": Vector2(2, 15),
		"from_d01": Vector2(2, 15),
	}


func _ready() -> void:
	super()
	GameState.terminal_hacked.connect(_on_terminal_hacked)


func _populate() -> void:
	var courier := Npc3D.new()
	courier.name = "Courier"
	courier.realm = Interactable3D.Realm.PHYSICAL
	courier.speaker = "COURIER"
	courier.tint = Color(0.55, 1.0, 0.8)
	courier.lines = [
		"You made it to the Archive. Every memory the Curator deleted ends up here.",
		"The shelves shift between worlds. Cross each one in the right world. Press H if you get lost.",
	] as Array[String]
	courier.question = "Anything else?"
	courier.options = ["What is the Archive?", "Never mind"] as Array[String]
	courier.answers = [
		"A vault inside the Grid. Whoever built it wanted nothing lost, only hidden. Be careful what you find.",
	] as Array[String]
	_place_px(courier, Vector2(144, 400))

	_add_fragment("fragment_03", Vector2(272, 176), [
		"A door sliding shut. You, younger, carrying a crate marked ARCHIVE.",
		"\"One more district,\" you whisper. \"Then it is over.\"",
	] as Array[String])
	_add_fragment("fragment_04", Vector2(1872, 800), [
		"The Curator's voice, softer than you expect: \"I only wanted the city to stop hurting.\"",
		"Your own voice answers: \"Then you should have asked it.\"",
	] as Array[String])

	# ---- the shelf hall and gate A
	_add_terminal(Vector2(560, 464), "term_arch1", Interactable3D.Realm.BOTH, 5, 30.0)
	_add_door(Vector2(656, 480), "term_arch1", [], Interactable3D.Realm.BOTH)

	# ---- the reading rooms: three keys for gate B
	_add_terminal(Vector2(752, 144), "term_r1", Interactable3D.Realm.BOTH, 5, 30.0)
	_add_terminal(Vector2(784, 784), "term_r2", Interactable3D.Realm.BOTH, 6, 25.0, 3, 25)
	_add_terminal(Vector2(1072, 784), "term_r3", Interactable3D.Realm.BOTH, 6, 25.0, 3, 25)
	_add_door(Vector2(1296, 480), "term_r1", ["term_r2", "term_r3"] as Array[String], Interactable3D.Realm.BOTH)

	# ---- the timed gate C and the core
	_add_switch(Vector2(1392, 336), "sw_wall", 12.0)
	_add_door(Vector2(1808, 480), "sw_wall", [], Interactable3D.Realm.BOTH)
	var core := Terminal3D.new()
	core.terminal_id = "term_core"
	core.realm = Interactable3D.Realm.DIGITAL
	core.attempts = 3
	core.time_limit = 15.0
	core.fail_damage = 30
	_place_px(core, Vector2(1936, 464))

	# ---- optional data node (cell 30, 6)
	_add_terminal(Vector2(976, 208), "node_d02", Interactable3D.Realm.BOTH, 5, 25.0, 3, 20, "chip_archive")

	# ---- drones (Grid only)
	_add_enemy_px(Drone3D.new(), Vector2(400, 150), Vector2(0, 560))
	_add_enemy_px(Drone3D.new(), Vector2(896, 608), Vector2(288, 0))
	_add_enemy_px(Drone3D.new(), Vector2(1232, 320), Vector2(0, 320))
	_add_enemy_px(Drone3D.new(), Vector2(1520, 256), Vector2(0, 448))
	_add_enemy_px(Drone3D.new(), Vector2(1648, 704), Vector2(0, -448))
	_add_enemy_px(Drone3D.new(), Vector2(1872, 64), Vector2(0, 832), 3.8)
	_add_enemy_px(Drone3D.new(), Vector2(2000, 864), Vector2(0, -800), 3.8)

	# ---- beacons (one per section) and ways out
	_add_beacon(Vector2(22.5, 15))
	_add_beacon(Vector2(41.5, 15))
	_add_beacon(Vector2(58.5, 15))
	_add_exit(Vector2(2, 5), WorldMap3D.HUB, "from_d02", "VANTAGE PLAZA")
	_add_exit(Vector2(2, 25), "3d_district_01", "from_d02", "STATIC ROW")


func _gps_target() -> Dictionary:
	if not GameState.is_hacked("term_arch1"):
		return _goal_px(Vector2(560, 464), "Terminal at the end of the shelf hall")
	var keys: Array = []
	if not GameState.is_hacked("term_r1"):
		keys.append(_goal_px(Vector2(752, 144), "Key terminal (north-west)"))
	if not GameState.is_hacked("term_r2"):
		keys.append(_goal_px(Vector2(784, 784), "Key terminal (south-west room)"))
	if not GameState.is_hacked("term_r3"):
		keys.append(_goal_px(Vector2(1072, 784), "Key terminal (south-east room)"))
	if not keys.is_empty():
		return _nearest_goal(keys)
	if not GameState.is_hacked("sw_wall"):
		return _goal_px(Vector2(1392, 336), "Grid lever: then run for the gate")
	if not GameState.is_hacked("term_core"):
		return _goal_px(Vector2(1936, 464), "The Curator's core (Grid)")
	return _exit_goal(WorldMap3D.HUB, "Back to the plaza (Relay Tower next)")


func _objectives() -> Array[Dictionary]:
	return [
		{
			"done": func() -> bool: return GameState.is_hacked("term_arch1"),
			"tiers": [
				"The shelves block the hall. Some of them are only real in one world.",
				"Walk to a shelf wall. If it blocks you, press Space to swap worlds and try again. They alternate.",
				"West wall: cross in the Grid. Middle wall: cross in the real world. Last wall: cross in the Grid. Then hack the terminal at the end of the hall. A drone patrols the Grid in the middle.",
			],
		},
		{
			"done": func() -> bool: return GameState.is_hacked("term_r1"),
			"tiers": [
				"The next gate needs three keys. Start with the nearest terminal.",
				"One terminal is out in the open in the north-west of the reading rooms.",
				"Hack the terminal in the north-west corner of the reading rooms.",
			],
		},
		{
			"done": func() -> bool: return GameState.is_hacked("term_r2"),
			"tiers": [
				"A key is locked inside a small room in the south-west.",
				"That room's walls only exist in the Grid. Try the real world.",
				"Press Space to be in the real world, then walk into the south-west room and hack the terminal.",
			],
		},
		{
			"done": func() -> bool: return GameState.is_hacked("term_r3"),
			"tiers": [
				"The last key is in a room in the south-east. Watch for drones in the Grid.",
				"That room's walls only exist in the real world. Enter through the Grid. Inside the room you can swap back to safety.",
				"Swap to the Grid, go around the drones into the south-east room, then press Space inside it to hide in the real world while you hack.",
			],
		},
		{
			"done": func() -> bool: return _player.global_position.x > 1808.0 / 32.0 * WorldLayers3D.TILE,
			"tiers": [
				"The next gate is on a timer. Find what powers it.",
				"A lever in the Grid, just past the gate, powers it for a short time. The real-world path to the gate is long.",
				"Pull the lever (Grid only), then run. In the real world the shelves force a long winding route. In the Grid the way is straight but drones patrol it. You have 12 seconds.",
			],
		},
		{
			"done": func() -> bool: return false,
			"tiers": [
				"The Curator's core is ahead. It only exists in the Grid.",
				"Swap to the Grid and hack the core. The drones stop while you hack, but the timer does not.",
				"Swap to the Grid, reach the core terminal and break the code in 15 seconds. You decide what happens next.",
			],
		},
	]


func _on_terminal_hacked(id: String) -> void:
	if id == "term_core":
		_finale()


## The reveal. The core opens the road to the Relay Tower; the final choice now happens
## after the boss fight there.
func _finale() -> void:
	await get_tree().process_frame
	if Dialogue.is_active:
		await Dialogue.finished
	GameState.flags["curator_revealed"] = true
	Dialogue.start("CURATOR", [
		"Welcome back, Runner. You built this Archive.",
		"You were my best courier. You carried the deletions yourself, district by district.",
		"Then you erased your own memory so you could not stop yourself. Clever.",
		"Come to the Relay Tower. Finish what you started.",
	] as Array[String])
	await Dialogue.finished
	Dialogue.start("SYSTEM", ["The Relay Tower gate has opened in Vantage Plaza."] as Array[String])
