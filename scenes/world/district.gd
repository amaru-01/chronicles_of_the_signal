class_name District
extends Node2D
## Shared logic for every district scene: HUD, hints (H), swap feedback, music,
## checkpoints and the signal-lost reboot. A district script extends this and
## overrides `_objectives()` with its own hint list.

@onready var _player: Player = $Player
@onready var _spawn: Marker2D = $SpawnPoint
@onready var _layers: WorldLayers = $Layers
@onready var _fx: ScreenFX = $ScreenFX
@onready var _world_label: Label = $HUD/Margin/VBox/WorldLabel
@onready var _integrity_bar: ProgressBar = $HUD/Margin/VBox/IntegrityBar
@onready var _integrity_label: Label = $HUD/Margin/VBox/IntegrityLabel
@onready var _notice: Label = $HUD/Notice

@export var district_id: String = "district_01"

var _hint_tier: Dictionary = {}  # objective index -> tiers already shown


func _ready() -> void:
	GameState.current_district = district_id
	_player.global_position = _checkpoint_or_spawn()
	GameState.checkpoint_reached.connect(func() -> void:
		Audio.sfx("pickup")
		_show_notice("Checkpoint saved")
	)
	_fit_camera()
	_layers.layer_changed.connect(_on_layer_changed)
	_layers.swap_blocked.connect(_on_swap_blocked)
	GameState.integrity_changed.connect(func(_value: int) -> void: _on_integrity_changed())
	GameState.signal_lost.connect(_on_signal_lost)
	_notice.modulate.a = 0.0
	_refresh_hud()
	_play_world_music(GameState.current_layer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hint") and not Dialogue.is_active and not GameState.minigame_active:
		get_viewport().set_input_as_handled()
		_show_hint()


## Override in each district. Each entry: {"done": "method_name", "tiers": [vague, ..., explicit]}.
## Objectives are checked in order; the first not-done one is hinted.
func _objectives() -> Array[Dictionary]:
	return []


func _checkpoint_or_spawn() -> Vector2:
	if GameState.checkpoints.has(district_id):
		return GameState.checkpoints[district_id]
	return _spawn.global_position


func _show_hint() -> void:
	Audio.sfx("click")
	var objectives: Array[Dictionary] = _objectives()
	for i: int in objectives.size():
		var objective: Dictionary = objectives[i]
		if call(objective["done"] as String):
			continue
		var tiers: Array = objective["tiers"]
		var shown: int = _hint_tier.get(i, 0)
		var text: String = tiers[mini(shown, tiers.size() - 1)]
		_hint_tier[i] = mini(shown + 1, tiers.size())
		var more: String = "" if shown >= tiers.size() - 1 else "  (press H again for more help)"
		Dialogue.start("HINT", ["%s%s" % [text, more]] as Array[String])
		return


func _on_layer_changed(layer: GameState.WorldLayer) -> void:
	Audio.sfx("swap")
	_play_world_music(layer)
	_refresh_hud()


func _play_world_music(layer: GameState.WorldLayer) -> void:
	Audio.play_music("physical" if layer == GameState.WorldLayer.PHYSICAL else "digital")


func _on_swap_blocked() -> void:
	Audio.sfx("hack_fail", -6.0)
	_fx.flash(Color(1.0, 0.1, 0.2, 0.35), 0.3)
	_show_notice("Can't swap: you'd be stuck inside something solid")


func _on_integrity_changed() -> void:
	_fx.pulse(0.6, 0.3)
	_fx.flash(Color(1.0, 0.1, 0.2, 0.3), 0.4)
	_refresh_hud()


func _on_signal_lost() -> void:
	if Dialogue.is_active:
		await Dialogue.finished
	Audio.sfx("lost")
	Dialogue.start("SYSTEM", ["SIGNAL LOST.", "Rebooting from the last safe point..."])
	await Dialogue.finished
	GameState.restore_signal()
	GameState.current_layer = GameState.WorldLayer.PHYSICAL
	SceneManager.change_scene(scene_file_path)


func _refresh_hud() -> void:
	var world: String = (
		"PHYSICAL" if GameState.current_layer == GameState.WorldLayer.PHYSICAL else "DIGITAL"
	)
	_world_label.text = "WORLD: %s   ITEMS: %d   [H] HINT" % [world, GameState.inventory.size()]
	_integrity_bar.value = GameState.player_signal_integrity
	_integrity_label.text = "SIGNAL INTEGRITY %d%%" % GameState.player_signal_integrity


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(_notice, "modulate:a", 0.0, 0.5)


## Stop the camera at the map edges so the void is never shown.
func _fit_camera() -> void:
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = _layers.map_size.x * WorldLayers.TILE_SIZE
	camera.limit_bottom = _layers.map_size.y * WorldLayers.TILE_SIZE
