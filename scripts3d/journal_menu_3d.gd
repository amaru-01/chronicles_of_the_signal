class_name JournalMenu3D
extends CanvasLayer
## Tab opens the journal: quests (with checklists), memories you have recovered, and the
## items / upgrades you own. The game pauses while it is open.

const PAGE_SIZE: Vector2 = Vector2(780, 400)

var _tabs: TabContainer
var _quests_box: VBoxContainer
var _memories_box: VBoxContainer
var _items_box: VBoxContainer


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.05, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "JOURNAL"
	title.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_tabs = TabContainer.new()
	_tabs.custom_minimum_size = PAGE_SIZE
	column.add_child(_tabs)
	_quests_box = _add_page("QUESTS")
	_memories_box = _add_page("MEMORIES")
	_items_box = _add_page("ITEMS & UPGRADES")

	var footer := Label.new()
	footer.text = "[TAB] / [ESC] CLOSE"
	footer.add_theme_font_size_override("font_size", 13)
	footer.modulate = Color(1, 1, 1, 0.6)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer)


func is_open() -> bool:
	return visible


func open() -> void:
	if get_tree().paused:
		return  # another menu (pause, fast travel) already owns the game
	refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("journal") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: Key = (event as InputEventKey).physical_keycode
		if key == KEY_Q or key == KEY_LEFT:
			_tabs.current_tab = posmod(_tabs.current_tab - 1, _tabs.get_tab_count())
		elif key == KEY_R or key == KEY_RIGHT:
			_tabs.current_tab = posmod(_tabs.current_tab + 1, _tabs.get_tab_count())


## Rebuild every page from the current game state.
func refresh() -> void:
	_fill_quests()
	_fill_memories()
	_fill_items()


func _add_page(page_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(PAGE_SIZE.x - 40.0, 0)
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	return box


func _clear(box: VBoxContainer) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _label(box: VBoxContainer, text: String, color: Color = Color.WHITE, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(PAGE_SIZE.x - 60.0, 0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	return label


func _fill_quests() -> void:
	_clear(_quests_box)
	var any: bool = false
	for kind: String in ["main", "side"]:
		var header_shown: bool = false
		for quest: Dictionary in Quests3D.defs():
			if quest["kind"] != kind:
				continue
			var status: String = Quests3D.status(quest["id"])
			if status == "locked":
				continue
			if not header_shown:
				header_shown = true
				_label(_quests_box, "MAIN QUESTS" if kind == "main" else "SIDE QUESTS", Color(1.0, 0.85, 0.2), 14)
			any = true
			var done: bool = status == "done"
			_label(_quests_box, quest["title"] + ("  (complete)" if done else ""),
				Color(0.5, 0.6, 0.6) if done else Color(0.2, 0.95, 1.0), 18)
			if not done:
				_label(_quests_box, str(quest["summary"]), Color(0.75, 0.75, 0.85), 14)
			var objectives: Array = quest["objectives"]
			for i: int in objectives.size():
				var finished: bool = Quests3D.objective_done(quest["id"], i)
				if done and not finished:
					continue
				_label(_quests_box, ("  [x] " if finished else "  [ ] ") + Quests3D.objective_text(objectives[i]),
					Color(0.5, 0.75, 0.55) if finished else Color.WHITE, 15)
	if not any:
		_label(_quests_box, "No quests yet. Talk to people and explore.", Color(0.7, 0.7, 0.8))


func _fill_memories() -> void:
	_clear(_memories_box)
	var found: int = 0
	for item_id: String in GameState.inventory:
		var key: String = "memory_" + item_id
		if GameState.flags.has(key):
			found += 1
			_label(_memories_box, Items3D.name_of(item_id), Color(0.9, 0.4, 1.0), 17)
			_label(_memories_box, str(GameState.flags[key]), Color(0.85, 0.85, 0.95), 14)
	if found == 0:
		_label(_memories_box, "You remember nothing yet. Memory fragments glow in the Grid.", Color(0.7, 0.7, 0.8))


func _fill_items() -> void:
	_clear(_items_box)
	_label(_items_box, "UPGRADES", Color(1.0, 0.85, 0.2), 14)
	for upgrade: String in Items3D.UPGRADES:
		if Items3D.owned(upgrade):
			_label(_items_box, "[+] %s: %s" % [Items3D.name_of(upgrade), Items3D.desc_of(upgrade)], Color(0.4, 1.0, 0.7), 15)
		else:
			_label(_items_box, "[ ] ???  (not found yet)", Color(0.5, 0.5, 0.6), 15)
	_label(_items_box, "ITEMS", Color(1.0, 0.85, 0.2), 14)
	var any: bool = false
	for item_id: String in GameState.inventory:
		if item_id.begins_with("upgrade_"):
			continue
		any = true
		_label(_items_box, "%s: %s" % [Items3D.name_of(item_id), Items3D.desc_of(item_id)], Color.WHITE, 15)
	if not any:
		_label(_items_box, "Nothing yet.", Color(0.7, 0.7, 0.8))
