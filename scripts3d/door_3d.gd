class_name Door3D
extends StaticBody3D
## A gate filling a gap in a wall (it runs along the z axis, `span` metres long). It
## stays solid until `required_terminal` AND every id in `extra_required` are hacked or
## switched on, then sinks into the floor. If one of them switches itself off again (a
## timed Switch3D) the gate rises again, but never on top of the player.
## `realm` picks which world(s) the gate exists and blocks in.

const THICKNESS: float = 0.6

@export var required_terminal: String = ""
@export var extra_required: Array[String] = []
@export var realm: Interactable3D.Realm = Interactable3D.Realm.PHYSICAL
@export var span: float = 4.0

var _mesh: MeshInstance3D
var _open: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("doors3d")
	collision_mask = 0
	var size := Vector3(THICKNESS, WorldLayers3D.WALL_HEIGHT, span)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position.y = size.y / 2.0
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.02, 0.12)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.15, 0.6)
	material.emission_energy_multiplier = 1.4
	_mesh.material_override = material
	_mesh.position.y = size.y / 2.0
	add_child(_mesh)

	_open = _all_met()
	if _open:
		_mesh.position.y = -size.y
	GameState.terminal_hacked.connect(func(_id: String) -> void: _on_state_changed())
	GameState.terminal_reset.connect(func(_id: String) -> void: _on_state_changed())
	GameState.layer_changed.connect(func(_layer: GameState.WorldLayer) -> void: _refresh())
	set_process(false)
	_refresh()


func _all_met() -> bool:
	if required_terminal != "" and not GameState.is_hacked(required_terminal):
		return false
	for id: String in extra_required:
		if not GameState.is_hacked(id):
			return false
	return true


## True if this gate would be solid in `target` and overlaps the player at `pos`
## (used by WorldLayers3D to refuse a swap that would trap the player in the gate).
func blocks_swap(target: GameState.WorldLayer, pos: Vector3) -> bool:
	if _open or not Interactable3D.realm_active(realm, target):
		return false
	return _overlaps(pos, 0.45)


func _overlaps(pos: Vector3, margin: float) -> bool:
	return (
		absf(pos.x - global_position.x) < THICKNESS / 2.0 + margin
		and absf(pos.z - global_position.z) < span / 2.0 + margin
	)


func _on_state_changed() -> void:
	if _all_met() and not _open:
		_set_open(true)
	elif not _all_met() and _open:
		set_process(true)  # close as soon as the doorway is clear


func _process(_delta: float) -> void:
	if _all_met():
		set_process(false)
		return
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player != null and _overlaps(player.global_position, 0.8):
		return  # never close on top of the player
	_set_open(false)
	set_process(false)


func _set_open(value: bool) -> void:
	_open = value
	Audio.sfx("door")
	_refresh()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var rest: float = WorldLayers3D.WALL_HEIGHT / 2.0
	_tween.tween_property(_mesh, "position:y", -WorldLayers3D.WALL_HEIGHT if value else rest, 0.7) \
		.set_trans(Tween.TRANS_CUBIC)


func _refresh() -> void:
	var in_world: bool = Interactable3D.realm_active(realm, GameState.current_layer)
	visible = in_world
	var world_bit: int = (
		WorldLayers3D.PHYSICAL_LAYER_BIT
		if GameState.current_layer == GameState.WorldLayer.PHYSICAL
		else WorldLayers3D.DIGITAL_LAYER_BIT
	)
	collision_layer = world_bit if (in_world and not _open) else 0
