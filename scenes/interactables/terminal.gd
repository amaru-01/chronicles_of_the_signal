class_name Terminal
extends Interactable
## A hackable terminal. Interacting starts the timed code-breaker minigame.

const HACK_SCENE: PackedScene = preload("res://ui/hack_minigame.tscn")

@export var terminal_id: String = "terminal_01"
@export_group("Minigame")
@export_range(5, 6) var word_length: int = 6
@export var attempts: int = 4
@export var time_limit: float = 30.0
## Signal integrity lost when the hack fails.
@export var fail_damage: int = 20

var _busy: bool = false

@onready var _screen: Sprite2D = $Body


func _ready() -> void:
	super()
	_update_look()


func interact(_player: Node2D) -> void:
	if _busy:
		return
	if GameState.is_hacked(terminal_id):
		Dialogue.start("TERMINAL", ["Already hacked. The signal is open."])
		return
	_busy = true
	var game: HackMinigame = HACK_SCENE.instantiate()
	game.word_length = word_length
	game.max_attempts = attempts
	game.time_limit = time_limit
	get_tree().root.add_child(game)
	var result: int = await game.finished
	_busy = false
	match result:
		HackMinigame.Result.SUCCESS:
			GameState.hack_terminal(terminal_id)
			_update_look()
			Audio.sfx("hack_ok")
			Dialogue.start("TERMINAL", ["Access granted.", "Somewhere nearby, a lock gives way."])
		HackMinigame.Result.FAIL:
			Audio.sfx("hack_fail")
			Dialogue.start("TERMINAL", ["Trace detected. Signal integrity -%d%%." % fail_damage])
			GameState.damage_signal(fail_damage)


func _update_look() -> void:
	_screen.frame = 1 if GameState.is_hacked(terminal_id) else 0
