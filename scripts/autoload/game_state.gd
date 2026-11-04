extends Node
## Global game state that persists across scene changes (port of GameState dataclass).
## Registered as the "GameState" autoload in project.godot.

signal layer_changed(layer: WorldLayer)
signal terminal_hacked(terminal_id: String)
signal integrity_changed(value: int)
signal signal_lost

enum WorldLayer { PHYSICAL, DIGITAL }

const MAX_SIGNAL_INTEGRITY: int = 100

var current_layer: WorldLayer = WorldLayer.PHYSICAL
var current_district: String = "district_01"
var player_health: int = 100
var player_signal_integrity: int = MAX_SIGNAL_INTEGRITY  # "HP" for the digital layer
var inventory: Array[String] = []
var hacked_terminals: Dictionary = {}  # terminal_id -> true (acts as a set)
var flags: Dictionary = {}

## True while the hacking minigame is open (other UI should ignore input).
var minigame_active: bool = false


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


func damage_signal(amount: int) -> void:
	player_signal_integrity = maxi(0, player_signal_integrity - amount)
	integrity_changed.emit(player_signal_integrity)
	if player_signal_integrity == 0:
		signal_lost.emit()


func restore_signal() -> void:
	player_signal_integrity = MAX_SIGNAL_INTEGRITY
	integrity_changed.emit(player_signal_integrity)


func reset() -> void:
	current_layer = WorldLayer.PHYSICAL
	current_district = "district_01"
	player_health = 100
	player_signal_integrity = MAX_SIGNAL_INTEGRITY
	inventory.clear()
	hacked_terminals.clear()
	flags.clear()
	minigame_active = false
