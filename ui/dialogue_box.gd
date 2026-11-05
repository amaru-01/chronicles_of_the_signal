extends CanvasLayer
## Typewriter dialogue box. Registered as the "Dialogue" autoload.
##
## Usage: Dialogue.start("NAME", ["line one", "line two"])
## Press the interact action to finish a line, then to advance.
##
## Choices: var i: int = await Dialogue.ask("NAME", "Question?", ["A", "B"])
## Move with W/S or the arrows, pick with E. Returns the chosen index.

signal finished
signal choice_made(index: int)

const CHARS_PER_SECOND: float = 60.0

var is_active: bool = false

var _lines: Array[String] = []
var _index: int = 0
var _opened_frame: int = -1
var _tween: Tween
var _choosing: bool = false

@onready var _panel: Control = $Panel
@onready var _speaker: Label = $Panel/Margin/VBox/Speaker
@onready var _text: Label = $Panel/Margin/VBox/Text
@onready var _choices: VBoxContainer = $Panel/Margin/VBox/Choices
@onready var _hint: Label = $Panel/Margin/VBox/Hint


func _ready() -> void:
	_panel.visible = false
	_choices.visible = false


func start(speaker: String, lines: Array[String]) -> void:
	if is_active or lines.is_empty():
		return
	_speaker.text = speaker
	_lines = lines
	_index = 0
	is_active = true
	_opened_frame = Engine.get_process_frames()  # ignore the key press that opened us
	_panel.visible = true
	_show_line()


## Shows `prompt` with a button per option and waits for a pick. Returns the index.
func ask(speaker: String, prompt: String, options: Array[String]) -> int:
	if is_active or options.is_empty():
		return -1
	_speaker.text = speaker
	_text.text = prompt
	_text.visible_ratio = 1.0
	_hint.text = "[W/S] choose   [E] select"
	is_active = true
	_choosing = true
	_opened_frame = Engine.get_process_frames()
	for i: int in options.size():
		var button := Button.new()
		button.text = options[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void: choice_made.emit(i))
		_choices.add_child(button)
	_choices.visible = true
	_panel.visible = true
	_choices.get_child(0).grab_focus()
	var picked: int = await choice_made
	_choosing = false
	_choices.visible = false
	for child: Node in _choices.get_children():
		child.queue_free()
	_hint.text = "[E] continue"
	is_active = false
	_panel.visible = false
	return picked


func _show_line() -> void:
	Audio.sfx("blip")
	_text.text = _lines[_index]
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / CHARS_PER_SECOND)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not event.is_action_pressed("interact"):
		return
	if _choosing:
		if Engine.get_process_frames() != _opened_frame:
			var focused := get_viewport().gui_get_focus_owner() as BaseButton
			if focused != null:
				get_viewport().set_input_as_handled()
				focused.pressed.emit()
		return
	if Engine.get_process_frames() == _opened_frame:
		return
	get_viewport().set_input_as_handled()
	if _text.visible_ratio < 1.0:
		_tween.kill()
		_text.visible_ratio = 1.0
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()


func _close() -> void:
	is_active = false
	_panel.visible = false
	finished.emit()
