class_name Player3D
extends CharacterBody3D
## Third-person ground-plane player. Moves relative to the fixed camera, shows the
## existing 2D sprite sheet as an upright billboard, interacts (E) and strikes (J).
##
## Input events are handled by the district (the player lives in a SubViewport, which
## does not receive them); this node only polls Input for movement.

signal target_changed(target: Interactable3D)

const SPEED: float = 7.0
const SHEET: Texture2D = preload("res://assets3d/sprites/player_3d.png")
const DIRECTIONS: Array[String] = ["down", "left", "right", "up"]  # sheet row order
const WALK_FPS: float = 9.0
const ATTACK_RANGE: float = 2.6
const ATTACK_COOLDOWN: float = 0.35

## Camera yaw in degrees; movement is rotated by this so "up" is always screen-up.
var camera_yaw: float = 0.0

var _sprite: Sprite3D
var _interact_area: Area3D
var _nearby: Array[Interactable3D] = []
var _target: Interactable3D
var _facing: Vector3 = Vector3(0, 0, 1)
var _row: int = 0
var _anim_time: float = 0.0
var _step_timer: float = 0.0
var _attack_timer: float = 0.0
var _pulse_timer: float = 0.0


func _ready() -> void:
	add_to_group("player3d")
	collision_layer = 1  # player
	collision_mask = WorldLayers3D.PHYSICAL_LAYER_BIT | WorldLayers3D.DIGITAL_LAYER_BIT
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = 0.95
	add_child(shape)

	# 5x4 sheet of 48x80 cells (2 m tall): columns idle + 4 walk frames, rows down/left/right/up.
	_sprite = Interactable3D.make_billboard(SHEET, 5, 4)
	add_child(_sprite)

	add_child(_make_blob_shadow())

	_interact_area = Area3D.new()
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = Interactable3D.INTERACTABLE_LAYER_BIT
	_interact_area.monitorable = false
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.0
	reach.shape = sphere
	reach.position.y = 0.9
	_interact_area.add_child(reach)
	add_child(_interact_area)
	_interact_area.area_entered.connect(_on_area_entered)
	_interact_area.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if not (Dialogue.is_active or GameState.minigame_active):
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, deg_to_rad(camera_yaw))
	velocity = direction * SPEED * Items3D.speed_multiplier()
	move_and_slide()
	position.y = 0.0

	if input.length() > 0.1:
		_facing = direction.normalized()
		# Pick the sheet row from the screen-relative input, not the world direction.
		if absf(input.x) > absf(input.y):
			_row = 1 if input.x < 0.0 else 2
		else:
			_row = 3 if input.y < 0.0 else 0
		_anim_time += delta
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.32
			Audio.sfx("step", -8.0)
	else:
		_anim_time = 0.0
	var column: int = 1 + int(_anim_time * WALK_FPS) % 4 if input.length() > 0.1 else 0
	_sprite.frame_coords = Vector2i(column, _row)

	_attack_timer = maxf(0.0, _attack_timer - delta)
	_pulse_timer = maxf(0.0, _pulse_timer - delta)
	_update_target()


func try_interact() -> void:
	if is_instance_valid(_target):
		_target.interact(self)


## Melee strike: hits enemies in a cone in front of the player.
func attack() -> void:
	if _attack_timer > 0.0 or Dialogue.is_active or GameState.minigame_active:
		return
	_attack_timer = ATTACK_COOLDOWN
	Audio.sfx("swap", -14.0)
	_spawn_slash()
	for node: Node in get_tree().get_nodes_in_group("enemy3d"):
		var enemy := node as Enemy3D
		if enemy == null or not enemy.active:
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() > ATTACK_RANGE:
			continue
		if to_enemy.length() < 0.2 or _facing.dot(to_enemy.normalized()) > 0.2:
			enemy.take_hit(Items3D.strike_damage(), global_position, "melee")


## Hack pulse: a ranged bolt along the facing direction.
func fire_pulse() -> void:
	if _pulse_timer > 0.0 or Dialogue.is_active or GameState.minigame_active:
		return
	_pulse_timer = Items3D.pulse_cooldown()
	Audio.sfx("pickup", -6.0)
	var bolt := Pulse3D.new()
	bolt.direction = _facing
	bolt.damage = Items3D.pulse_damage()
	bolt.position = global_position + _facing * 0.9 + Vector3(0.0, 1.2, 0.0)
	get_parent().add_child(bolt)


## Red flash when the player takes damage.
func hurt_flash() -> void:
	_sprite.modulate = Color(3.0, 0.5, 0.5)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.3)


func get_target() -> Interactable3D:
	return _target


func _update_target() -> void:
	var best: Interactable3D = null
	var best_distance: float = INF
	for candidate: Interactable3D in _nearby:
		if not is_instance_valid(candidate):
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	if best != _target:
		_target = best
		target_changed.emit(_target)


func _on_area_entered(area: Area3D) -> void:
	var interactable := area as Interactable3D
	if interactable and not _nearby.has(interactable):
		_nearby.append(interactable)


func _on_area_exited(area: Area3D) -> void:
	var interactable := area as Interactable3D
	if interactable:
		_nearby.erase(interactable)


func _spawn_slash() -> void:
	var slash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, 1.6)
	slash.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.4, 1.0, 1.0, 0.85)
	material.albedo_texture = _slash_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	slash.material_override = material
	slash.rotation = Vector3(-PI / 2.0, atan2(-_facing.x, -_facing.z), 0.0)
	slash.position = _facing * 1.3 + Vector3(0, 0.9, 0)
	add_child(slash)
	slash.top_level = true
	slash.global_position = global_position + _facing * 1.3 + Vector3(0, 0.9, 0)
	var tween: Tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.18)
	tween.finished.connect(slash.queue_free)


func _slash_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture


func _make_blob_shadow() -> MeshInstance3D:
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	shadow.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0, 0, 0, 0.55)
	material.albedo_texture = _slash_texture()
	shadow.material_override = material
	shadow.rotation.x = -PI / 2.0
	shadow.position.y = 0.02
	return shadow
