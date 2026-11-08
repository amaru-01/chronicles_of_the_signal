class_name District01_3D
extends District3D
## District 01 "Static Row" in 3D: the full 2D puzzle set, ported by reusing the 2D
## pixel coordinates (see District3D._place_px). Wall that exists in one world only, two
## key gates, a vault with a Grid-only lever, a timed gate, drones in the Grid and
## armoured enforcers in the real world. Exits: west to the hub, east to The Archive.


func _init() -> void:
	district_id = "3d_district_01"
	map_path = "res://scenes/world/maps/district_01.txt"


func _spawn_cells() -> Dictionary:
	return {
		"start": Vector2(3, 3),
		"from_hub": Vector2(5, 12),
		"from_d02": Vector2(45, 10),
	}


func _populate() -> void:
	# ---- people and story
	var fixer := Npc3D.new()
	fixer.name = "Fixer"
	fixer.realm = Interactable3D.Realm.PHYSICAL
	fixer.speaker = "FIXER"
	fixer.talk_flag = "talked_fixer"
	fixer.lines = [
		"Signal's weak out here. The wall splits this district in two, but only in the real world.",
		"Press Space. The Grid has no wall. Get across, find the terminal, and open the gate for me. And there is a vault down south; the lever for it only exists in the Grid.",
	] as Array[String]
	fixer.alt_if_hacked = "term_gate"
	fixer.alt_lines = ["You opened it. Maybe you're not just another ghost in the wire."] as Array[String]
	fixer.question = "What do you want to know?"
	fixer.options = ["What is the Signal?", "Who are you?", "Never mind"] as Array[String]
	fixer.answers = [
		"It carries everything this city remembers. Right now someone is deleting it, piece by piece.",
		"Just a fixer. I find people who are lost in the wire. You're the first who can walk both sides of it.",
	] as Array[String]
	_place_px(fixer, Vector2(176, 176))

	var courier := Npc3D.new()
	courier.name = "Courier"
	courier.realm = Interactable3D.Realm.PHYSICAL
	courier.speaker = "COURIER"
	courier.tint = Color(0.55, 1.0, 0.8)
	courier.lines = [
		"Gate ahead needs two keys: the relay terminal and the one down south. The relay room has no door in the real world.",
		"Slip in through the Grid. The last gate is on a timer, so be quick.",
	] as Array[String]
	courier.alt_if_hacked = "term_relay"
	courier.alt_lines = ["Relay's live. The way east is open."] as Array[String]
	_place_px(courier, Vector2(1360, 208))

	_add_fragment("fragment_01", Vector2(144, 464), [
		"A rooftop at night. Someone laughs, a face you almost know.",
		"\"Whatever happens, Runner, the Signal remembers for us.\"",
	] as Array[String])
	_add_fragment("fragment_02", Vector2(96, 624), [
		"A server room. Your own hands, typing a command you cannot read.",
		"A voice says: \"Delete them all. Start with the lower districts.\"",
	] as Array[String])

	# ---- puzzle 1: the wall that only exists in the real world
	_add_door(Vector2(656, 320), "term_gate", [], Interactable3D.Realm.PHYSICAL)
	_add_terminal(Vector2(976, 304), "term_gate", Interactable3D.Realm.PHYSICAL)

	# ---- puzzle 2: two keys for the east gate
	_add_terminal(Vector2(880, 176), "term_relay", Interactable3D.Realm.BOTH, 5, 25.0)
	_add_terminal(Vector2(912, 592), "term_south", Interactable3D.Realm.BOTH, 6, 25.0, 3, 25)
	_add_door(Vector2(1168, 320), "term_relay", ["term_south"] as Array[String], Interactable3D.Realm.BOTH)

	# ---- puzzle 3: the vault, opened by a lever that only exists in the Grid
	_add_door(Vector2(240, 640), "sw_vault", [], Interactable3D.Realm.BOTH)
	_add_switch(Vector2(400, 400), "sw_vault", 0.0)

	# ---- puzzle 4: the timed gate
	_add_switch(Vector2(1232, 176), "sw_timed", 12.0)
	_add_door(Vector2(1424, 320), "sw_timed", [], Interactable3D.Realm.BOTH)

	# ---- threats
	_add_enemy_px(Drone3D.new(), Vector2(704, 460), Vector2(320, 0))
	_add_enemy_px(Drone3D.new(), Vector2(1232, 230), Vector2(0, 200))
	_add_enemy_px(Drone3D.new(), Vector2(260, 520), Vector2(200, 0), 2.6)
	_add_enemy(Enforcer3D.new(), Vector2(24, 16), Vector3(10.0, 0.0, 0.0))
	_add_enemy(Enforcer3D.new(), Vector2(32, 4), Vector3(0.0, 0.0, 10.0))

	# ---- optional data node (cell 12, 3)
	_add_terminal(Vector2(400, 112), "node_d01", Interactable3D.Realm.BOTH, 5, 25.0, 3, 20, "chip_static")

	# ---- beacons and ways out
	_add_beacon(Vector2(8, 3))
	_add_beacon(Vector2(28, 9))
	_add_exit(Vector2(2, 12), WorldMap3D.HUB, "from_d01", "VANTAGE PLAZA")
	_add_exit(Vector2(46, 9), "3d_district_02", "from_d01", "THE ARCHIVE")


func _gps_target() -> Dictionary:
	if not GameState.flags.get("talked_fixer", false):
		return _goal_px(Vector2(176, 176), "Talk to the Fixer")
	if not GameState.is_hacked("term_gate"):
		return _goal_px(Vector2(976, 304), "Gate terminal (cross in the Grid)")
	if not (GameState.is_hacked("term_relay") and GameState.is_hacked("term_south")):
		var open: Array = []
		if not GameState.is_hacked("term_relay"):
			open.append(_goal_px(Vector2(880, 176), "Relay terminal"))
		if not GameState.is_hacked("term_south"):
			open.append(_goal_px(Vector2(912, 592), "South terminal"))
		return _nearest_goal(open)
	if not GameState.is_hacked("sw_timed"):
		return _goal_px(Vector2(1232, 176), "Grid lever: then run for the gate")
	return _exit_goal("3d_district_02", "The Archive")


func _objectives() -> Array[Dictionary]:
	return [
		{
			"done": func() -> bool: return GameState.is_hacked("term_gate"),
			"tiers": [
				"The wall in the middle of the alley only exists in the real world.",
				"Press SPACE to swap into the Grid, where the wall is gone, and cross it.",
				"Cross in the Grid, swap back, and hack the terminal on the east side. Strike drones with J; armoured enforcers only fall to the K pulse.",
			],
		},
		{
			"done": func() -> bool: return GameState.is_hacked("term_relay") and GameState.is_hacked("term_south"),
			"tiers": [
				"The next gate needs two keys.",
				"One terminal is in the relay room in the north; the other is in the south. Neither is hidden, but drones guard the Grid.",
				"Hack the relay terminal (north) and the south terminal. The relay room has no door in the real world, so go in through the Grid.",
			],
		},
		{
			"done": func() -> bool: return GameState.is_hacked("sw_timed"),
			"tiers": [
				"The last gate is on a timer. Find what powers it.",
				"A lever that only exists in the Grid powers it for a short time.",
				"Swap to the Grid, pull the lever in the north-east, then run for the gate. You have 12 seconds.",
			],
		},
		{
			"done": func() -> bool: return false,
			"tiers": ["The way east leads to The Archive. Strike drones (J) in the Grid; pulse (K) the enforcers in the real world."],
		},
	]
