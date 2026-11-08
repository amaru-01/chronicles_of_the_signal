class_name Drone3D
extends Enemy3D
## Trace drone. Hovers on a patrol and exists only in the Digital world. Contact costs
## signal integrity. Weak to everything: melee strike or hack pulse.

const DRONE_TEXTURE: Texture2D = preload("res://assets3d/sprites/drone_3d.png")

@export var hover_height: float = 1.5


func _home_world() -> GameState.WorldLayer:
	return GameState.WorldLayer.DIGITAL


func _make_sprite() -> Sprite3D:
	var sprite: Sprite3D = Interactable3D.make_billboard(DRONE_TEXTURE, 2)
	sprite.pixel_size = 0.036  # a bit larger than the 0.025 character scale: drones loom
	sprite.position.y = hover_height
	return sprite


func _animate(delta: float) -> void:
	_anim_time += delta
	_sprite.frame = int(_anim_time * 3.0) % 2
	_sprite.position.y = hover_height + sin(_anim_time * 3.0) * 0.12


func _on_contact() -> void:
	GameState.damage_signal(damage)
