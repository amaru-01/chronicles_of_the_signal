class_name Door3D
extends StaticBody3D
## A gate in the Physical world's wall. It blocks the Physical world only (the Grid
## has no wall here, which is the puzzle), until `required_terminal` is hacked, then
## it sinks into the floor.

const SIZE: Vector3 = Vector3(0.6, 4.6, 4.0)

@export var required_terminal: String = "term_gate"

var _mesh: MeshInstance3D
var _open: bool = false


func _ready() -> void:
	collision_mask = 0

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = SIZE
	shape.shape = box_shape
	shape.position.y = SIZE.y / 2.0
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = SIZE
	_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.02, 0.12)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.15, 0.6)
	material.emission_energy_multiplier = 1.4
	_mesh.material_override = material
	_mesh.position.y = SIZE.y / 2.0
	add_child(_mesh)

	GameState.terminal_hacked.connect(_on_terminal_hacked)
	GameState.layer_changed.connect(func(_layer: GameState.WorldLayer) -> void: _refresh())
	if GameState.is_hacked(required_terminal):
		_open = true
		_mesh.position.y = -SIZE.y
	_refresh()


func _on_terminal_hacked(terminal_id: String) -> void:
	if terminal_id != required_terminal or _open:
		return
	_open = true
	_refresh()
	Audio.sfx("hack_ok", -4.0)
	var tween: Tween = create_tween()
	tween.tween_property(_mesh, "position:y", -SIZE.y, 0.8).set_trans(Tween.TRANS_CUBIC)


func _refresh() -> void:
	var physical: bool = GameState.current_layer == GameState.WorldLayer.PHYSICAL
	visible = physical
	collision_layer = WorldLayers3D.PHYSICAL_LAYER_BIT if (physical and not _open) else 0
