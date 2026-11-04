extends Node2D
## Trial scene: walk around and press Space to swap worlds.

@onready var _layers: WorldLayers = $Layers
@onready var _label: Label = $HUD/Label


func _ready() -> void:
	_layers.layer_changed.connect(_on_layer_changed)
	_layers.swap_blocked.connect(_on_swap_blocked)
	_refresh_label("")


func _on_layer_changed(_layer: GameState.WorldLayer) -> void:
	_refresh_label("")


func _on_swap_blocked() -> void:
	_refresh_label("  [swap blocked: you'd be inside a wall]")


func _refresh_label(extra: String) -> void:
	var world: String = (
		"PHYSICAL" if GameState.current_layer == GameState.WorldLayer.PHYSICAL else "DIGITAL"
	)
	_label.text = "World: %s   (WASD / arrows move, Space swaps)%s" % [world, extra]
