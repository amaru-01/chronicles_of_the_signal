class_name Enemy3D
extends Node3D
## Base class for 3D enemies. Each enemy lives in one world (hidden and harmless in the
## other), patrols between its start and start + `patrol_offset`, hurts the player on
## contact, and decides per attack kind ("melee", "pulse") whether it takes damage.
## Subclasses override the `_home_world`, `_make_sprite`, `_accepts`, `_on_contact`
## hooks (and optionally `_move` / `_animate`).

@export var patrol_offset: Vector3 = Vector3(8.0, 0.0, 0.0)
@export var speed: float = 3.2
@export var damage: int = 15
@export var hit_cooldown: float = 1.5
@export var max_hp: int = 3
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
## Resting colour of the sprite; hit flashes fade back to it.
var _base_tint: Color = Color.WHITE
var _layers: WorldLayers3D


# --- hooks for subclasses -------------------------------------------------------

func _home_world() -> GameState.WorldLayer:
	return GameState.WorldLayer.DIGITAL


func _make_sprite() -> Sprite3D:
	return null


## Which attack kinds hurt this enemy.
func _accepts(_kind: String) -> bool:
	return true


## Contact with the player (already rate-limited by `hit_cooldown`).
func _on_contact() -> void:
	pass


func _animate(delta: float) -> void:
	_anim_time += delta


func _move(delta: float) -> void:
	var target: Vector3 = _end if _to_end else _start
	if _step_toward(target, speed, delta):
		_to_end = not _to_end


# --- shared behaviour -----------------------------------------------------------

func _ready() -> void:
	add_to_group("enemy3d")
	_hp = max_hp
	_start = position
	_end = position + patrol_offset
	_sprite = _make_sprite()
	if _sprite:
		add_child(_sprite)
	_layers = get_tree().get_first_node_in_group("layers3d") as WorldLayers3D
	GameState.layer_changed.connect(_refresh)
	_refresh(GameState.current_layer)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_animate(delta)
	if _knockback.length() > 0.05:
		position += _knockback * delta
		_knockback = _knockback.move_toward(Vector3.ZERO, 14.0 * delta)
	else:
		_move(delta)

	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0 or Dialogue.is_active or GameState.minigame_active:
		return
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player and flat_distance(player.global_position) < contact_radius:
		_cooldown = hit_cooldown
		Audio.sfx("hit")
		_on_contact()


## Called by the player's attacks. `kind` is "melee" or "pulse".
func take_hit(amount: int, from: Vector3, kind: String) -> void:
	if not active:
		return
	var away: Vector3 = global_position - from
	away.y = 0.0
	if not _accepts(kind):
		_knockback = away.normalized() * 3.0
		Audio.sfx("hack_fail", -10.0)
		_flash(Color(1.6, 1.4, 0.8))  # spark: it shrugged the attack off
		return
	_hp -= amount
	Audio.sfx("hit")
	_knockback = away.normalized() * 9.0
	_flash(Color(3.0, 3.0, 3.0))
	if _hp <= 0:
		active = false
		remove_from_group("enemy3d")
		GameState.flags["kills"] = int(GameState.flags.get("kills", 0)) + 1  # for the hunting quest
		if _sprite:
			var fade: Tween = create_tween()
			fade.tween_property(_sprite, "modulate:a", 0.0, 0.25)
			fade.finished.connect(queue_free)
		else:
			queue_free()


func is_alive() -> bool:
	return active and _hp > 0


func flat_distance(point: Vector3) -> float:
	return Vector2(global_position.x - point.x, global_position.z - point.z).length()


## Move toward `target` on the ground plane. Returns true on arrival. Ground enemies
## (those that call it with `walls = true`) slide along walls instead of crossing them.
func _step_toward(target: Vector3, move_speed: float, delta: float, walls: bool = false) -> bool:
	var to_target: Vector3 = target - position
	to_target.y = 0.0
	if to_target.length() < 0.05:
		return true
	var step: Vector3 = to_target.normalized() * minf(move_speed * delta, to_target.length())
	if not walls:
		position += step
	else:
		var next: Vector3 = position
		if _walkable(Vector3(position.x + step.x, 0.0, position.z)):
			next.x += step.x
		if _walkable(Vector3(next.x, 0.0, position.z + step.z)):
			next.z += step.z
		position = next
	return (target - position).length() < 0.1


func _walkable(point: Vector3) -> bool:
	if _layers == null:
		return true
	var r: float = 0.5
	for offset: Vector2 in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var cx: int = floori((point.x + offset.x) / WorldLayers3D.TILE)
		var cy: int = floori((point.z + offset.y) / WorldLayers3D.TILE)
		if _layers.is_wall(_home_world(), cx, cy):
			return false
	return true


func _flash(color: Color) -> void:
	if _sprite == null:
		return
	_sprite.modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", _base_tint, 0.2)


func _refresh(layer: GameState.WorldLayer) -> void:
	active = layer == _home_world() and _hp > 0
	visible = active
	_cooldown = hit_cooldown  # grace period after swapping into an enemy's reach


func _set_tint(color: Color) -> void:
	if color == _base_tint:
		return
	_base_tint = color
	if _sprite:
		_sprite.modulate = color
