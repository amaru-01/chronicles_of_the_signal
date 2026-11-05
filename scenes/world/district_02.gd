extends District
## District 02 "The Archive": alternate worlds through the shelves, collect three
## keys, race a timed gate, then face the Curator's core and make the final choice.

const OBJECTIVES: Array[Dictionary] = [
	{
		"done": "_arch_done",
		"tiers": [
			"The shelves block the hall. Some of them are only real in one world.",
			"Walk to a shelf wall. If it blocks you, press Space to swap worlds and try again. They alternate.",
			"West wall: cross in the Grid. Middle wall: cross in the real world. Last wall: cross in the Grid. Then hack the terminal at the end of the hall. A drone patrols the Grid in the middle.",
		],
	},
	{
		"done": "_r1_done",
		"tiers": [
			"The next gate needs three keys. Start with the nearest terminal.",
			"One terminal is out in the open in the north-west of the reading rooms.",
			"Hack the terminal in the north-west corner of the reading rooms.",
		],
	},
	{
		"done": "_r2_done",
		"tiers": [
			"A key is locked inside a small room in the south-west.",
			"That room's walls only exist in the Grid. Try the real world.",
			"Press Space to be in the real world, then walk into the south-west room and hack the terminal.",
		],
	},
	{
		"done": "_r3_done",
		"tiers": [
			"The last key is in a room in the south-east. Watch for drones in the Grid.",
			"That room's walls only exist in the real world. Enter through the Grid. Inside the room you can swap back to safety.",
			"Swap to the Grid, go around the drones into the south-east room, then press Space inside it to hide in the real world while you hack.",
		],
	},
	{
		"done": "_wall_done",
		"tiers": [
			"The next gate is on a timer. Find what powers it.",
			"A lever in the Grid, just past the gate, powers it for a short time. The real-world path to the gate is long.",
			"Pull the lever (Grid only), then run. In the real world the shelves force a long winding route. In the Grid the way is straight but drones patrol it. You have 12 seconds.",
		],
	},
	{
		"done": "_core_done",
		"tiers": [
			"The Curator's core is ahead. It only exists in the Grid.",
			"Swap to the Grid and hack the core. The drones stop while you hack, but the timer does not.",
			"Swap to the Grid, reach the core terminal and break the code in 15 seconds. You decide what happens next.",
		],
	},
]


func _objectives() -> Array[Dictionary]:
	return OBJECTIVES


func _ready() -> void:
	super()
	GameState.terminal_hacked.connect(_on_terminal_hacked)


func _arch_done() -> bool:
	return GameState.is_hacked("term_arch1")


func _r1_done() -> bool:
	return GameState.is_hacked("term_r1")


func _r2_done() -> bool:
	return GameState.is_hacked("term_r2")


func _r3_done() -> bool:
	return GameState.is_hacked("term_r3")


func _wall_done() -> bool:
	return _player.global_position.x > 1808.0  # past the timed gate


func _core_done() -> bool:
	return false


func _on_terminal_hacked(id: String) -> void:
	if id == "term_core":
		_finale()


## The reveal and the final choice. Sets flags["ending"] and goes to the end screen.
func _finale() -> void:
	await get_tree().process_frame
	if Dialogue.is_active:
		await Dialogue.finished
	Dialogue.start("CURATOR", [
		"Welcome back, Runner. You built this Archive.",
		"You were my best courier. You carried the deletions yourself, district by district.",
		"Then you erased your own memory so you could not stop yourself. Clever.",
		"Every memory in this room can be restored with one command. It will take yours with it.",
	] as Array[String])
	await Dialogue.finished
	var options: Array[String] = [
		"Restore the city's memories. Lose my own.",
		"Keep my memories. Leave the Archive sealed.",
	]
	var pick: int = await Dialogue.ask("CURATOR", "What will you do?", options)
	GameState.flags["ending"] = "restore" if pick == 0 else "keep"
	SceneManager.change_scene("res://ui/end_screen.tscn")
