class_name Door
extends Interactable
## A door that stays solid until `required_terminal` AND every id in
## `extra_required` are hacked/switched on. If one of them turns itself off again
## (a timed Switch) the door closes, but never on top of the player.

@export var required_terminal: String = "terminal_01"
@export var extra_required: Array[String] = []

var _opened: bool = false

@onready var _blocker: StaticBody2D = $Blocker
@onready var _blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D
@onready var _body: Sprite2D = $Body


func _ready() -> void:
	set_process(false)
	# The wall only collides in the world(s) the door exists in.
	match realm:
		Realm.PHYSICAL:
			_blocker.collision_layer = 1 << 1
		Realm.DIGITAL:
			_blocker.collision_layer = 1 << 2
		_:
			_blocker.collision_layer = (1 << 1) | (1 << 2)
	_opened = _all_met()
	super()
	GameState.terminal_hacked.connect(_on_terminal_hacked)
	GameState.terminal_reset.connect(_on_terminal_hacked)
	_apply_state()


func interact(_player: Node2D) -> void:
	if _opened:
		return
	var missing: int = _missing_count()
	if missing > 1:
		Dialogue.start("DOOR", ["Locked.", "%d keys are still missing." % missing])
	else:
		Dialogue.start("DOOR", ["Locked.", "The access panel is dead. It needs one more key."])


func blocks_swap(target: GameState.WorldLayer, player_rect: Rect2) -> bool:
	if _opened or not exists_in(target):
		return false
	return _door_rect().intersects(player_rect)


func _all_met() -> bool:
	return _missing_count() == 0


func _missing_count() -> int:
	var missing: int = 0 if GameState.is_hacked(required_terminal) else 1
	for id: String in extra_required:
		if not GameState.is_hacked(id):
			missing += 1
	return missing


func _on_terminal_hacked(_terminal_id: String) -> void:
	if _all_met() and not _opened:
		_opened = true
		Audio.sfx("door")
		_apply_state()
	elif not _all_met() and _opened:
		set_process(true)  # close as soon as the doorway is clear


func _process(_delta: float) -> void:
	if _all_met():
		set_process(false)
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and _door_rect().intersects(player.get_rect().grow(4.0)):
		return  # never close on top of the player
	_opened = false
	Audio.sfx("door")
	_apply_state()
	set_process(false)


func _door_rect() -> Rect2:
	var size: Vector2 = (_blocker_shape.shape as RectangleShape2D).size
	return Rect2(_blocker_shape.global_position - size / 2.0, size)


func _on_realm_changed(_active: bool) -> void:
	if is_node_ready():
		_apply_state()


func _apply_state() -> void:
	_blocker_shape.set_deferred("disabled", _opened or not is_in_current_world)
	_body.visible = not _opened
	prompt_text = "Open" if _opened else "Inspect"
	if _prompt:
		_prompt.text = "[E] " + prompt_text
