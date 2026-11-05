class_name Drone
extends Area2D
## Trace drone. Patrols between its start and start + `patrol_offset`, and only
## exists in the Digital world. Touching the player costs signal integrity, then
## the drone ignores the player for `hit_cooldown` seconds. In the Physical world
## it is hidden and harmless, so swapping back is always a way to escape.

@export var patrol_offset: Vector2 = Vector2(200, 0)
@export var speed: float = 90.0
@export var damage: int = 15
@export var hit_cooldown: float = 1.5

var active: bool = true

var _start: Vector2
var _end: Vector2
var _heading_to_end: bool = true
var _cooldown: float = 0.0
var _anim_time: float = 0.0

@onready var _sprite: Sprite2D = $Body


func _ready() -> void:
	_start = position
	_end = position + patrol_offset
	collision_layer = 0
	collision_mask = 1  # player
	GameState.layer_changed.connect(_refresh)
	_refresh(GameState.current_layer)


func _physics_process(delta: float) -> void:
	if not active:
		return
	var target: Vector2 = _end if _heading_to_end else _start
	position = position.move_toward(target, speed * delta)
	if position.is_equal_approx(target):
		_heading_to_end = not _heading_to_end
	_anim_time += delta
	_sprite.frame = int(_anim_time * 3.0) % 2
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0 or Dialogue.is_active or GameState.minigame_active:
		return
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			_hit()
			return


func _hit() -> void:
	_cooldown = hit_cooldown
	Audio.sfx("hit")
	GameState.damage_signal(damage)


func _refresh(layer: GameState.WorldLayer) -> void:
	active = layer == GameState.WorldLayer.DIGITAL
	visible = active
	set_deferred("monitoring", active)
	_cooldown = hit_cooldown  # grace period after swapping into a drone's path
