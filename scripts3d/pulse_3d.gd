class_name Pulse3D
extends Node3D
## The hack pulse: a fast glowing bolt of signal fired by the player. Stops at walls
## of the current world and damages the first enemy it touches.

const SPEED: float = 18.0
const LIFETIME: float = 0.9
const DAMAGE: int = 2
const HIT_RADIUS: float = 1.0

var direction: Vector3 = Vector3(0, 0, -1)

var _age: float = 0.0


func _ready() -> void:
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	sphere.radial_segments = 10
	sphere.rings = 5
	orb.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.02, 0.05, 0.08)
	material.emission_enabled = true
	material.emission = Color(0.2, 1.0, 1.0)
	material.emission_energy_multiplier = 5.0
	orb.material_override = material
	add_child(orb)
	# Short tail so the bolt reads as motion at the low render resolution.
	var tail := MeshInstance3D.new()
	var streak := BoxMesh.new()
	streak.size = Vector3(0.1, 0.1, 0.9)
	tail.mesh = streak
	tail.material_override = material
	tail.position = Vector3(0, 0, 0.55)
	add_child(tail)
	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	global_position += direction * SPEED * delta

	var layers := get_tree().get_first_node_in_group("layers3d") as WorldLayers3D
	if layers:
		var cx: int = floori(global_position.x / WorldLayers3D.TILE)
		var cy: int = floori(global_position.z / WorldLayers3D.TILE)
		if layers.is_wall(GameState.current_layer, cx, cy):
			queue_free()
			return
	for node: Node in get_tree().get_nodes_in_group("enemy3d"):
		var enemy := node as Enemy3D
		if enemy and enemy.active and enemy.flat_distance(global_position) < HIT_RADIUS:
			enemy.take_hit(DAMAGE, global_position - direction, "pulse")
			queue_free()
			return
