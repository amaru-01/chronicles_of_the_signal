class_name Npc3D
extends Interactable3D
## A talking character. Says `alt_lines` once `alt_if_hacked` has been hacked. Optional
## question menu after the lines: `answers[i]` is said for `options[i]`; the last option
## always ends the conversation (use it for "Never mind").

@export var speaker: String = "FIXER"
@export var sheet: Texture2D = preload("res://assets3d/sprites/fixer_3d.png")
@export var tint: Color = Color.WHITE
## Set when the player talks to this character (for quest objectives).
@export var talk_flag: String = ""
@export var lines: Array[String] = []
@export var alt_if_hacked: String = ""
@export var alt_lines: Array[String] = []
@export var question: String = ""
@export var options: Array[String] = []
@export var answers: Array[String] = []

var _sprite: Sprite3D


func _ready() -> void:
	prompt_text = "TALK"
	super()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	shape.shape = sphere
	shape.position.y = 0.9
	add_child(shape)
	# 5x4 sheet of 48x80 cells: show the front-facing idle cell.
	_sprite = make_billboard(sheet, 5, 4)
	_sprite.frame_coords = Vector2i(0, 0)
	_sprite.modulate = tint
	add_child(_sprite)


func _process(_delta: float) -> void:
	# Turn to face the player (sheet rows: down, left, right, up).
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player == null or not is_in_current_world:
		return
	var offset: Vector3 = player.global_position - global_position
	if offset.length() > 6.0:
		_sprite.frame_coords = Vector2i(0, 0)
	elif absf(offset.x) > absf(offset.z) * 1.4:
		_sprite.frame_coords = Vector2i(0, 2 if offset.x > 0.0 else 1)
	else:
		_sprite.frame_coords = Vector2i(0, 0 if offset.z > 0.0 else 3)


func interact(_player: Node3D) -> void:
	if talk_flag != "":
		GameState.flags[talk_flag] = true
	if alt_if_hacked != "" and GameState.is_hacked(alt_if_hacked) and not alt_lines.is_empty():
		Dialogue.start(speaker, alt_lines)
		return
	Dialogue.start(speaker, lines)
	await Dialogue.finished
	if not options.is_empty():
		await _ask_questions()


func _ask_questions() -> void:
	while true:
		var pick: int = await Dialogue.ask(speaker, question, options)
		if pick < 0 or pick >= options.size() - 1 or pick >= answers.size():
			return
		Dialogue.start(speaker, [answers[pick]] as Array[String])
		await Dialogue.finished
