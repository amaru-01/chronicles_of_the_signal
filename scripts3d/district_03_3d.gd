class_name District03_3D
extends District3D
## District 03 "Neon Market": three zones separated by two gates.
##  A  the market square: sentries guard it. A lever sits in a booth whose walls only exist
##     in the Grid, so you walk in through the real world, then swap to pull it (the lever is
##     Grid-only) to open gate A.
##  B  the night market: stalkers haunt the Grid. Two terminal booths, one ringed by
##     real-world-only walls (enter from the Grid) and one ringed by Grid-only walls (enter
##     from the real world). Both must be hacked to open gate B.
##  C  the vault: a memory fragment and a data node, guarded by a sentry and drones.


func _init() -> void:
	district_id = "3d_district_03"
	map_path = "res://scenes3d/maps/district_03.txt"


func _theme() -> Dictionary:  # the market: loud magenta, orange and yellow
	return {
		"neon": [Color(1.0, 0.15, 0.6), Color(1.0, 0.6, 0.1), Color(1.0, 0.9, 0.2), Color(0.1, 0.9, 1.0), Color(0.9, 0.2, 1.0)] as Array[Color],
		"ambient": Color(0.4, 0.28, 0.5), "fog": Color(0.18, 0.05, 0.14),
		"fog_digital": Color(0.25, 0.03, 0.3), "moon": Color(0.7, 0.4, 0.8),
	}


func _spawn_cells() -> Dictionary:
	return {"start": Vector2(3, 15), "from_hub": Vector2(3, 15)}


func _populate() -> void:
	var broker := Npc3D.new()
	broker.name = "Broker"
	broker.realm = Interactable3D.Realm.PHYSICAL
	broker.speaker = "BROKER"
	broker.tint = Color(1.0, 0.8, 0.5)
	broker.lines = [
		"Neon Market. Everything is for sale except the truth, and that goes cheap.",
		"The sentries keep the square quiet. The lever for the first gate is in the booth with the Grid-only walls. Walk in from the real world, then swap.",
	] as Array[String]
	broker.question = "Ask the Broker:"
	broker.options = ["What lies past the gates?", "Who built the sentries?", "Never mind"] as Array[String]
	broker.answers = [
		"A vault the Curator forgot to empty. Stalkers drift through the middle: they walk through walls in the Grid. Real world is safer there.",
		"The Curator, to keep the lower city asleep. They do not care who they shoot.",
	] as Array[String]
	_place(broker, Vector2(9, 17))

	# ---- zone A: the square
	_add_enemy(Sentry3D.new(), Vector2(10, 9), Vector3.ZERO)
	_add_enemy(Sentry3D.new(), Vector2(10, 21), Vector3.ZERO)
	_add_enemy(Sentry3D.new(), Vector2(18, 26), Vector3.ZERO)
	var lever := Switch3D.new()
	lever.switch_id = "sw_market"
	lever.realm = Interactable3D.Realm.DIGITAL
	_place(lever, Vector2(16, 15))
	_add_door_cell(Vector2(20.5, 15), "sw_market", [])

	# ---- zone B: the night market
	_add_terminal_cell(Vector2(29, 8), "term_m1")
	_add_terminal_cell(Vector2(29, 21), "term_m2")
	_add_door_cell(Vector2(40.5, 15), "term_m1", ["term_m2"] as Array[String])
	_add_enemy(Stalker3D.new(), Vector2(25, 5), Vector3(4.0, 0.0, 0.0))
	_add_enemy(Stalker3D.new(), Vector2(34, 12), Vector3(0.0, 0.0, 4.0))
	_add_enemy(Stalker3D.new(), Vector2(33, 24), Vector3(-4.0, 0.0, 0.0))
	_add_enemy(Enforcer3D.new(), Vector2(24, 17), Vector3(0.0, 0.0, 8.0))

	# ---- zone C: the vault
	_add_fragment("fragment_05", Vector2(50.5 * 32.0, 15.5 * 32.0), [
		"A market stall at dusk. You are buying something wrapped in paper: a gift.",
		"\"For the Curator,\" you say, smiling. \"They never get anything.\"",
	] as Array[String])
	_add_terminal(Vector2(47.5 * 32.0, 23.5 * 32.0), "node_d03", Interactable3D.Realm.BOTH, 5, 25.0, 3, 20, "chip_market")
	_add_enemy(Sentry3D.new(), Vector2(46, 12), Vector3.ZERO)
	_add_enemy_px(Drone3D.new(), Vector2(45 * 32.0, 22 * 32.0), Vector2(256.0, 0.0))
	_add_enemy_px(Drone3D.new(), Vector2(55 * 32.0, 8 * 32.0), Vector2(0.0, 192.0))

	_add_beacon(Vector2(6, 15))
	_add_beacon(Vector2(22, 15))
	_add_beacon(Vector2(43, 15))
	_add_exit(Vector2(2, 3), WorldMap3D.HUB, "from_d03", "VANTAGE PLAZA")


func _gps_target() -> Dictionary:
	if not GameState.is_hacked("sw_market"):
		return _goal_cell(Vector2(16, 15), "Lever booth (Grid walls)")
	if not (GameState.is_hacked("term_m1") and GameState.is_hacked("term_m2")):
		var open: Array = []
		if not GameState.is_hacked("term_m1"):
			open.append(_goal_cell(Vector2(29, 8), "North booth terminal"))
		if not GameState.is_hacked("term_m2"):
			open.append(_goal_cell(Vector2(29, 21), "South booth terminal"))
		return _nearest_goal(open)
	if not GameState.inventory.has("fragment_05"):
		return _goal_px(Vector2(50.5 * 32.0, 15.5 * 32.0), "Memory fragment in the vault")
	return _exit_goal(WorldMap3D.HUB, "Back to the plaza")


func _objectives() -> Array[Dictionary]:
	return [
		{
			"done": func() -> bool: return GameState.is_hacked("sw_market"),
			"tiers": [
				"The first gate is powered by a lever somewhere in the square.",
				"The lever is in the booth in the middle of the square. Its walls only exist in the Grid.",
				"Walk into the booth from the real world, then press Space to swap into the Grid inside it, and pull the lever.",
			],
		},
		{
			"done": func() -> bool: return GameState.is_hacked("term_m1") and GameState.is_hacked("term_m2"),
			"tiers": [
				"The second gate needs two terminals, each in its own booth.",
				"One booth is walled only in the real world, the other only in the Grid. Swap to get in.",
				"North booth: enter from the Grid. South booth: enter from the real world. Hack both. Stalkers cannot reach you in the real world.",
			],
		},
		{
			"done": func() -> bool: return false,
			"tiers": ["The vault is open. Take the memory fragment, and watch for the sentry."],
		},
	]


func _add_terminal_cell(cell: Vector2, id: String) -> void:
	_add_terminal(Vector2((cell.x + 0.5) * 32.0, (cell.y + 0.5) * 32.0), id, Interactable3D.Realm.BOTH, 5, 25.0, 3, 20)


func _add_door_cell(cell: Vector2, required: String, extra: Array[String]) -> void:
	_add_door(Vector2(cell.x * 32.0, cell.y * 32.0), required, extra, Interactable3D.Realm.BOTH)
