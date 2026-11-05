extends Node2D
## Trial scene: walk around, swap worlds, talk, hack, open the door.

@onready var _layers: WorldLayers = $Layers
@onready var _fx: ScreenFX = $ScreenFX
@onready var _world_label: Label = $HUD/Margin/VBox/WorldLabel
@onready var _integrity_bar: ProgressBar = $HUD/Margin/VBox/IntegrityBar
@onready var _integrity_label: Label = $HUD/Margin/VBox/IntegrityLabel
@onready var _notice: Label = $HUD/Notice


func _ready() -> void:
	_layers.layer_changed.connect(func(_layer: GameState.WorldLayer) -> void: _refresh_hud())
	_layers.swap_blocked.connect(_on_swap_blocked)
	GameState.integrity_changed.connect(func(_value: int) -> void: _on_integrity_changed())
	GameState.signal_lost.connect(_on_signal_lost)
	_notice.modulate.a = 0.0
	_refresh_hud()


func _on_swap_blocked() -> void:
	_fx.flash(Color(1.0, 0.1, 0.2, 0.35), 0.3)
	_show_notice("Can't swap: you'd be stuck inside something solid")


func _on_integrity_changed() -> void:
	_fx.pulse(0.6, 0.3)
	_fx.flash(Color(1.0, 0.1, 0.2, 0.3), 0.4)
	_refresh_hud()


func _on_signal_lost() -> void:
	if Dialogue.is_active:
		await Dialogue.finished
	Dialogue.start("SYSTEM", ["SIGNAL LOST.", "Rebooting from the last safe point..."])
	await Dialogue.finished
	GameState.restore_signal()
	GameState.current_layer = GameState.WorldLayer.PHYSICAL
	SceneManager.change_scene(scene_file_path)


func _refresh_hud() -> void:
	var world: String = (
		"PHYSICAL" if GameState.current_layer == GameState.WorldLayer.PHYSICAL else "DIGITAL"
	)
	_world_label.text = "WORLD: %s   ITEMS: %d" % [world, GameState.inventory.size()]
	_integrity_bar.value = GameState.player_signal_integrity
	_integrity_label.text = "SIGNAL INTEGRITY %d%%" % GameState.player_signal_integrity


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(_notice, "modulate:a", 0.0, 0.5)
