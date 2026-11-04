class_name NPC
extends Interactable
## A talking NPC. Says `alt_lines` instead once `alt_if_hacked` has been hacked.

@export var speaker: String = "STRANGER"
@export var lines: Array[String] = ["..."]
@export var alt_if_hacked: String = ""
@export var alt_lines: Array[String] = []


func interact(_player: Node2D) -> void:
	if alt_if_hacked != "" and GameState.is_hacked(alt_if_hacked) and not alt_lines.is_empty():
		Dialogue.start(speaker, alt_lines)
	else:
		Dialogue.start(speaker, lines)
