class_name Pickup3D
extends Interactable3D
## A memory fragment: a bobbing hologram orb. Remembers it was taken (flags) so it stays
## gone after a reload.

@export var item_id: String = "fragment_01"
@export var item_name: String = "Memory Fragment"
@export var memory_lines: Array[String] = []
## Set this flag on pickup (e.g. "found_cache" for a hidden-area quest).
@export var set_flag: String = ""

var _orb: MeshInstance3D


func _ready() -> void:
	if GameState.flags.has("picked_" + item_id):
		queue_free()
		return
	prompt_text = "COLLECT"
	super()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	shape.position.y = 0.9
	add_child(shape)

	_orb = MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.3
	orb_mesh.height = 0.6
	orb_mesh.radial_segments = 12
	orb_mesh.rings = 6
	_orb.mesh = orb_mesh
	_orb.material_override = _glow(Color(0.9, 0.3, 1.0), 3.5)
	_orb.position.y = 1.1
	add_child(_orb)
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.04
	disc.radial_segments = 16
	ring.mesh = disc
	ring.material_override = _glow(Color(0.1, 0.9, 1.0), 2.4)
	ring.position.y = 0.03
	add_child(ring)
	var tween: Tween = _orb.create_tween().set_loops()
	tween.tween_property(_orb, "position:y", 1.4, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_orb, "position:y", 0.9, 0.9).set_trans(Tween.TRANS_SINE)


func interact(_player: Node3D) -> void:
	Audio.sfx("pickup")
	GameState.add_item(item_id)
	GameState.flags["picked_" + item_id] = true
	if set_flag != "":
		GameState.flags[set_flag] = true
	if not memory_lines.is_empty():
		GameState.flags["memory_" + item_id] = "  ".join(memory_lines)  # re-readable in the journal
	var lines: Array[String] = ["Collected: %s." % Items3D.name_of(item_id) if Items3D.ITEMS.has(item_id) else "Collected: %s." % item_name]
	lines.append_array(memory_lines)
	Dialogue.start("MEMORY" if not memory_lines.is_empty() else "", lines)
	queue_free()


func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.02, 0.02, 0.03)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
