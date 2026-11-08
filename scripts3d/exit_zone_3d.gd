class_name ExitZone3D
extends Area3D
## A gateway to another district. Stepping into it travels to `target_district`, arriving
## at the spawn point named `target_spawn`. It can be locked until a terminal/switch id
## has been hacked.

@export var target_district: String = WorldMap3D.HUB
@export var target_spawn: String = ""
## Shown above the doorway by the district HUD (full resolution, so it stays readable).
@export var label_text: String = ""
## Empty = always open. Otherwise this terminal/switch id must be hacked first.
@export var requires_id: String = ""
@export var locked_lines: Array[String] = ["The way is sealed.", "Something nearby still holds it shut."]
@export var color: Color = Color(1.0, 0.85, 0.2)

var _cooldown: float = 0.0


func _ready() -> void:
	add_to_group("exit3d")
	collision_layer = 0
	collision_mask = Checkpoint3D.PLAYER_LAYER_BIT
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 3.0, 2.2)
	shape.shape = box
	shape.position.y = 1.5
	add_child(shape)
	body_entered.connect(_on_body_entered)

	# Two posts and a shimmering plane: reads as a doorway, in the colour of the way on.
	for x: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.22, 3.0, 0.22)
		post.mesh = post_mesh
		post.material_override = _glow(color, 3.0, 1.0)
		post.position = Vector3(x, 1.5, 0.0)
		add_child(post)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(2.2, 0.22, 0.22)
	lintel.mesh = lintel_mesh
	lintel.material_override = _glow(color, 3.0, 1.0)
	lintel.position = Vector3(0.0, 3.0, 0.0)
	add_child(lintel)
	var veil := MeshInstance3D.new()
	var veil_mesh := QuadMesh.new()
	veil_mesh.size = Vector2(1.8, 2.9)
	veil.mesh = veil_mesh
	var veil_material := _glow(color, 1.2, 0.3)
	veil_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil.material_override = veil_material
	veil.position = Vector3(0.0, 1.5, 0.0)
	add_child(veil)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func is_locked() -> bool:
	return requires_id != "" and not GameState.is_hacked(requires_id)


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0 or not body is Player3D:
		return
	_cooldown = 2.0
	if is_locked():
		Audio.sfx("hack_fail", -6.0)
		Dialogue.start("SYSTEM", locked_lines)
		return
	Audio.sfx("door")
	WorldMap3D.travel(target_district, target_spawn)


func _glow(glow_color: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(glow_color.r * 0.2, glow_color.g * 0.2, glow_color.b * 0.2, alpha)
	material.emission_enabled = true
	material.emission = glow_color
	material.emission_energy_multiplier = energy
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
