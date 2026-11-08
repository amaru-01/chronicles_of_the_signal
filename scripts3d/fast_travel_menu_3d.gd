class_name FastTravelMenu3D
extends CanvasLayer
## T opens a list of districts whose beacon you have touched (the hub is always there).
## Picking one travels there and respawns you at that district's last beacon.

var _list: VBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.05, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "FAST TRAVEL"
	title.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	column.add_child(_list)
	var footer := Label.new()
	footer.text = "Touch a beacon in a district to unlock it.   [T] / [ESC] CLOSE"
	footer.add_theme_font_size_override("font_size", 13)
	footer.modulate = Color(1, 1, 1, 0.6)
	column.add_child(footer)


func is_open() -> bool:
	return visible


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	var first: Button = null
	for district_id: String in WorldMap3D.DISTRICTS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(380, 0)
		var here: bool = district_id == GameState.current_district
		var unlocked: bool = WorldMap3D.is_unlocked(district_id)
		if here:
			button.text = "%s  (you are here)" % WorldMap3D.title_of(district_id)
			button.disabled = true
		elif unlocked:
			button.text = WorldMap3D.title_of(district_id)
			button.pressed.connect(_travel.bind(district_id))
			if first == null:
				first = button
		else:
			button.text = "???  (no beacon found yet)"
			button.disabled = true
		_list.add_child(button)
	visible = true
	get_tree().paused = true
	if first:
		first.grab_focus.call_deferred()


func close() -> void:
	visible = false
	get_tree().paused = false


func _travel(district_id: String) -> void:
	Audio.sfx("click")
	close()
	WorldMap3D.travel(district_id, "")


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("fast_travel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
