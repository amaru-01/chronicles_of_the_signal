class_name NPC
extends Interactable
## A talking NPC. Says `alt_lines` instead once `alt_if_hacked` has been hacked.

@export var speaker: String = "STRANGER"
@export var lines: Array[String] = ["..."]
@export var alt_if_hacked: String = ""
@export var alt_lines: Array[String] = []

@onready var _sprite: CharacterSprite = $Sprite


func interact(player: Node2D) -> void:
	_sprite.face_towards(player.global_position)
	if alt_if_hacked != "" and GameState.is_hacked(alt_if_hacked) and not alt_lines.is_empty():
		Dialogue.start(speaker, alt_lines)
	else:
		Dialogue.start(speaker, lines)
