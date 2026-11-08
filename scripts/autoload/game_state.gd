extends Node
## Global game state that persists across scene changes (port of GameState dataclass).
## Registered as the "GameState" autoload in project.godot.

signal layer_changed(layer: WorldLayer)
signal terminal_hacked(terminal_id: String)
signal terminal_reset(terminal_id: String)  # a timed switch turned itself off
signal integrity_changed(value: int)
signal health_changed(value: int)  # physical-world HP (used by the 3D game)
signal signal_lost
signal checkpoint_reached

enum WorldLayer { PHYSICAL, DIGITAL }

const SAVE_PATH: String = "user://save.json"
## Where saves go. Dev tests point this at a throwaway file so they never touch a real save.
var save_path: String = SAVE_PATH
const SAVE_VERSION: int = 1
## district id -> scene, used by Continue.
const DISTRICT_SCENES: Dictionary = {
	"district_01": "res://scenes/world/district_01.tscn",
	"district_02": "res://scenes/world/district_02.tscn",
	# 3D game (see scripts3d/world_map_3d.gd)
	"3d_hub": "res://scenes3d/hub_3d.tscn",
	"3d_district_01": "res://scenes3d/district_01_3d.tscn",
	"3d_district_02": "res://scenes3d/district_02_3d.tscn",
}

const MAX_SIGNAL_INTEGRITY: int = 100

var current_layer: WorldLayer = WorldLayer.PHYSICAL
var current_district: String = "district_01"
var player_health: int = 100
var player_signal_integrity: int = MAX_SIGNAL_INTEGRITY  # "HP" for the digital layer
var inventory: Array[String] = []
var hacked_terminals: Dictionary = {}  # terminal_id -> true (acts as a set)
var flags: Dictionary = {}
var deaths: int = 0
## district id -> Vector2 where a reboot respawns the player.
var checkpoints: Dictionary = {}
## Ids of timed switches: they turn themselves off, so they are never saved.
var transient_ids: Dictionary = {}

## True while the hacking minigame is open (other UI should ignore input).
var minigame_active: bool = false


func set_layer(layer: WorldLayer) -> void:
	current_layer = layer
	layer_changed.emit(layer)


func set_checkpoint(district: String, pos: Vector2) -> void:
	if checkpoints.get(district) == pos:
		return
	checkpoints[district] = pos
	checkpoint_reached.emit()
	save_game()


func hack_terminal(terminal_id: String) -> void:
	if hacked_terminals.has(terminal_id):
		return
	hacked_terminals[terminal_id] = true
	terminal_hacked.emit(terminal_id)
	save_game()


func unhack_terminal(terminal_id: String) -> void:
	if hacked_terminals.erase(terminal_id):
		terminal_reset.emit(terminal_id)


func is_hacked(terminal_id: String) -> bool:
	return hacked_terminals.has(terminal_id)


func add_item(item_id: String) -> void:
	inventory.append(item_id)
	save_game()


func damage_signal(amount: int) -> void:
	player_signal_integrity = maxi(0, player_signal_integrity - amount)
	integrity_changed.emit(player_signal_integrity)
	if player_signal_integrity == 0:
		deaths += 1
		signal_lost.emit()


## Physical-world damage (3D game). At 0 HP the same "signal lost" reboot runs.
func damage_health(amount: int) -> void:
	player_health = maxi(0, player_health - amount)
	health_changed.emit(player_health)
	if player_health == 0:
		deaths += 1
		signal_lost.emit()


func restore_health() -> void:
	player_health = 100
	health_changed.emit(player_health)


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
	deaths = 0
	checkpoints.clear()
	minigame_active = false


# --- save / load ---------------------------------------------------------------
# Autosaves on every hack and pickup. The player's position is not saved: loading
# puts you back at the district's spawn point with your progress intact.

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"district": current_district,
		"health": player_health,
		"integrity": player_signal_integrity,
		"inventory": inventory,
		"hacked": hacked_terminals.keys().filter(func(id: Variant) -> bool: return not transient_ids.has(id)),
		"flags": flags,
		"deaths": deaths,
		"checkpoints": _checkpoints_to_json(),
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("GameState: cannot write save file")
		return
	file.store_string(JSON.stringify(data))


## Returns true if a valid save was loaded into the current state.
func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed
	reset()
	current_district = str(data.get("district", "district_01"))
	player_health = int(data.get("health", 100))
	player_signal_integrity = maxi(1, int(data.get("integrity", MAX_SIGNAL_INTEGRITY)))
	deaths = int(data.get("deaths", 0))
	for item: Variant in data.get("inventory", []):
		inventory.append(str(item))
	for id: Variant in data.get("hacked", []):
		hacked_terminals[str(id)] = true
	var saved_cp: Variant = data.get("checkpoints", {})
	if saved_cp is Dictionary:
		for id: Variant in saved_cp:
			var xy: Variant = saved_cp[id]
			if xy is Array and xy.size() == 2:
				checkpoints[str(id)] = Vector2(float(xy[0]), float(xy[1]))
	var saved_flags: Variant = data.get("flags", {})
	if saved_flags is Dictionary:
		flags = saved_flags
	return true


## The district id stored in the save file ("" if there is no readable save). Lets the
## title screen say whether Continue resumes the 2D or the 3D game.
func saved_district() -> String:
	if not has_save():
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary:
		return str((parsed as Dictionary).get("district", ""))
	return ""


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func district_scene() -> String:
	return DISTRICT_SCENES.get(current_district, DISTRICT_SCENES["district_01"])


func _checkpoints_to_json() -> Dictionary:
	var out: Dictionary = {}
	for id: Variant in checkpoints:
		var pos: Vector2 = checkpoints[id]
		out[id] = [pos.x, pos.y]
	return out
