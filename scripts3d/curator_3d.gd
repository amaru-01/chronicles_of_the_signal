class_name Curator3D
extends Enemy3D
## The Curator: the final boss, fought in the Relay Tower arena.
##
## It exists in ONE world at a time (its "form") and flips between Physical and Digital on a
## timer, with a one-second telegraph. You can only hurt it while you are standing in its
## current world, and its bolts only exist in that same world, so swapping dodges its
## attacks but also stops you hitting back. In its Physical form it is armoured: only the
## hack pulse hurts it. In its Digital form melee works too.
##
## Three phases (by HP): 1 fans of bolts, 2 rings of bolts and two Stalkers join in,
## 3 bigger rings, faster flips and two Enforcers join in. It sleeps until you walk in.

signal awakened
signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal deflected(reason: String)  # "dormant", "phase" (wrong world) or "armour"
signal defeated

const CURATOR_TEXTURE: Texture2D = preload("res://assets3d/sprites/curator_3d.png")
const FORM_SECONDS: Array[float] = [9.0, 7.0, 5.0]
const ATTACK_SECONDS: Array[float] = [2.6, 2.1, 1.6]
const BOLT_SPEED: Array[float] = [7.0, 8.0, 9.0]
const TELEGRAPH_SECONDS: float = 1.0

@export var wake_radius: float = 13.0

var form: GameState.WorldLayer = GameState.WorldLayer.PHYSICAL
var awake: bool = false
var phase: int = 1

var _form_timer: float = 9.0
var _telegraph: float = 0.0
var _attack_timer: float = 2.0
var _attack_count: int = 0
var _center: Vector3
var _time: float = 0.0


func _init() -> void:
	max_hp = 30
	damage = 25
	speed = 0.0
	contact_radius = 1.8
	hit_cooldown = 1.5
	patrol_offset = Vector3.ZERO


func _ready() -> void:
	super()
	_center = position
	_refresh(GameState.current_layer)


func _home_world() -> GameState.WorldLayer:
	return form


func _kind() -> String:
	return "curator"


func _make_sprite() -> Sprite3D:
	var sprite: Sprite3D = Interactable3D.make_billboard(CURATOR_TEXTURE, 4)
	sprite.pixel_size = 0.03
	return sprite


## The boss is always "active" (it cannot be pulled out of existence by swapping); what
## changes is whether you can touch it.
func _refresh(_layer: GameState.WorldLayer) -> void:
	active = _hp > 0
	visible = active
	_cooldown = hit_cooldown


func _accepts(kind: String) -> bool:
	if not awake or _telegraph > 0.0:
		return false
	if GameState.current_layer != form:
		return false
	if form == GameState.WorldLayer.PHYSICAL:
		return kind == "pulse"
	return true


func _on_deflected(_away: Vector3) -> void:
	Audio.sfx("clang", -6.0)
	_flash(Color(1.4, 1.4, 1.6))
	if not awake:
		deflected.emit("dormant")
	elif GameState.current_layer != form:
		deflected.emit("phase")
	elif form == GameState.WorldLayer.PHYSICAL:
		deflected.emit("armour")


func _knockback_strength() -> float:
	return 0.0


func _can_hurt_player() -> bool:
	return awake and _telegraph <= 0.0 and GameState.current_layer == form


func _on_contact() -> void:
	if form == GameState.WorldLayer.PHYSICAL:
		GameState.damage_health(Items3D.physical_damage(damage))
	else:
		GameState.damage_signal(Items3D.signal_damage(damage))


func take_hit(amount: int, from: Vector3, kind: String) -> void:
	var before: int = _hp
	super(amount, from, kind)
	if _hp != before:
		hp_changed.emit(maxi(_hp, 0), max_hp)
		_check_phase()


func _check_phase() -> void:
	var new_phase: int = 1 if _hp > 20 else (2 if _hp > 10 else 3)
	if new_phase <= phase or _hp <= 0:
		return
	phase = new_phase
	phase_changed.emit(phase)
	Audio.sfx("boss_phase")
	_telegraph = TELEGRAPH_SECONDS  # a beat of invulnerability while it powers up
	_attack_timer = ATTACK_SECONDS[phase - 1]
	if phase == 2:
		_summon(Stalker3D, [Vector3(-5.0, 0.0, 4.0), Vector3(5.0, 0.0, 4.0)])
	else:
		_summon(Enforcer3D, [Vector3(-6.0, 0.0, 5.0), Vector3(6.0, 0.0, 5.0)])


func _summon(enemy_script: GDScript, offsets: Array) -> void:
	for offset: Vector3 in offsets:
		var add: Enemy3D = enemy_script.new()
		add.position = _center + offset
		get_parent().add_child(add)


func _on_death() -> void:
	GameState.flags["curator_defeated"] = true
	for node: Node in get_tree().get_nodes_in_group("enemy3d"):
		if node != self:
			node.queue_free()
	for bolt: Node in get_tree().get_nodes_in_group("enemy_bolt3d"):
		bolt.queue_free()
	hp_changed.emit(0, max_hp)
	Audio.sfx("boss_down")
	defeated.emit()


func _animate(delta: float) -> void:
	_time += delta
	_anim_time += delta
	var form_index: int = 0 if form == GameState.WorldLayer.PHYSICAL else 1
	_sprite.frame = form_index * 2 + int(_anim_time * 2.0) % 2
	_sprite.position.y = 1.9 + sin(_time * 1.6) * 0.18
	# Ghostly when you are in the other world, flickering while it flips or powers up.
	var alpha: float = 1.0 if GameState.current_layer == form else 0.28
	if _telegraph > 0.0:
		alpha = 0.5 + 0.5 * sin(_time * 30.0)
	_set_tint(Color(1.0, 1.0, 1.0, alpha))


func _move(delta: float) -> void:
	if not awake:
		var player := get_tree().get_first_node_in_group("player3d") as Node3D
		if player != null and flat_distance(player.global_position) < wake_radius:
			awake = true
			Audio.sfx("boss_wake")
			awakened.emit()
			hp_changed.emit(_hp, max_hp)
		return

	position = _center + Vector3(sin(_time * 0.6) * 3.0, 0.0, cos(_time * 0.4) * 1.5)

	if _telegraph > 0.0:
		_telegraph -= delta
		if _telegraph <= 0.0 and _form_timer <= 0.0:
			_set_form(
				GameState.WorldLayer.DIGITAL if form == GameState.WorldLayer.PHYSICAL else GameState.WorldLayer.PHYSICAL
			)
		return

	_form_timer -= delta
	if _form_timer <= 0.0:
		_telegraph = TELEGRAPH_SECONDS  # the flip happens when the telegraph ends
		Audio.sfx("boss_flip", -4.0)
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = ATTACK_SECONDS[phase - 1]
		_attack()


func _set_form(new_form: GameState.WorldLayer) -> void:
	form = new_form
	_form_timer = FORM_SECONDS[phase - 1]
	_refresh(GameState.current_layer)


func _attack() -> void:
	_attack_count += 1
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	var aim: Vector3 = Vector3(0, 0, 1)
	if player != null:
		aim = player.global_position - global_position
		aim.y = 0.0
		aim = aim.normalized()
	Audio.sfx("bolt", -6.0)
	var ring: bool = phase >= 2 and _attack_count % 2 == 0
	if ring:
		_fire_ring(8 if phase == 2 else 12, randf() * TAU)
	else:
		_fire_fan(aim, 3 if phase < 3 else 5)


func _fire_fan(aim: Vector3, count: int) -> void:
	for i: int in count:
		var angle: float = deg_to_rad(16.0) * (i - (count - 1) / 2.0)
		_fire(aim.rotated(Vector3.UP, angle))


func _fire_ring(count: int, offset: float) -> void:
	for i: int in count:
		_fire(Vector3(0, 0, 1).rotated(Vector3.UP, offset + TAU * i / count))


func _fire(direction: Vector3) -> void:
	var bolt := EnemyBolt3D.new()
	bolt.world = form
	bolt.speed = BOLT_SPEED[phase - 1]
	bolt.damage = 12 if phase < 3 else 15
	bolt.direction = direction
	bolt.position = global_position + direction * 1.4
	get_parent().add_child(bolt)
