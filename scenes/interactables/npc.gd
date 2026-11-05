class_name NPC
extends Interactable
## A talking NPC. Says `alt_lines` instead once `alt_if_hacked` has been hacked.

@export var speaker: String = "STRANGER"
@export var lines: Array[String] = ["..."]
@export var alt_if_hacked: String = ""
@export var alt_lines: Array[String] = []
## Optional question menu after the lines. `answers[i]` is said for `options[i]`.
## The last option always ends the conversation (use it for "Never mind").
@export var question: String = ""
@export var options: Array[String] = []
@export var answers: Array[String] = []

@onready var _sprite: CharacterSprite = $Sprite


func interact(player: Node2D) -> void:
	_sprite.face_towards(player.global_position)
	if alt_if_hacked != "" and GameState.is_hacked(alt_if_hacked) and not alt_lines.is_empty():
		Dialogue.start(speaker, alt_lines)
	else:
		Dialogue.start(speaker, lines)
		await Dialogue.finished
		if not options.is_empty() and not GameState.is_hacked(alt_if_hacked):
			await _ask_questions()


func _ask_questions() -> void:
	while true:
		var pick: int = await Dialogue.ask(speaker, question, options)
		if pick < 0 or pick >= options.size() - 1 or pick >= answers.size():
			return
		Dialogue.start(speaker, [answers[pick]] as Array[String])
		await Dialogue.finished
