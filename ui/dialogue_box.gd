extends CanvasLayer
## Typewriter dialogue box. Registered as the "Dialogue" autoload.
##
## Usage: Dialogue.start("NAME", ["line one", "line two"])
## Press the interact action to finish a line, then to advance.

signal finished

const CHARS_PER_SECOND: float = 60.0

var is_active: bool = false

var _lines: Array[String] = []
var _index: int = 0
var _opened_frame: int = -1
var _tween: Tween

@onready var _panel: Control = $Panel
@onready var _speaker: Label = $Panel/Margin/VBox/Speaker
@onready var _text: Label = $Panel/Margin/VBox/Text


func _ready() -> void:
	_panel.visible = false


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


func _show_line() -> void:
	_text.text = _lines[_index]
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / CHARS_PER_SECOND)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not event.is_action_pressed("interact"):
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
