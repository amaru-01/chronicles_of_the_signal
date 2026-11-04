class_name HackMinigame
extends CanvasLayer
## Timed code-breaker. One of the listed codes is the key. Picking a code
## reveals its "likeness": how many letters sit in the same position as the
## key. Find the key before you run out of attempts or time.
##
## Usage: instantiate, set the exported vars, add to the tree, await `finished`.

signal finished(result: Result)

enum Result { SUCCESS, FAIL, ABORT }

const WORDS: Dictionary = {
	5: ["PROXY", "VIRUS", "LOGIC", "CYBER", "PIXEL", "CRASH", "QUERY", "ROUTE",
		"TOKEN", "BYTES", "NODES", "PATCH", "STACK", "CLOCK", "SHELL", "INPUT"],
	6: ["SIGNAL", "CIPHER", "BINARY", "KERNEL", "MATRIX", "ROUTER", "SOCKET", "PACKET",
		"BUFFER", "DAEMON", "ACCESS", "SHADOW", "NEURAL", "VECTOR", "GLITCH", "STATIC"],
}

const COLOR_OK: Color = Color(0.22, 1.0, 0.08)
const COLOR_BAD: Color = Color(1.0, 0.18, 0.3)
const COLOR_TITLE: Color = Color(0.0, 0.94, 1.0)

var word_length: int = 6
var word_count: int = 8
var max_attempts: int = 4
var time_limit: float = 30.0

var _key: String = ""
var _words: Array[String] = []
var _buttons: Array[Button] = []
var _attempts_left: int = 0
var _time_left: float = 0.0
var _done: bool = false
var _log_lines: Array[String] = []

@onready var _title: Label = $Dim/Center/Panel/Margin/VBox/Title
@onready var _time_label: Label = $Dim/Center/Panel/Margin/VBox/Status/TimeLabel
@onready var _attempts_label: Label = $Dim/Center/Panel/Margin/VBox/Status/AttemptsLabel
@onready var _bar: ProgressBar = $Dim/Center/Panel/Margin/VBox/TimeBar
@onready var _grid: GridContainer = $Dim/Center/Panel/Margin/VBox/Body/Words
@onready var _log: Label = $Dim/Center/Panel/Margin/VBox/Body/Log


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	GameState.minigame_active = true

	var pool: Array = (WORDS.get(word_length, WORDS[6]) as Array).duplicate()
	pool.shuffle()
	for i: int in mini(word_count, pool.size()):
		_words.append(pool[i] as String)
	_key = _words.pick_random()

	_attempts_left = max_attempts
	_time_left = time_limit
	_bar.max_value = time_limit
	_bar.value = time_limit

	for word: String in _words:
		var button := Button.new()
		button.text = word
		button.custom_minimum_size = Vector2(190, 44)
		button.pressed.connect(_on_word_pressed.bind(word, button))
		_grid.add_child(button)
		_buttons.append(button)
	_buttons[0].grab_focus()
	_log.text = "> awaiting input..."
	_refresh_status()


func _process(delta: float) -> void:
	if _done:
		return
	_time_left = maxf(0.0, _time_left - delta)
	_bar.value = _time_left
	_refresh_status()
	if _time_left <= 0.0:
		_end(Result.FAIL, "TIME OUT", COLOR_BAD)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_end(Result.ABORT, "", COLOR_TITLE, 0.0)


func _on_word_pressed(word: String, button: Button) -> void:
	if _done:
		return
	button.disabled = true
	_attempts_left -= 1
	var likeness: int = _likeness(word)
	_log_lines.append("> %s  %d/%d" % [word, likeness, word_length])
	_log.text = "\n".join(_log_lines)
	_refresh_status()
	if word == _key:
		_end(Result.SUCCESS, "ACCESS GRANTED", COLOR_OK)
	elif _attempts_left <= 0:
		_end(Result.FAIL, "LOCKED OUT", COLOR_BAD)
	else:
		_focus_next_enabled()


func _likeness(word: String) -> int:
	var count: int = 0
	for i: int in word.length():
		if word[i] == _key[i]:
			count += 1
	return count


func _focus_next_enabled() -> void:
	for button: Button in _buttons:
		if not button.disabled:
			button.grab_focus()
			return


func _refresh_status() -> void:
	_time_label.text = "TIME %04.1f" % _time_left
	_attempts_label.text = "ATTEMPTS %s" % "#".repeat(_attempts_left).rpad(max_attempts, "-")
	var urgent: bool = _time_left < 8.0 and not _done
	_time_label.add_theme_color_override("font_color", COLOR_BAD if urgent else COLOR_TITLE)


func _end(result: Result, message: String, color: Color, delay: float = 1.0) -> void:
	_done = true
	_title.text = message if message != "" else "// DISCONNECTED"
	_title.add_theme_color_override("font_color", color)
	for button: Button in _buttons:
		button.disabled = true
	if delay > 0.0:
		await get_tree().create_timer(delay, true).timeout
	get_tree().paused = false
	GameState.minigame_active = false
	finished.emit(result)
	queue_free()
