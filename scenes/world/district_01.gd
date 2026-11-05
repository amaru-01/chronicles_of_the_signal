extends District
## District 01 "Static Row": walk, swap worlds, talk, hack two gates, reach the exit.

## Puzzle hints (press H). Objectives are checked in order and the first one that
## is not done is hinted. Each press on the same objective gives a more direct tier.
## `done` is a method name on this script; `tiers` go from vague to explicit.
const OBJECTIVES: Array[Dictionary] = [
	{
		"done": "_gate_done",
		"tiers": [
			"A wall splits this district in two. Maybe it is not solid everywhere.",
			"Press Space to swap to the Digital Grid. Some walls only exist in one world.",
			"In the Grid, walk across the middle of the map. Then swap back (Space) and find the terminal near the first gate.",
		],
	},
	{
		"done": "_relay_done",
		"tiers": [
			"The second gate needs more than one key. Look for terminals.",
			"The relay terminal sits in a walled room in the north. Real-world walls, but the Grid has none.",
			"Swap to the Grid, walk into the walled room in the north, and hack the terminal inside. Hack it from either world.",
		],
	},
	{
		"done": "_south_done",
		"tiers": [
			"One more key is still missing for the second gate.",
			"There is a terminal in the south of the middle area.",
			"Walk to the south of the middle area (below the relay room) and hack the terminal there.",
		],
	},
	{
		"done": "_timed_done",
		"tiers": [
			"The last gate has no terminal. Something else must open it.",
			"A lever in the north of the east area only exists in the Grid. Its power does not last.",
			"Swap to the Grid and pull the lever in the north-east. The gate stays open for 12 seconds, so run to it. Drones patrol the Grid, swap back if one gets close.",
		],
	},
	{
		"done": "_exit_done",
		"tiers": [
			"The way out is through the last gate, to the east.",
			"Walk through the open gate and keep going east.",
			"Walk east through the last gate to leave the district.",
		],
	},
]
const VAULT_HINT: String = "Optional: a vault in the south-west has a lever that only exists in the Grid."



func _objectives() -> Array[Dictionary]:
	return OBJECTIVES


func _gate_done() -> bool:
	return GameState.is_hacked("term_gate")


func _relay_done() -> bool:
	return GameState.is_hacked("term_relay")


func _south_done() -> bool:
	return GameState.is_hacked("term_south")


func _timed_done() -> bool:
	return _player.global_position.x > 1424.0  # past the last gate


func _exit_done() -> bool:
	return false


