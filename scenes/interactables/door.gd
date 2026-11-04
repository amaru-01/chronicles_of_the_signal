class_name Door
extends Interactable
## A door that stays solid until `required_terminal` has been hacked.

@export var required_terminal: String = "terminal_01"

var _opened: bool = false

@onready var _blocker: StaticBody2D = $Blocker
@onready var _blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D
@onready var _body: ColorRect = $Body


func _ready() -> void:
	# The wall only collides in the world(s) the door exists in.
	match realm:
		Realm.PHYSICAL:
			_blocker.collision_layer = 1 << 1
		Realm.DIGITAL:
			_blocker.collision_layer = 1 << 2
		_:
			_blocker.collision_layer = (1 << 1) | (1 << 2)
	_opened = GameState.is_hacked(required_terminal)
	super()
	GameState.terminal_hacked.connect(_on_terminal_hacked)
	_apply_state()


func interact(_player: Node2D) -> void:
	if _opened:
		return
	Dialogue.start("DOOR", ["Locked.", "The access panel is dead. It needs a hacked terminal."])


func blocks_swap(target: GameState.WorldLayer, player_rect: Rect2) -> bool:
	if _opened or not exists_in(target):
		return false
	var size: Vector2 = (_blocker_shape.shape as RectangleShape2D).size
	var door_rect := Rect2(_blocker_shape.global_position - size / 2.0, size)
	return door_rect.intersects(player_rect)


func _on_terminal_hacked(terminal_id: String) -> void:
	if terminal_id == required_terminal:
		_opened = true
		_apply_state()


func _on_realm_changed(_active: bool) -> void:
	if is_node_ready():
		_apply_state()


func _apply_state() -> void:
	_blocker_shape.set_deferred("disabled", _opened or not is_in_current_world)
	_body.visible = not _opened
	if _opened:
		prompt_text = "Open"
