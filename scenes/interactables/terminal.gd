class_name Terminal
extends Interactable
## A hackable terminal. Phase C replaces the instant hack with a minigame.

@export var terminal_id: String = "terminal_01"

@onready var _screen: ColorRect = $Body


func _ready() -> void:
	super()
	_update_look()


func interact(_player: Node2D) -> void:
	if GameState.is_hacked(terminal_id):
		Dialogue.start("TERMINAL", ["Already hacked. The signal is open."])
		return
	GameState.hack_terminal(terminal_id)
	_update_look()
	Dialogue.start("TERMINAL", ["Access granted.", "Somewhere nearby, a lock gives way."])


func _update_look() -> void:
	_screen.color = Color("39ff14") if GameState.is_hacked(terminal_id) else Color("ff9d00")
