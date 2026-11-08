extends SceneTree
## Dev tool: checks the Phase 4 adventure systems. Usage:
##   godot --path . --script res://tools/test_adventure_3d.gd -- <output_dir>
## Quest logic and chaining, rewards (once only), upgrade effects, save/load, the hub's
## hidden cache, the journal pages, the kill counter, the HUD tracker. Uses a throwaway
## save file. Untyped on purpose (a --script SceneTree compiles before autoloads exist).

var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false
var _out: String = "."
var _state: Node
var _quests: GDScript
var _items: GDScript


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_state = root.get_node("GameState")
	_state.save_path = "user://dev_test_save.json"  # never touch the real save
	_quests = load("res://scripts3d/quests_3d.gd")
	_items = load("res://scripts3d/items_3d.gd")
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
	await process_frame
	await process_frame
	return scene


func _types(events: Array, type: String) -> int:
	var n: int = 0
	for e: Dictionary in events:
		if e["type"] == type:
			n += 1
	return n


func _owned_count(item: String) -> int:
	return _state.inventory.count(item)


func _labels(box: Node) -> String:
	var text: PackedStringArray = PackedStringArray()
	for child: Node in box.get_children():
		if child is Label:
			text.append(child.text)
	return "\n".join(text)


func _run() -> void:
	_state.reset()
	_state.delete_save()

	# ------------------------------------------------------------ quest logic
	var events: Array = _quests.evaluate()
	_check("fresh game: 6 quests start (the Archive and the Tower wait)", _types(events, "quest_start") == 6)
	_check("q_wire active, q_archive locked",
		_quests.status("q_wire") == "active" and _quests.status("q_archive") == "locked")
	var tracked: Dictionary = _quests.tracked()
	_check("tracker: first main objective", tracked.get("quest") == "Wake in the Wire"
		and str(tracked.get("text")).contains("Talk to the Fixer"))

	_state.flags["talked_fixer"] = true
	events = _quests.evaluate()
	_check("talking to the Fixer completes objective 1", _types(events, "objective") == 1)
	_check("tracker advances to objective 2", str(_quests.tracked()["text"]).contains("Cross the wall"))

	_state.hack_terminal("term_gate")
	_state.hack_terminal("term_relay")
	_state.hack_terminal("term_south")
	_state.flags["visited_3d_district_02"] = true
	events = _quests.evaluate()
	_check("hacks + visiting the Archive complete 'Wake in the Wire'", _quests.status("q_wire") == "done")
	_check("completion chains: 'The Archive' unlocks in the same pass", _quests.status("q_archive") == "active")
	_check("reward granted: Phase Boots", _owned_count("upgrade_phase_boots") == 1)
	_check("events report quest_done", _types(events, "quest_done") == 1)
	events = _quests.evaluate()
	_check("evaluating again changes nothing (no duplicate rewards)",
		events.is_empty() and _owned_count("upgrade_phase_boots") == 1)

	# ------------------------------------------------------------ progress + rewards
	var streets: Dictionary = _quests.get_def("q_streets")
	_state.flags["kills"] = 3
	_check("counter objective shows progress (3/5)",
		_quests.objective_text(streets["objectives"][0]).ends_with("(3/5)"))
	_state.flags["kills"] = 5
	_quests.evaluate()
	_check("5 kills complete 'Clear the Streets' and grant Hardened Plating",
		_quests.status("q_streets") == "done" and _owned_count("upgrade_plating") == 1)

	for id: String in ["fragment_01", "fragment_02", "fragment_03", "fragment_04"]:
		_state.add_item(id)
	_quests.evaluate()
	_check("4 of 5 fragments: quest still open",
		_quests.status("q_memories") == "active"
		and _quests.objective_text(_quests.get_def("q_memories")["objectives"][0]).ends_with("(4/5)"))
	_state.add_item("fragment_05")
	_quests.evaluate()
	_check("5th fragment completes 'Lost Memories' (Strike Edge)",
		_quests.status("q_memories") == "done" and _owned_count("upgrade_strike_edge") == 1)

	_state.hack_terminal("node_hub")
	_state.hack_terminal("node_d01")
	_state.hack_terminal("node_d02")
	_quests.evaluate()
	_check("3 of 4 data nodes: 'Open Nodes' still open", _quests.status("q_nodes") == "active")
	_state.hack_terminal("node_d03")
	_quests.evaluate()
	_check("4th node completes 'Open Nodes' (Signal Cell)",
		_quests.status("q_nodes") == "done" and _owned_count("upgrade_signal_cell") == 1)

	# ------------------------------------------------------------ upgrade effects
	_check("Phase Boots: +15% speed", is_equal_approx(_items.speed_multiplier(), 1.15))
	_check("Strike Edge: melee 1 -> 2", _items.strike_damage() == 2)
	_check("Plating: 20 damage -> 15", _items.physical_damage(20) == 15)
	_check("Signal Cell: 15 signal damage -> 11", _items.signal_damage(15) == 11)
	_check("no Pulse Core yet: pulse 2 dmg / 0.9 s", _items.pulse_damage() == 2 and is_equal_approx(_items.pulse_cooldown(), 0.9))

	# ------------------------------------------------------------ save / load
	_state.save_game()
	_state.reset()
	_check("a reset wipes the quest log", _quests.status("q_wire") == "locked")
	_check("...and the upgrades", _owned_count("upgrade_phase_boots") == 0)
	_state.load_game()
	_check("loading restores quest progress", _quests.status("q_wire") == "done" and _quests.status("q_archive") == "active")
	_check("loading restores upgrades", _owned_count("upgrade_phase_boots") == 1 and _owned_count("upgrade_strike_edge") == 1)
	_check("no reward re-grants after a load", _quests.evaluate().is_empty() and _owned_count("upgrade_plating") == 1)

	# ------------------------------------------------------------ the hub: hidden cache, node, journal, tracker
	var hub: Node = await _load_scene("res://scenes3d/hub_3d.tscn")
	_check("hub: HUD tracker names the active main quest", hub._quest_label.text.contains("The Archive"))
	_check("hub: journal action registered", InputMap.has_action("journal"))
	var layers: Node = hub._layers
	_check("hub: cache room walls are real in Physical, absent in the Grid",
		layers.is_wall(0, 36, 24) and not layers.is_wall(1, 36, 24))
	var cache: Node = null
	var data_node: Node = null
	for n: Node in get_nodes_in_group("interactable3d"):
		var global_name: String = n.get_script().get_global_name()
		if global_name == "Pickup3D" and n.item_id == "upgrade_pulse_core":
			cache = n
		if global_name == "Terminal3D" and n.terminal_id == "node_hub":
			data_node = n
	_check("hub: hidden cache exists, Grid-only, holds the Pulse Core", cache != null and cache.realm == 2)
	_check("hub: data node exists with a Datachip reward", data_node != null and data_node.reward_item == "chip_hub")
	var cache_cell: Vector3 = layers.cell_to_world(Vector2(38, 24))
	_check("hub: cache sits inside the ring", cache.global_position.distance_to(cache_cell) < 0.1)

	cache.interact(hub._player)
	_check("picking up the cache: Pulse Core owned, found_cache flag set",
		_owned_count("upgrade_pulse_core") == 1 and _state.flags.get("found_cache", false))
	_check("Pulse Core: pulse 3 dmg / 0.6 s", _items.pulse_damage() == 3 and is_equal_approx(_items.pulse_cooldown(), 0.6))
	hub._poll_quests()
	_check("'Whispers in the Plaza' completes", _quests.status("q_cache") == "done")
	_check("a notice was queued/shown for the quest events", hub._notice.text != "")
	var reward_line: String = data_node._grant_reward()
	_check("data node reward line + item", reward_line == "Recovered: Plaza Datachip." and _owned_count("chip_hub") == 1)
	data_node._grant_reward()
	_check("data node reward is not duplicated", _owned_count("chip_hub") == 1)

	hub._journal.open()
	_check("journal opens and pauses the game", hub._journal.is_open() and paused)
	var quests_text: String = _labels(hub._journal._quests_box)
	_check("journal: lists completed main quest", quests_text.contains("Wake in the Wire  (complete)"))
	_check("journal: lists the active main quest with its checklist",
		quests_text.contains("The Archive") and quests_text.contains("[ ] Hack the terminal at the end of the shelf hall"))
	_check("journal: side quest progress is shown", _labels(hub._journal._quests_box).contains("Whispers in the Plaza"))
	_check("journal: memories tab shows recovered memory text",
		_labels(hub._journal._memories_box).contains("hidden cache") or _labels(hub._journal._memories_box).contains("Pulse Core"))
	var items_text: String = _labels(hub._journal._items_box)
	_check("journal: owned upgrades shown, the unfound one (Echo Core) hidden as ???",
		items_text.contains("[+] Pulse Core") and items_text.contains("[+] Phase Boots")
		and items_text.contains("[ ] ???") and not items_text.contains("Echo Core"))
	hub._journal.close()
	_check("journal closes and unpauses", not hub._journal.is_open() and not paused)

	# ------------------------------------------------------------ District 01: kills, talk flag, strike edge
	var d01: Node = await _load_scene("res://scenes3d/district_01_3d.tscn")
	_state.flags.erase("talked_fixer")
	var fixer: Node = null
	for n: Node in get_nodes_in_group("interactable3d"):
		if n.get_script().get_global_name() == "Npc3D" and n.speaker == "FIXER":
			fixer = n
	fixer.interact(d01._player)
	_check("talking to the Fixer sets the quest flag", _state.flags.get("talked_fixer", false))
	root.get_node("Dialogue").is_active = false

	d01._swap()  # into the Grid, where the drones live
	var drone: Node3D = null
	for n: Node in get_nodes_in_group("enemy3d"):
		if n.get_script().get_global_name() == "Drone3D":
			drone = n as Node3D
			break
	for n: Node in get_nodes_in_group("enemy3d"):
		n.speed = 0.0
	d01._player.global_position = drone.global_position + Vector3(-1.8, 0.0, 0.0)
	d01._player._facing = Vector3(1, 0, 0)
	d01._player._attack_timer = 0.0
	d01._player.attack()
	_check("Strike Edge: one melee hit takes a drone from 3 HP to 1", drone._hp == 1)
	var kills_before: int = int(_state.flags.get("kills", 0))
	drone.take_hit(5, drone.global_position + Vector3(-1, 0, 0), "melee")
	_check("destroying a drone adds a kill", int(_state.flags.get("kills", 0)) == kills_before + 1)

	var terminals: int = 0
	var node_d01: Node = null
	for n: Node in get_nodes_in_group("interactable3d"):
		if n.get_script().get_global_name() == "Terminal3D":
			terminals += 1
			if n.terminal_id == "node_d01":
				node_d01 = n
	_check("d01: optional data node exists with the Static Row datachip", node_d01 != null and node_d01.reward_item == "chip_static")

	root.get_texture().get_image().save_png("%s/adventure_d01.png" % _out)
	d01._journal.open()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/adventure_journal.png" % _out)
	d01._journal.close()

	_state.delete_save()
	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	quit(1 if _failed else 0)
