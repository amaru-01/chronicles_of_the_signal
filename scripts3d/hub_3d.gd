class_name Hub3D
extends District3D
## Vantage Plaza: the safe hub. Three ways out: Static Row (west), The Archive (east, sealed
## until the first gate in Static Row is open) and the Relay Tower (north, not built yet).
## No enemies here. The central beacon is the always-available fast-travel point.

const HUB_MAP: String = "res://scenes3d/maps/hub.txt"


func _init() -> void:
	district_id = WorldMap3D.HUB
	map_path = HUB_MAP


func _spawn_cells() -> Dictionary:
	return {
		"start": Vector2(22, 22),
		"from_d01": Vector2(6, 14),
		"from_d02": Vector2(37, 14),
		"from_d03": Vector2(6, 22),
		"from_tower": Vector2(22, 6),
	}


func _populate() -> void:
	var fixer := Npc3D.new()
	fixer.name = "Fixer"
	fixer.realm = Interactable3D.Realm.PHYSICAL
	fixer.speaker = "FIXER"
	fixer.lines = [
		"Vantage Plaza. The last place in the lower city the Signal still reaches.",
		"Static Row is west. The Archive is east, but its gate is sealed until you open the first lock in Static Row.",
	] as Array[String]
	fixer.question = "Need anything?"
	fixer.options = ["How do I travel quickly?", "Any rumours?", "What is north?", "Never mind"] as Array[String]
	fixer.answers = [
		"Touch a beacon in a district and it joins your list. Press T anywhere to jump between them. Press Tab for your journal.",
		"Some of the plaza's walls only exist in the real world. Look in the south-east corner. From the Grid.",
		"The Relay Tower. Sealed. Whatever the Curator keeps up there, it is not ready for visitors.",
	] as Array[String]
	_place(fixer, Vector2(18, 20))

	_add_beacon(Vector2(22, 18))

	# Side content: an optional data node, and a cache sealed behind real-world-only walls
	# (the ring at the south-east corner of the map). Enter it through the Grid.
	var node := Terminal3D.new()
	node.terminal_id = "node_hub"
	node.attempts = 3
	node.time_limit = 25.0
	node.reward_item = "chip_hub"
	_place(node, Vector2(6, 24))
	var cache := Pickup3D.new()
	cache.item_id = "upgrade_pulse_core"
	cache.realm = Interactable3D.Realm.DIGITAL
	cache.set_flag = "found_cache"
	cache.memory_lines = ["A hidden cache, sealed off from the real world.", "A scrap of paper: \"For whoever walks both sides. - F\""] as Array[String]
	_place(cache, Vector2(38, 24))

	_add_exit(Vector2(3, 14), "3d_district_01", "from_hub", "STATIC ROW")
	_add_exit(
		Vector2(40, 14), "3d_district_02", "from_hub", "THE ARCHIVE", "term_gate",
		["The Archive gate is sealed.", "Open the first gate in Static Row, then come back."] as Array[String]
	)
	_add_exit(Vector2(3, 22), "3d_district_03", "from_hub", "NEON MARKET")
	_add_exit(
		Vector2(22, 3), "3d_relay_tower", "from_hub", "RELAY TOWER", "term_core",
		["The Relay Tower is sealed.", "The key is the Curator's core, deep in the Archive."] as Array[String],
		Color(1.0, 0.25, 0.3)
	)


func _objectives() -> Array[Dictionary]:
	return [
		{
			"done": func() -> bool: return GameState.is_hacked("term_gate"),
			"tiers": [
				"Static Row, the west exit, is where the trail starts.",
				"Walk to the west exit and open the first gate there.",
				"Take the west exit to Static Row, cross the wall in the Grid, and hack the terminal.",
			],
		},
		{
			"done": func() -> bool: return false,
			"tiers": ["The Archive is open. Take the east exit."],
		},
	]
