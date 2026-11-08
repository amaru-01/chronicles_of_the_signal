class_name Drone3D
extends Node3D
## Trace drone. Hovers on a patrol and exists only in the Digital world. Touching
## the player costs signal integrity; the player can destroy it with the melee
## strike (J / left click). In the Physical world it is hidden and harmless.

const DRONE_TEXTURE: Texture2D = preload("res://assets3d/sprites/drone_3d.png")

@export var patrol_offset: Vector3 = Vector3(8.0, 0.0, 0.0)
@export var speed: float = 3.2
@export var damage: int = 15
@export var hit_cooldown: float = 1.5
@export var max_hp: int = 3
@export var hover_height: float = 1.5
@export var contact_radius: float = 1.1

var active: bool = true

var _start: Vector3
var _end: Vector3
var _to_end: bool = true
var _cooldown: float = 0.0
var _anim_time: float = 0.0
var _hp: int
var _knockback: Vector3 = Vector3.ZERO
var _sprite: Sprite3D


func _ready() -> void:
	add_to_group("enemy3d")
	_hp = max_hp
	_start = position
	_end = position + patrol_offset
	_sprite = Interactable3D.make_billboard(DRONE_TEXTURE, 2)
	_sprite.pixel_size = 0.036  # a bit larger than the 0.025 character scale: drones loom
	_sprite.position.y = hover_height
	add_child(_sprite)
	GameState.layer_changed.connect(_refresh)
	_refresh(GameState.current_layer)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_anim_time += delta
	_sprite.frame = int(_anim_time * 3.0) % 2
	_sprite.position.y = hover_height + sin(_anim_time * 3.0) * 0.12

	if _knockback.length() > 0.05:
		position += _knockback * delta
		_knockback = _knockback.move_toward(Vector3.ZERO, 14.0 * delta)
	else:
		var target: Vector3 = _end if _to_end else _start
		position = position.move_toward(target, speed * delta)
		if position.is_equal_approx(target):
			_to_end = not _to_end

	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0 or Dialogue.is_active or GameState.minigame_active:
		return
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player and _flat_distance(player.global_position) < contact_radius:
		_hit()


## Called by the player's melee strike.
func take_hit(amount: int, from: Vector3) -> void:
	if not active:
		return
	_hp -= amount
	Audio.sfx("hit")
	var away: Vector3 = (global_position - from)
	away.y = 0.0
	_knockback = away.normalized() * 9.0
	_sprite.modulate = Color(3.0, 3.0, 3.0)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if _hp <= 0:
		active = false
		remove_from_group("enemy3d")
		var fade: Tween = create_tween()
		fade.tween_property(_sprite, "modulate:a", 0.0, 0.25)
		fade.finished.connect(queue_free)


func _hit() -> void:
	_cooldown = hit_cooldown
	Audio.sfx("hit")
	GameState.damage_signal(damage)


func _flat_distance(point: Vector3) -> float:
	return Vector2(global_position.x - point.x, global_position.z - point.z).length()


func _refresh(layer: GameState.WorldLayer) -> void:
	var in_grid: bool = layer == GameState.WorldLayer.DIGITAL
	active = in_grid and _hp > 0
	visible = active
	_cooldown = hit_cooldown  # grace period after swapping into a drone's path
