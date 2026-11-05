class_name Checkpoint
extends Area2D
## Walk through to save a respawn point. After a "signal lost" reboot the player
## starts here instead of at the district's start. Invisible; it just saves.

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # player
	body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			GameState.set_checkpoint(_district_id(), global_position)
	)


func _district_id() -> String:
	return GameState.current_district
