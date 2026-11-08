class_name EnemyBolt3D
extends Node3D
## A bolt fired by an enemy. It exists only in the world it was fired in: swap worlds and
## it vanishes (and cannot hurt you), swap back and it is still coming. Stops at walls of
## that world. A Physical bolt costs HP, a Digital bolt costs signal integrity.

const HIT_RADIUS: float = 0.8
const HEIGHT: float = 1.2

var direction: Vector3 = Vector3(0, 0, 1)
var speed: float = 7.0
var damage: int = 12
var world: GameState.WorldLayer = GameState.WorldLayer.PHYSICAL
var lifetime: float = 6.0

var _age: float = 0.0
var _layers: WorldLayers3D


func _ready() -> void:
	add_to_group("enemy_bolt3d")
	_layers = get_tree().get_first_node_in_group("layers3d") as WorldLayers3D
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.24
	sphere.height = 0.48
	sphere.radial_segments = 10
	sphere.rings = 5
	orb.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.03, 0.02, 0.02)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.45, 0.1) if world == GameState.WorldLayer.PHYSICAL else Color(1.0, 0.2, 0.9)
	material.emission_energy_multiplier = 4.5
	orb.material_override = material
	add_child(orb)
	position.y = HEIGHT
	visible = GameState.current_layer == world


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > lifetime:
		queue_free()
		return
	global_position += direction * speed * delta
	visible = GameState.current_layer == world
	if _layers:
		var cx: int = floori(global_position.x / WorldLayers3D.TILE)
		var cy: int = floori(global_position.z / WorldLayers3D.TILE)
		if _layers.is_wall(world, cx, cy):
			queue_free()
			return
	if not visible or Dialogue.is_active or GameState.minigame_active:
		return
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player == null:
		return
	var flat := Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z)
	if flat.length() < HIT_RADIUS:
		Audio.sfx("hit")
		if world == GameState.WorldLayer.PHYSICAL:
			GameState.damage_health(Items3D.physical_damage(damage))
		else:
			GameState.damage_signal(Items3D.signal_damage(damage))
		queue_free()
