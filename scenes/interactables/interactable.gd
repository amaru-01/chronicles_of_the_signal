class_name Interactable
extends Area2D
## Base class for everything the player can press E on.
##
## The player's InteractArea (mask: interactable) finds these. Set `realm` to
## make an object exist in only one world: it is hidden and un-interactable in
## the other.

enum Realm { BOTH, PHYSICAL, DIGITAL }

@export var realm: Realm = Realm.BOTH
@export var prompt_text: String = "Interact"

var is_in_current_world: bool = true

@onready var _prompt: Label = get_node_or_null("Prompt")


func _ready() -> void:
	collision_layer = 1 << 3  # physics layer 4: "interactable"
	collision_mask = 0
	monitoring = false
	add_to_group("interactable")
	if _prompt:
		_prompt.text = "[E] " + prompt_text
	set_prompt_visible(false)
	GameState.layer_changed.connect(_on_layer_changed)
	_refresh_realm()


func interact(_player: Node2D) -> void:
	pass


func set_prompt_visible(value: bool) -> void:
	if _prompt:
		_prompt.visible = value and is_in_current_world


## True if this object would be solid in `target` and overlaps `player_rect`.
## Used by WorldLayers to refuse a swap that would trap the player.
func blocks_swap(_target: GameState.WorldLayer, _player_rect: Rect2) -> bool:
	return false


func exists_in(layer: GameState.WorldLayer) -> bool:
	match realm:
		Realm.PHYSICAL:
			return layer == GameState.WorldLayer.PHYSICAL
		Realm.DIGITAL:
			return layer == GameState.WorldLayer.DIGITAL
	return true


func _on_layer_changed(_layer: GameState.WorldLayer) -> void:
	_refresh_realm()


func _refresh_realm() -> void:
	is_in_current_world = exists_in(GameState.current_layer)
	visible = is_in_current_world
	set_deferred("monitorable", is_in_current_world)
	_on_realm_changed(is_in_current_world)


## Override to react when this object appears/disappears with a world swap.
func _on_realm_changed(_active: bool) -> void:
	pass
