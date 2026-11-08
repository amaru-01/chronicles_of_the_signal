class_name RelayTower3D
extends District3D
## The Relay Tower: an approach (sentries, stalkers, an enforcer, a terminal booth you enter
## from the Grid) leading through a gate into the Curator's arena. Defeating the Curator
## ends the game: the final Restore / Keep choice happens here.

const ENDING_SCENE: String = "res://ui/end_screen.tscn"

var _boss: Curator3D
var _boss_bar: ProgressBar
var _boss_box: Control
var _hint_shown: Dictionary = {}


func _init() -> void:
	district_id = "3d_relay_tower"
	map_path = "res://scenes3d/maps/relay_tower.txt"


func _theme() -> Dictionary:  # the Curator's seat: crimson and violet
	return {
		"neon": [Color(1.0, 0.15, 0.25), Color(0.7, 0.15, 1.0), Color(1.0, 0.4, 0.1), Color(1.0, 0.2, 0.6)] as Array[Color],
		"ambient": Color(0.32, 0.2, 0.42), "fog": Color(0.16, 0.02, 0.1),
		"fog_digital": Color(0.25, 0.02, 0.22), "moon": Color(0.6, 0.3, 0.6),
	}


func _spawn_cells() -> Dictionary:
	return {"start": Vector2(3, 31), "from_hub": Vector2(3, 31)}


func _populate() -> void:
	# ---- the approach
	_add_enemy(Sentry3D.new(), Vector2(4, 17), Vector3.ZERO)
	_add_enemy(Sentry3D.new(), Vector2(10, 25), Vector3.ZERO)
	_add_enemy(Stalker3D.new(), Vector2(7, 10), Vector3(0.0, 0.0, 5.0))
	_add_enemy(Stalker3D.new(), Vector2(11, 28), Vector3(-4.0, 0.0, 0.0))
	_add_enemy(Enforcer3D.new(), Vector2(6, 28), Vector3(8.0, 0.0, 0.0))
	_add_terminal(Vector2(10.5 * 32.0, 5.5 * 32.0), "term_tower", Interactable3D.Realm.BOTH, 6, 25.0, 3, 25)
	_add_door(Vector2(15.5 * 32.0, 17.0 * 32.0), "term_tower", [], Interactable3D.Realm.BOTH)
	_add_beacon(Vector2(3, 29))
	_add_beacon(Vector2(17, 16))
	_add_exit(Vector2(3, 2), WorldMap3D.HUB, "from_tower", "VANTAGE PLAZA")

	# ---- the arena
	_boss = Curator3D.new()
	_boss.name = "Curator"
	_add_enemy(_boss, Vector2(27, 8), Vector3.ZERO)
	_boss.awakened.connect(_on_boss_awakened)
	_boss.hp_changed.connect(_on_boss_hp)
	_boss.phase_changed.connect(_on_boss_phase)
	_boss.deflected.connect(_on_boss_deflected)
	_boss.defeated.connect(_on_boss_defeated)


func _gps_target() -> Dictionary:
	if not GameState.is_hacked("term_tower"):
		return _goal_px(Vector2(10.5 * 32.0, 5.5 * 32.0), "Gate terminal (via the Grid)")
	if _boss != null and is_instance_valid(_boss) and not GameState.flags.get("curator_defeated", false):
		return _goal(_boss.global_position, "The Curator")
	return {}


func _objectives() -> Array[Dictionary]:
	return [
		{
			"done": func() -> bool: return GameState.is_hacked("term_tower"),
			"tiers": [
				"The gate to the arena is locked from a terminal in the approach.",
				"The terminal is in a booth in the north-west whose walls only exist in the real world.",
				"Swap to the Grid, walk into the north-west booth and hack the terminal. Stalkers walk through walls in the Grid; sentries only fire in the real world.",
			],
		},
		{
			"done": func() -> bool: return GameState.flags.get("curator_defeated", false),
			"tiers": [
				"The Curator lives in one world at a time. You can only hurt it in its own world.",
				"Its bolts also only exist in its world, so swapping dodges them. In its real-world form it is armoured: use the K pulse. In its Grid form melee works too.",
				"Match the Curator's world to hit it, swap away to dodge, hide behind pillars, and pulse it while it is armoured. It flips worlds on a timer.",
			],
		},
	]


# --- boss HUD ----------------------------------------------------------------------------

func _on_boss_awakened() -> void:
	_show_notice("The Curator wakes.")
	_boss_box = VBoxContainer.new()
	var label := Label.new()
	label.text = "THE CURATOR"
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.7))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(label)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(420, 14)
	_boss_bar.show_percentage = false
	_boss_bar.max_value = float(_boss.max_hp)
	_boss_bar.value = float(_boss.max_hp)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.25, 0.6)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_box.add_child(_boss_bar)
	_hud.add_child(_boss_box)
	_pin(_boss_box, 0.5, 0.0, 14.0)
	_boss_box.offset_top += 50.0
	_boss_box.offset_bottom += 50.0


func _on_boss_hp(hp: int, _max_hp: int) -> void:
	if _boss_bar:
		_boss_bar.value = float(hp)


func _on_boss_phase(new_phase: int) -> void:
	_show_notice("The Curator tears at the Signal. Phase %d." % new_phase)
	_fx.pulse(0.8, 0.5)


## Explain why a hit did nothing, once per reason.
func _on_boss_deflected(reason: String) -> void:
	if _hint_shown.has(reason):
		return
	_hint_shown[reason] = true
	match reason:
		"phase":
			_show_notice("It is out of phase. Swap worlds (Space) to match it.")
		"armour":
			_show_notice("Its real-world form is armoured. Use the pulse (K).")
		"dormant":
			_show_notice("It has not noticed you yet.")


# --- the ending ----------------------------------------------------------------------------

func _on_boss_defeated() -> void:
	Quests3D.evaluate()
	GameState.save_game()
	if _boss_box:
		_boss_box.queue_free()
	await get_tree().create_timer(1.6).timeout
	if Dialogue.is_active:
		await Dialogue.finished
	Dialogue.start("CURATOR", [
		"The Signal... is not mine to hold. It never was.",
		"Every memory in the Archive can be restored with one command. It will take yours with it.",
		"Or you can seal it, and keep what you are. Choose, Runner. You built this city's silence. Decide its voice.",
	] as Array[String])
	await Dialogue.finished
	var options: Array[String] = [
		"Restore the city's memories. Lose my own.",
		"Keep my memories. Leave the Archive sealed.",
	]
	var pick: int = await Dialogue.ask("CURATOR", "What will you do?", options)
	GameState.flags["ending"] = "restore" if pick == 0 else "keep"
	GameState.save_game()
	SceneManager.change_scene(ENDING_SCENE)
