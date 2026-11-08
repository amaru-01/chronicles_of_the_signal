class_name Enforcer3D
extends Enemy3D
## Armoured security robot. Exists only in the Physical world, chases the player when
## close (sliding along walls) and costs HP on contact. Its plating shrugs off the
## melee strike: only the hack pulse hurts it, so the player has to keep their distance.

const ENFORCER_TEXTURE: Texture2D = preload("res://assets3d/sprites/enforcer_3d.png")

@export var alert_radius: float = 8.0
@export var chase_speed: float = 4.2

var _chasing: bool = false


func _init() -> void:
	max_hp = 4
	damage = 20
	speed = 2.4
	hit_cooldown = 1.2
	contact_radius = 1.2


func _home_world() -> GameState.WorldLayer:
	return GameState.WorldLayer.PHYSICAL


func _make_sprite() -> Sprite3D:
	return Interactable3D.make_billboard(ENFORCER_TEXTURE, 2)


func _accepts(kind: String) -> bool:
	return kind == "pulse"


func _animate(delta: float) -> void:
	_anim_time += delta
	_sprite.frame = int(_anim_time * (6.0 if _chasing else 3.0)) % 2


func _move(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	var near: bool = player != null and flat_distance(player.global_position) < alert_radius
	_chasing = near
	_set_tint(Color(1.0, 0.65, 0.65) if _chasing else Color.WHITE)
	if _chasing:
		_step_toward(player.global_position, chase_speed, delta, true)
		return
	var target: Vector3 = _end if _to_end else _start
	if _step_toward(target, speed, delta, true):
		_to_end = not _to_end


func _on_contact() -> void:
	GameState.damage_health(damage)
