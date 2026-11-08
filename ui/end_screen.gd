extends Control
## End of the game: shows the ending and a summary, and offers Play again / Main menu.
## The UI is built in code so the scene file stays tiny.

const TITLE_SCENE: String = "res://ui/title_screen.tscn"
const INTRO_SCENE: String = "res://scenes3d/intro_3d.tscn"


func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.01, 0.05, 1)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "SIGNAL RESTORED" if GameState.flags.get("ending", "") != "keep" else "SIGNAL SEALED"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0, 0.94, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var story := Label.new()
	story.text = _ending_text()
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(story)

	var stats := Label.new()
	stats.text = "Memory fragments: %d    Terminals hacked: %d    Reboots: %d" % [
		GameState.inventory.size(), _count_terminals(), GameState.deaths
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	box.add_child(stats)

	var again := _make_button("Play again", func() -> void:
		GameState.reset()
		GameState.delete_save()
		SceneManager.change_scene(INTRO_SCENE)
	)
	var menu := _make_button("Main menu", func() -> void: SceneManager.change_scene(TITLE_SCENE))
	box.add_child(again)
	box.add_child(menu)
	again.grab_focus()

	GameState.delete_save()  # finished: Continue should not resume a completed run
	Audio.play_music("title")


func _ending_text() -> String:
	match str(GameState.flags.get("ending", "")):
		"restore":
			return "The Archive opens. Every deleted memory flows back into the city.
You forget your own name, and for the first time, the Signal is quiet and whole."
		"keep":
			return "You seal the Archive and keep what you are. The city stays silent.
Somewhere, the Curator keeps deleting. You are the only one who remembers why."
	return "The Signal is still out there."


## Memory fragments only (the inventory also holds datachips and upgrades).
func _count_fragments() -> int:
	var count: int = 0
	for id: String in GameState.inventory:
		if id.begins_with("fragment_"):
			count += 1
	return count


## Real terminals only; levers (ids starting "sw_") are not counted.
func _count_terminals() -> int:
	var count: int = 0
	for id: String in GameState.hacked_terminals:
		if not id.begins_with("sw_"):
			count += 1
	return count


func _make_button(label: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(240, 44)
	button.pressed.connect(on_press)
	return button
