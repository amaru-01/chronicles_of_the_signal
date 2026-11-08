class_name Checkpoint3D
extends Area3D
## A beacon. Walking into it saves a respawn point for this district and unlocks it as
## a fast-travel destination. Visible in both worlds.

const PLAYER_LAYER_BIT: int = 1

## The district this beacon belongs to (set by District3D._add_beacon).
var district_id: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER_BIT
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.7
	shape.shape = sphere
	shape.position.y = 1.0
	add_child(shape)
	body_entered.connect(_on_body_entered)

	# Ring + translucent beam that reads at a distance.
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.1
	disc.bottom_radius = 1.1
	disc.height = 0.05
	disc.radial_segments = 20
	ring.mesh = disc
	ring.material_override = _glow(Color(0.2, 1.0, 0.9), 2.6, 1.0)
	ring.position.y = 0.04
	add_child(ring)
	var beam := MeshInstance3D.new()
	var column := CylinderMesh.new()
	column.top_radius = 0.35
	column.bottom_radius = 0.6
	column.height = 3.6
	column.radial_segments = 12
	beam.mesh = column
	beam.material_override = _glow(Color(0.2, 1.0, 0.9), 2.0, 0.28)
	beam.position.y = 1.8
	add_child(beam)
	var tween: Tween = beam.create_tween().set_loops()
	tween.tween_property(beam, "scale:x", 1.25, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(beam, "scale:z", 1.25, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(beam, "scale:x", 0.85, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(beam, "scale:z", 0.85, 1.0).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player3D:
		return
	var district: String = district_id if district_id != "" else GameState.current_district
	GameState.flags[WorldMap3D.fast_travel_flag(district)] = true
	GameState.set_checkpoint(district, Vector2(global_position.x, global_position.z))


func _glow(color: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
