class_name Switch
extends Interactable
## A lever. Turning it on marks `switch_id` as hacked, so any Door that lists the
## id opens. With `duration` > 0 it turns itself off again after that many
## seconds (a timed puzzle). Typically placed in the Digital world only, so it
## changes the Physical world from the other side.

@export var switch_id: String = "switch_01"
## 0 = stays on forever.
@export var duration: float = 0.0

var _timer: SceneTreeTimer

@onready var _body: Sprite2D = $Body


func _ready() -> void:
	# A timed switch never starts on (e.g. after a reload mid-timer).
	if duration > 0.0:
		GameState.transient_ids[switch_id] = true
		GameState.hacked_terminals.erase(switch_id)
	super()
	GameState.terminal_reset.connect(func(_id: String) -> void: _update_look())
	_update_look()


func interact(_player: Node2D) -> void:
	if GameState.is_hacked(switch_id):
		Dialogue.start("SWITCH", ["Already on."])
		return
	Audio.sfx("lever")
	GameState.hack_terminal(switch_id)
	_update_look()
	if duration > 0.0:
		Dialogue.start("SWITCH", ["Power surge! It will hold for %d seconds." % int(duration)])
		_timer = get_tree().create_timer(duration)
		_timer.timeout.connect(_turn_off)
	else:
		Dialogue.start("SWITCH", ["Something clicks in the real world."])


func _turn_off() -> void:
	GameState.unhack_terminal(switch_id)
	_update_look()


func _update_look() -> void:
	_body.frame = 1 if GameState.is_hacked(switch_id) else 0
