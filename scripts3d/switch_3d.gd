class_name Switch3D
extends Interactable3D
## A lever. Pulling it marks `switch_id` as hacked, so any Door3D listing that id opens.
## With `duration` > 0 it switches itself off again (a timed puzzle). Normally placed in
## the Digital world only, so it changes the Physical world from the other side.

const LEVER_TEXTURE: Texture2D = preload("res://assets3d/sprites/lever_3d.png")

@export var switch_id: String = "sw_01"
## 0 = stays on.
@export var duration: float = 0.0

var _sprite: Sprite3D


func _ready() -> void:
	prompt_text = "PULL"
	# A timed switch never starts on (e.g. after a reload mid-timer).
	if duration > 0.0:
		GameState.transient_ids[switch_id] = true
		GameState.hacked_terminals.erase(switch_id)
	super()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	shape.position.y = 0.8
	add_child(shape)
	_sprite = make_billboard(LEVER_TEXTURE, 2)
	add_child(_sprite)
	GameState.terminal_reset.connect(func(_id: String) -> void: _update_look())
	_update_look()


func interact(_player: Node3D) -> void:
	if GameState.is_hacked(switch_id):
		Dialogue.start("SWITCH", ["Already on."])
		return
	Audio.sfx("lever")
	GameState.hack_terminal(switch_id)
	_update_look()
	if duration > 0.0:
		Dialogue.start("SWITCH", ["Power surge! It will hold for %d seconds." % int(duration)])
		get_tree().create_timer(duration).timeout.connect(_turn_off)
	else:
		Dialogue.start("SWITCH", ["Something clicks in the real world."])


func _turn_off() -> void:
	GameState.unhack_terminal(switch_id)
	_update_look()


func _update_look() -> void:
	_sprite.frame = 1 if GameState.is_hacked(switch_id) else 0
