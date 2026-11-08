class_name Terminal3D
extends Interactable3D
## Hackable terminal. Reuses the 2D timed code-breaker overlay unchanged.

const HACK_SCENE: PackedScene = preload("res://ui/hack_minigame.tscn")
const TERMINAL_TEXTURE: Texture2D = preload("res://assets3d/sprites/terminal_3d.png")

@export var terminal_id: String = "term_gate"
@export_range(5, 6) var word_length: int = 6
@export var attempts: int = 4
@export var time_limit: float = 30.0
@export var fail_damage: int = 20
## Optional-node reward: an item id handed over on the first successful hack.
@export var reward_item: String = ""

var _busy: bool = false
var _sprite: Sprite3D


func _ready() -> void:
	prompt_text = "HACK"
	super()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	shape.position.y = 0.8
	add_child(shape)
	_sprite = make_billboard(TERMINAL_TEXTURE, 2)
	add_child(_sprite)
	_update_look()


func interact(_player: Node3D) -> void:
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
			var lines: Array[String] = ["Access granted."]
			if reward_item != "":
				lines.append(_grant_reward())
			else:
				lines.append("Somewhere nearby, a lock gives way.")
			Dialogue.start("TERMINAL", lines)
		HackMinigame.Result.FAIL:
			Audio.sfx("hack_fail")
			Dialogue.start("TERMINAL", ["Trace detected. Signal integrity -%d%%." % fail_damage])
			GameState.damage_signal(Items3D.signal_damage(fail_damage))


## Hand over this node's reward (once) and return the line to show.
func _grant_reward() -> String:
	if not GameState.inventory.has(reward_item):
		GameState.add_item(reward_item)
	return "Recovered: %s." % Items3D.name_of(reward_item)


func _update_look() -> void:
	_sprite.frame = 1 if GameState.is_hacked(terminal_id) else 0
