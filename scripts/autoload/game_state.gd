extends Node
## Global game state that persists across scene changes (port of GameState dataclass).
## Registered as the "GameState" autoload in project.godot.

signal layer_changed(layer: WorldLayer)
signal terminal_hacked(terminal_id: String)

enum WorldLayer { PHYSICAL, DIGITAL }

var current_layer: WorldLayer = WorldLayer.PHYSICAL
var current_district: String = "district_01"
var player_health: int = 100
var player_signal_integrity: int = 100  # "HP" for the digital layer
var inventory: Array[String] = []
var hacked_terminals: Dictionary = {}  # terminal_id -> true (acts as a set)
var flags: Dictionary = {}


func set_layer(layer: WorldLayer) -> void:
	current_layer = layer
	layer_changed.emit(layer)


func hack_terminal(terminal_id: String) -> void:
	if hacked_terminals.has(terminal_id):
		return
	hacked_terminals[terminal_id] = true
	terminal_hacked.emit(terminal_id)


func is_hacked(terminal_id: String) -> bool:
	return hacked_terminals.has(terminal_id)


func add_item(item_id: String) -> void:
	inventory.append(item_id)


func reset() -> void:
	current_layer = WorldLayer.PHYSICAL
	current_district = "district_01"
	player_health = 100
	player_signal_integrity = 100
	inventory.clear()
	hacked_terminals.clear()
	flags.clear()
