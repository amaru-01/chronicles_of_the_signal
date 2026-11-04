class_name Pickup
extends Interactable
## A collectable. Remembers it was taken so it stays gone after a scene reload.

@export var item_id: String = "data_fragment"
@export var item_name: String = "Data Fragment"

@onready var _sprite: Sprite2D = $Body


func _ready() -> void:
	if GameState.flags.has("picked_" + item_id):
		queue_free()
		return
	super()
	# Gentle bob so it reads as collectable.
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_sprite, "position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "position:y", 3.0, 0.8).set_trans(Tween.TRANS_SINE)


func interact(_player: Node2D) -> void:
	GameState.add_item(item_id)
	GameState.flags["picked_" + item_id] = true
	Dialogue.start("", ["Collected: %s." % item_name])
	queue_free()
