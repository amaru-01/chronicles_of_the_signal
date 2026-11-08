class_name Sentry3D
extends Enemy3D
## Physical-world turret. Stationary; when you are in range and in line of sight (and in
## the Physical world) it fires slow bolts at you. Dodge them, break line of sight behind a
## wall, or swap to the Grid where it and its bolts do not exist. Melee and pulse both work.

const SENTRY_TEXTURE: Texture2D = preload("res://assets3d/sprites/sentry_3d.png")

@export var fire_range: float = 12.0
@export var fire_interval: float = 2.0
@export var bolt_speed: float = 7.0
@export var bolt_damage: int = 12

var _fire_timer: float = 1.0
var _flash_time: float = 0.0


func _init() -> void:
	max_hp = 3
	damage = 10
	speed = 0.0
	contact_radius = 0.9
	patrol_offset = Vector3.ZERO


func _home_world() -> GameState.WorldLayer:
	return GameState.WorldLayer.PHYSICAL


func _kind() -> String:
	return "sentry"


func _make_sprite() -> Sprite3D:
	var sprite: Sprite3D = Interactable3D.make_billboard(SENTRY_TEXTURE, 2)
	sprite.pixel_size = 0.03
	return sprite


func _animate(delta: float) -> void:
	_anim_time += delta
	_flash_time = maxf(0.0, _flash_time - delta)
	_sprite.frame = 1 if _flash_time > 0.0 else 0


func _move(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player == null or Dialogue.is_active or GameState.minigame_active:
		return
	if flat_distance(player.global_position) > fire_range or not _has_line_of_sight(player.global_position):
		return
	_fire_timer = fire_interval
	_flash_time = 0.2
	Audio.sfx("bolt", -8.0)
	var bolt := EnemyBolt3D.new()
	bolt.world = GameState.WorldLayer.PHYSICAL
	bolt.speed = bolt_speed
	bolt.damage = bolt_damage
	var aim: Vector3 = player.global_position - global_position
	aim.y = 0.0
	bolt.direction = aim.normalized()
	bolt.position = global_position + bolt.direction * 0.8
	get_parent().add_child(bolt)


## Walk the line to the target in 0.5 m steps; a wall in this world blocks the shot.
func _has_line_of_sight(target: Vector3) -> bool:
	if _layers == null:
		return true
	var line: Vector3 = target - global_position
	line.y = 0.0
	var steps: int = int(line.length() / 0.5)
	for i: int in range(1, steps):
		var point: Vector3 = global_position + line * (float(i) / float(steps))
		if _layers.is_wall(GameState.WorldLayer.PHYSICAL, floori(point.x / WorldLayers3D.TILE), floori(point.z / WorldLayers3D.TILE)):
			return false
	return true


func _on_contact() -> void:
	GameState.damage_health(Items3D.physical_damage(damage))
