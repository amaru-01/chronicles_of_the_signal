class_name ScreenFX
extends Node
## Full-screen effects: scanline/vignette overlay, glitch pulse, colour flash.
## Drop the scene into any level or menu.

@export var react_to_layer_swap: bool = true
@export var show_overlay: bool = true

@onready var _glitch: ColorRect = $GlitchLayer/Glitch
@onready var _flash: ColorRect = $GlitchLayer/Flash
@onready var _overlay_layer: CanvasLayer = $OverlayLayer

var _glitch_material: ShaderMaterial
var _glitch_tween: Tween


func _ready() -> void:
	_glitch_material = _glitch.material as ShaderMaterial
	_glitch.visible = false
	_overlay_layer.visible = show_overlay
	if react_to_layer_swap:
		GameState.layer_changed.connect(func(_layer: GameState.WorldLayer) -> void: pulse())


## Brief glitch burst that fades out.
func pulse(strength: float = 1.0, duration: float = 0.35) -> void:
	if _glitch_tween:
		_glitch_tween.kill()
	_glitch.visible = true
	_glitch_material.set_shader_parameter("intensity", strength)
	_glitch_tween = create_tween()
	_glitch_tween.tween_method(_set_intensity, strength, 0.0, duration)
	_glitch_tween.finished.connect(func() -> void: _glitch.visible = false)


## Quick colour flash (for example red when something is refused).
func flash(color: Color, duration: float = 0.25) -> void:
	_flash.color = color
	var tween: Tween = create_tween()
	tween.tween_property(_flash, "color:a", 0.0, duration)


func _set_intensity(value: float) -> void:
	_glitch_material.set_shader_parameter("intensity", value)
