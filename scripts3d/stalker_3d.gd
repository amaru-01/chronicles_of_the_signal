class_name Stalker3D
extends Enemy3D
## Grid wraith. Exists only in the Digital world, drifts near its post and, when you come
## close, streaks after you at speed THROUGH WALLS. Fragile (2 HP) but fast: the answer is
## to fight it, or to swap to the real world where it cannot follow.

const STALKER_TEXTURE: Texture2D = preload("res://assets3d/sprites/stalker_3d.png")

@export var alert_radius: float = 9.0
@export var chase_speed: float = 4.6

var _chasing: bool = false


func _init() -> void:
	max_hp = 2
	damage = 12
	speed = 1.2
	hit_cooldown = 1.0
	contact_radius = 1.0
	patrol_offset = Vector3(3.0, 0.0, 0.0)


func _home_world() -> GameState.WorldLayer:
	return GameState.WorldLayer.DIGITAL


func _kind() -> String:
	return "stalker"


func _make_sprite() -> Sprite3D:
	var sprite: Sprite3D = Interactable3D.make_billboard(STALKER_TEXTURE, 2)
	sprite.pixel_size = 0.03
	return sprite


func _animate(delta: float) -> void:
	_anim_time += delta
	_sprite.frame = int(_anim_time * (7.0 if _chasing else 3.0)) % 2
	_sprite.position.y = 1.0 + sin(_anim_time * 2.5) * 0.15


func _move(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	_chasing = player != null and flat_distance(player.global_position) < alert_radius
	_set_tint(Color(1.0, 0.7, 1.0) if _chasing else Color.WHITE)
	if _chasing:
		_step_toward(player.global_position, chase_speed, delta, false)  # phases through walls
		return
	var target: Vector3 = _end if _to_end else _start
	if _step_toward(target, speed, delta, false):
		_to_end = not _to_end


func _on_contact() -> void:
	GameState.damage_signal(Items3D.signal_damage(damage))
