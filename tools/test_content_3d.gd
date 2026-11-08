extends SceneTree
## Dev tool: checks the Phase 5 content. Usage:
##   godot --path . --script res://tools/test_content_3d.gd -- <output_dir>
## Patrol-start regression, Stalker / Sentry / bolts, Neon Market, the Relay Tower, the Curator
## boss (forms, vulnerability, phases, adds, death, ending), the D02 reveal, and the save
## polish (autosave on entry, SAVED signal, corrupt save). Uses a throwaway save file.
## Untyped on purpose (a --script SceneTree compiles before autoloads exist).

var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false
var _out: String = "."
var _state: Node
var _items: GDScript


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_state = root.get_node("GameState")
	_state.save_path = "user://dev_test_save.json"  # never touch the real save
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


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _of_class(group: String, global_name: String) -> Array:
	var found: Array = []
	for n: Node in get_nodes_in_group(group):
		if n.get_script() != null and n.get_script().get_global_name() == global_name:
			found.append(n)
	return found


func _heal() -> void:
	_state.player_health = 100
	_state.player_signal_integrity = 100


func _run() -> void:
	_state.reset()
	_state.delete_save()

	# ---------------------------------------------------------------- regression: patrol start
	var d01: Node = await _load_scene("res://scenes3d/district_01_3d.tscn")
	var drones: Array = _of_class("enemy3d", "Drone3D")
	var spawn_ok: bool = true
	for drone: Node3D in drones:
		# Enemies used to record (0,0,0) as their patrol start because they were positioned
		# after add_child. Every one must patrol around where it was placed.
		if drone._start.length() < 1.0:
			spawn_ok = false
	_check("regression: enemies patrol from their post, not from the world origin", spawn_ok and drones.size() == 3)

	# ---------------------------------------------------------------- autosave on entry + SAVED signal
	_check("autosave on entering a district: Continue would resume here",
		_state.has_save() and _state.saved_district() == "3d_district_01")
	var saved_count: Array = [0]
	_state.saved.connect(func() -> void: saved_count[0] += 1)
	_state.save_game()
	_check("GameState emits `saved` on every save", saved_count[0] == 1)

	# ---------------------------------------------------------------- Neon Market
	_state.reset()
	var d03: Node = await _load_scene("res://scenes3d/district_03_3d.tscn")
	_check("autosave records District 03", _state.saved_district() == "3d_district_03")
	_check("d03: sentries 4, stalkers 3, enforcers 1, drones 2",
		_of_class("enemy3d", "Sentry3D").size() == 4 and _of_class("enemy3d", "Stalker3D").size() == 3
		and _of_class("enemy3d", "Enforcer3D").size() == 1 and _of_class("enemy3d", "Drone3D").size() == 2)
	_check("d03: 2 gates, 1 lever, 3 terminals, 1 fragment, 1 NPC, 3 beacons, 1 exit",
		get_nodes_in_group("doors3d").size() == 2 and _of_class("interactable3d", "Switch3D").size() == 1
		and _of_class("interactable3d", "Terminal3D").size() == 3 and _of_class("interactable3d", "Pickup3D").size() == 1
		and _of_class("interactable3d", "Npc3D").size() == 1 and get_nodes_in_group("beacon3d").size() == 3
		and get_nodes_in_group("exit3d").size() == 1)
	var layers: Node = d03._layers
	_check("d03: lever booth is walled only in the Grid", layers.is_wall(1, 14, 13) and not layers.is_wall(0, 14, 13))
	_check("d03: terminal booth 1 is walled only in the real world", layers.is_wall(0, 27, 6) and not layers.is_wall(1, 27, 6))
	_check("d03: terminal booth 2 is walled only in the Grid", layers.is_wall(1, 27, 19) and not layers.is_wall(0, 27, 19))
	var gate_a: Node = null
	var gate_b: Node = null
	for door: Node in get_nodes_in_group("doors3d"):
		if door.required_terminal == "sw_market":
			gate_a = door
		else:
			gate_b = door
	_state.hack_terminal("term_m1")
	await process_frame
	_check("d03: gate B needs both terminals", not gate_b._open)
	_state.hack_terminal("term_m2")
	await process_frame
	_check("d03: ...and opens with both", gate_b._open)
	_state.hack_terminal("sw_market")
	await process_frame
	_check("d03: gate A opens from the lever", gate_a._open)

	# ---------------------------------------------------------------- Sentry + enemy bolts
	_state.reset()
	var sentries: Array = _of_class("enemy3d", "Sentry3D")
	var sentry: Node3D = sentries[0]  # cell (10, 9)
	for n: Node in get_nodes_in_group("enemy3d"):
		if n != sentry:
			n.speed = 0.0
			n.set_physics_process(false)
	var player: Node3D = d03._player
	player.global_position = sentry.global_position + Vector3(6.0, 0.0, 0.0)
	_check("sentry: clear line of sight at 6 m", sentry._has_line_of_sight(player.global_position))
	_heal()
	var waited: float = 0.0
	while get_nodes_in_group("enemy_bolt3d").is_empty() and waited < 3.0:
		await _wait(0.05)
		waited += 0.05
	_check("sentry fires a bolt when you are in range and in sight", not get_nodes_in_group("enemy_bolt3d").is_empty())
	await _wait(1.3)
	_check("a Physical bolt costs 12 HP", _state.player_health <= 88)

	for b: Node in get_nodes_in_group("enemy_bolt3d"):
		b.queue_free()
	await process_frame
	_heal()
	d03._swap()  # into the Grid
	var bolt: Node3D = (load("res://scripts3d/enemy_bolt_3d.gd") as GDScript).new()
	bolt.world = 0
	bolt.direction = Vector3(-1, 0, 0)
	bolt.position = player.global_position + Vector3(2.0, 0.0, 0.0)
	d03._viewport.add_child(bolt)
	await _wait(0.6)
	_check("a Physical bolt is invisible and harmless while you are in the Grid", not bolt.visible and _state.player_health == 100)
	for b: Node in get_nodes_in_group("enemy_bolt3d"):
		b.queue_free()

	var far_sentry: Node3D = sentries[2]  # cell (18, 26), the gate wall is between it and zone B
	_check("sentry: a wall blocks line of sight",
		not far_sentry._has_line_of_sight(far_sentry.global_position + Vector3(8.0, 0.0, 0.0)))

	# ---------------------------------------------------------------- Stalker phases through walls
	_heal()
	var stalker: Node = (load("res://scripts3d/stalker_3d.gd") as GDScript).new()
	stalker.position = Vector3(45.0, 0.0, 11.0)  # zone B, east of the gate wall (x 40..42)
	d03._viewport.add_child(stalker)
	player.global_position = Vector3(37.0, 0.0, 11.0)  # zone A, 8 m away, wall between
	await _wait(2.0)
	_check("stalker: chases THROUGH the wall (crossed x 40..42)", stalker.position.x < 40.0)
	_check("stalker: contact costs signal integrity", _state.player_signal_integrity < 100)
	d03._swap()  # back to the real world
	await process_frame
	_check("stalker: it is Digital-only (gone after swapping back)", not stalker.active and not stalker.visible)

	# ---------------------------------------------------------------- hub exits
	var hub: Node = await _load_scene("res://scenes3d/hub_3d.tscn")
	var tower_exit: Node = null
	var market_exit: Node = null
	for e: Node in get_nodes_in_group("exit3d"):
		if e.target_district == "3d_relay_tower":
			tower_exit = e
		if e.target_district == "3d_district_03":
			market_exit = e
	_state.reset()
	_check("hub: Neon Market exit is open, Tower exit is sealed", not market_exit.is_locked() and tower_exit.is_locked())
	_state.hack_terminal("term_core")
	_check("hub: the Archive core unlocks the Tower", not tower_exit.is_locked())
	_state.reset()

	# ---------------------------------------------------------------- D02 reveal no longer ends the game
	var d02: Node = await _load_scene("res://scenes3d/district_02_3d.tscn")
	d02._finale()
	await _wait(0.4)
	_check("d02 core: reveals the truth and does NOT end the game",
		root.get_node("Dialogue").is_active and _state.flags.get("curator_revealed", false)
		and not _state.flags.has("ending") and current_scene == d02)
	root.get_node("Dialogue").is_active = false

	# ---------------------------------------------------------------- Relay Tower + the Curator
	_state.reset()
	var tower: Node = await _load_scene("res://scenes3d/relay_tower_3d.tscn")
	_check("tower: approach has 2 sentries, 2 stalkers, 1 enforcer, plus the boss",
		_of_class("enemy3d", "Sentry3D").size() == 2 and _of_class("enemy3d", "Stalker3D").size() == 2
		and _of_class("enemy3d", "Enforcer3D").size() == 1 and _of_class("enemy3d", "Curator3D").size() == 1)
	_check("tower: 1 gate, 1 terminal, 2 beacons, 1 exit",
		get_nodes_in_group("doors3d").size() == 1 and _of_class("interactable3d", "Terminal3D").size() == 1
		and get_nodes_in_group("beacon3d").size() == 2 and get_nodes_in_group("exit3d").size() == 1)
	var boss: Node3D = _of_class("enemy3d", "Curator3D")[0]
	for n: Node in get_nodes_in_group("enemy3d"):
		if n != boss:
			n.queue_free()  # keep the arena to just the boss for the rules below
	await process_frame
	var tplayer: Node3D = tower._player
	var hints: Array = []
	boss.deflected.connect(func(reason: String) -> void: hints.append(reason))

	_heal()
	boss.take_hit(2, boss.global_position + Vector3(-1, 0, 0), "pulse")
	_check("boss: dormant until you come close (hits do nothing)", boss._hp == 30 and hints.has("dormant"))
	tplayer.global_position = boss.global_position + Vector3(0.0, 0.0, 11.0)
	await _wait(0.3)
	_check("boss: wakes when you enter the arena and the health bar appears", boss.awake and tower._boss_bar != null)
	_check("boss: starts in its Physical form", boss.form == 0)

	_heal()
	boss._attack_timer = 99.0
	boss._form_timer = 99.0
	boss.take_hit(1, boss.global_position + Vector3(0, 0, 1), "melee")
	_check("boss (Physical form): armoured, melee does nothing", boss._hp == 30 and hints.has("armour"))
	boss.take_hit(2, boss.global_position + Vector3(0, 0, 1), "pulse")
	_check("boss (Physical form): the pulse hurts it (30 -> 28)", boss._hp == 28)
	tower._swap()  # you are now in the Grid, the boss is in the real world
	boss.take_hit(2, boss.global_position + Vector3(0, 0, 1), "pulse")
	_check("boss: out of phase when you are in the other world", boss._hp == 28 and hints.has("phase"))
	tower._swap()  # back to the real world

	boss._form_timer = 0.05
	await _wait(0.4)
	_check("boss: telegraphs a form change", boss._telegraph > 0.0)
	var hp_mid: int = boss._hp
	boss.take_hit(2, boss.global_position + Vector3(0, 0, 1), "pulse")
	_check("boss: cannot be hurt while it is flipping", boss._hp == hp_mid)
	await _wait(1.1)
	_check("boss: flips to its Digital form", boss.form == 1)
	tower._swap()  # follow it into the Grid
	_heal()
	boss._attack_timer = 99.0
	boss._form_timer = 99.0
	boss.take_hit(1, boss.global_position + Vector3(0, 0, 1), "melee")
	_check("boss (Digital form): melee works when you are in the Grid", boss._hp == hp_mid - 1)

	# bolts only exist in the boss's world
	boss._attack_timer = 0.01
	await _wait(0.3)
	var bolts: Array = get_nodes_in_group("enemy_bolt3d")
	_check("boss fires a fan of 3 bolts in phase 1", bolts.size() == 3)
	var same_world: bool = true
	for b: Node in bolts:
		if b.world != boss.form:
			same_world = false
	_check("boss bolts belong to the boss's current world", same_world)
	for b: Node in bolts:
		b.queue_free()
	boss._attack_timer = 99.0

	# phases and adds
	var stalkers_before: int = _of_class("enemy3d", "Stalker3D").size()
	boss._telegraph = 0.0
	boss._hp = 21
	boss.take_hit(1, boss.global_position + Vector3(0, 0, 1), "melee")
	_check("boss: phase 2 below 21 HP", boss.phase == 2)
	_check("boss: phase 2 summons 2 Stalkers", _of_class("enemy3d", "Stalker3D").size() == stalkers_before + 2)
	boss._telegraph = 0.0
	boss.take_hit(1, boss.global_position + Vector3(0, 0, 1), "melee")
	_check("boss: adds are summoned once per phase", _of_class("enemy3d", "Stalker3D").size() == stalkers_before + 2)
	var enforcers_before: int = _of_class("enemy3d", "Enforcer3D").size()
	boss._telegraph = 0.0
	boss._hp = 11
	boss.take_hit(1, boss.global_position + Vector3(0, 0, 1), "melee")
	_check("boss: phase 3 below 11 HP and summons 2 Enforcers",
		boss.phase == 3 and _of_class("enemy3d", "Enforcer3D").size() == enforcers_before + 2)

	# death and ending
	var defeated_count: Array = [0]
	boss.defeated.connect(func() -> void: defeated_count[0] += 1)
	boss._telegraph = 0.0
	boss._hp = 1
	boss.take_hit(1, boss.global_position + Vector3(0, 0, 1), "melee")
	await _wait(0.2)
	_check("boss: defeated once, flag set, kill counted",
		defeated_count[0] == 1 and _state.flags.get("curator_defeated", false) and int(_state.flags.get("kills_curator", 0)) == 1)
	_check("boss death clears its adds and any bolts", _of_class("enemy3d", "Stalker3D").is_empty()
		and get_nodes_in_group("enemy_bolt3d").is_empty())
	await _wait(2.0)
	_check("the ending dialogue starts, waiting for the Restore / Keep choice",
		root.get_node("Dialogue").is_active and not _state.flags.has("ending"))
	root.get_node("Dialogue").is_active = false

	# ---------------------------------------------------------------- echo core
	_state.reset()
	var d01b: Node = await _load_scene("res://scenes3d/district_01_3d.tscn")
	_state.add_item("upgrade_echo_core")
	_state.player_signal_integrity = 50
	d01b._regen_timer = 0.0
	d01b._regenerate_signal(0.1)
	_check("Echo Core: signal integrity regenerates (+2 per tick)", _state.player_signal_integrity == 52)
	_state.inventory.clear()
	d01b._regen_timer = 0.0
	d01b._regenerate_signal(0.1)
	_check("...and only with the upgrade", _state.player_signal_integrity == 52)

	# ---------------------------------------------------------------- corrupt save
	var file := FileAccess.open(_state.save_path, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	_check("a corrupt save fails to load cleanly", not _state.load_game())
	var title: Node = (load("res://ui/title_screen.tscn") as PackedScene).instantiate()
	current_scene.queue_free()
	root.add_child(title)
	current_scene = title
	await process_frame
	await process_frame
	var cont: Button = title.get_node("Center/VBox/ContinueButton")
	_check("title: Continue is offered for the unreadable save", cont.visible)
	cont.pressed.emit()
	await _wait(0.3)
	_check("title: pressing Continue on a corrupt save hides the dead button instead of hanging",
		not cont.visible and current_scene == title)

	root.get_texture().get_image().save_png("%s/content_title.png" % _out)
	_state.delete_save()
	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	quit(1 if _failed else 0)
