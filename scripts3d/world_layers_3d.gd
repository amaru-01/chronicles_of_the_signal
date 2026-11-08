class_name WorldLayers3D
extends Node3D
## Builds the Physical and Digital worlds from a text map and owns the swap.
##
## Same map format as the 2D game (scenes/world/maps/*.txt):
##   #  wall in both worlds     .  floor in both worlds
##   P  wall in Physical only   D  wall in Digital only
## One map cell is TILE metres. Each world is a root node (visuals) plus a
## StaticBody3D (collision). Swapping toggles `visible` and the body's collision
## layer, the 3D equivalent of TileMapLayer.enabled.

signal layer_changed(layer: GameState.WorldLayer)
signal swap_blocked

const TILE: float = 2.0
const WALL_HEIGHT: float = 4.6
## Cut-away: wall blocks (and their props) between the low camera and the player are
## hidden. A block is hidden when it lies more than CUT_AHEAD metres toward the camera
## and inside a cone that widens with distance (CUT_BASE + dz * CUT_SPREAD).
const CUT_AHEAD: float = 0.6
const CUT_BASE: float = 3.2
const CUT_SPREAD: float = 0.55
const PHYSICAL_LAYER_BIT: int = 1 << 1  # 3D physics layer 2: world_physical
const DIGITAL_LAYER_BIT: int = 1 << 2   # 3D physics layer 3: world_digital

const BRICK: Shader = preload("res://shaders3d/brick.gdshader")
const WET_FLOOR: Shader = preload("res://shaders3d/wet_floor.gdshader")
const GRID: Shader = preload("res://shaders3d/digital_grid.gdshader")

@export_file("*.txt") var map_path: String = "res://scenes/world/maps/district_01.txt"

var map_size: Vector2i = Vector2i.ZERO
var physical_root: Node3D
var digital_root: Node3D

var _rows: PackedStringArray = PackedStringArray()
var _physical_body: StaticBody3D
var _digital_body: StaticBody3D
## Things that can be cut away: {node, x0, x1, z, layer}.
var _cut_items: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("layers3d")
	_load_map()
	physical_root = _build_world(GameState.WorldLayer.PHYSICAL)
	digital_root = _build_world(GameState.WorldLayer.DIGITAL)
	_apply_layer(GameState.current_layer)


## Register a node (a wall block or a prop on one) for the cut-away. `z` is the
## ground-plane depth used to decide whether it stands between camera and player.
func register_cutaway(node: Node3D, x0: float, x1: float, z: float, layer: GameState.WorldLayer) -> void:
	_cut_items.append({"node": node, "x0": x0, "x1": x1, "z": z, "layer": layer})


## Call every frame with the player's position (camera looks toward -z).
func update_cutaway(player_pos: Vector3) -> void:
	for item: Dictionary in _cut_items:
		if item["layer"] != GameState.current_layer:
			continue
		var dz: float = float(item["z"]) - player_pos.z
		var hide: bool = false
		if dz > CUT_AHEAD:
			var reach: float = CUT_BASE + dz * CUT_SPREAD
			hide = float(item["x1"]) > player_pos.x - reach and float(item["x0"]) < player_pos.x + reach
		var node: Node3D = item["node"]
		if node.visible == hide:
			node.visible = not hide


func world_size() -> Vector2:
	return Vector2(map_size.x, map_size.y) * TILE


## Map cell -> world position at the cell centre (y = 0).
func cell_to_world(cell: Vector2) -> Vector3:
	return Vector3((cell.x + 0.5) * TILE, 0.0, (cell.y + 0.5) * TILE)


func is_wall(layer: GameState.WorldLayer, cx: int, cy: int) -> bool:
	if cx < 0 or cy < 0 or cy >= _rows.size() or cx >= _rows[cy].length():
		return true
	match _rows[cy][cx]:
		"#":
			return true
		"P":
			return layer == GameState.WorldLayer.PHYSICAL
		"D":
			return layer == GameState.WorldLayer.DIGITAL
	return false


func char_at(cx: int, cy: int) -> String:
	if cx < 0 or cy < 0 or cy >= _rows.size() or cx >= _rows[cy].length():
		return "#"
	return _rows[cy][cx]


func toggle(player: Node3D = null) -> void:
	var target: GameState.WorldLayer = (
		GameState.WorldLayer.DIGITAL
		if GameState.current_layer == GameState.WorldLayer.PHYSICAL
		else GameState.WorldLayer.PHYSICAL
	)
	set_layer(target, player)


func set_layer(target: GameState.WorldLayer, player: Node3D = null) -> void:
	if target == GameState.current_layer:
		return
	# Same rule as the 2D game: refuse a swap that would bury the player in a wall.
	if player != null and _would_trap(target, player.global_position):
		swap_blocked.emit()
		return
	_apply_layer(target)
	layer_changed.emit(target)


func _apply_layer(layer: GameState.WorldLayer) -> void:
	var physical: bool = layer == GameState.WorldLayer.PHYSICAL
	physical_root.visible = physical
	digital_root.visible = not physical
	_physical_body.collision_layer = PHYSICAL_LAYER_BIT if physical else 0
	_digital_body.collision_layer = 0 if physical else DIGITAL_LAYER_BIT
	GameState.set_layer(layer)


func _would_trap(target: GameState.WorldLayer, pos: Vector3) -> bool:
	for node: Node in get_tree().get_nodes_in_group("doors3d"):
		var door := node as Door3D
		if door and door.blocks_swap(target, pos):
			return true
	var r: float = 0.4
	for offset: Vector2 in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var cx: int = floori((pos.x + offset.x) / TILE)
		var cy: int = floori((pos.z + offset.y) / TILE)
		if is_wall(target, cx, cy):
			return true
	return false


# --- map loading and geometry --------------------------------------------------

func _load_map() -> void:
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("WorldLayers3D: cannot open map %s" % map_path)
		return
	for row: String in file.get_as_text().strip_edges().split("\n"):
		_rows.append(row.strip_edges())
	map_size = Vector2i(_rows[0].length(), _rows.size())


func _build_world(layer: GameState.WorldLayer) -> Node3D:
	var root := Node3D.new()
	root.name = "Physical" if layer == GameState.WorldLayer.PHYSICAL else "Digital"
	add_child(root)

	var body := StaticBody3D.new()
	body.name = "Collision"
	body.collision_mask = 0
	root.add_child(body)
	if layer == GameState.WorldLayer.PHYSICAL:
		_physical_body = body
	else:
		_digital_body = body

	var wall_material: ShaderMaterial = _make_material(
		BRICK if layer == GameState.WorldLayer.PHYSICAL else GRID
	)
	if layer == GameState.WorldLayer.DIGITAL:
		# Walls get a brighter purple fill than the floor so they read as solid.
		wall_material.set_shader_parameter("fill_color", Color(0.09, 0.03, 0.26))
	_add_floor(root, layer)
	# Merge each horizontal run of wall cells into one box: far fewer nodes.
	for cy: int in map_size.y:
		var cx: int = 0
		while cx < map_size.x:
			if not is_wall(layer, cx, cy):
				cx += 1
				continue
			var start: int = cx
			while cx < map_size.x and is_wall(layer, cx, cy):
				cx += 1
			_add_wall_run(root, body, wall_material, start, cx - start, cy, layer)
	return root


func _add_wall_run(
	root: Node3D, body: StaticBody3D, material: ShaderMaterial, start: int, length: int, cy: int,
	layer: GameState.WorldLayer
) -> void:
	var size := Vector3(length * TILE, WALL_HEIGHT, TILE)
	var centre := Vector3((start + length / 2.0) * TILE, WALL_HEIGHT / 2.0, (cy + 0.5) * TILE)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = centre
	root.add_child(mesh)
	register_cutaway(mesh, start * TILE, (start + length) * TILE, cy * TILE, layer)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = centre
	body.add_child(shape)


func _add_floor(root: Node3D, layer: GameState.WorldLayer) -> void:
	var size: Vector2 = world_size()
	var mesh := MeshInstance3D.new()
	mesh.name = "Floor"
	var plane := PlaneMesh.new()
	plane.size = size
	mesh.mesh = plane
	mesh.position = Vector3(size.x / 2.0, 0.0, size.y / 2.0)
	mesh.material_override = _make_material(
		WET_FLOOR if layer == GameState.WorldLayer.PHYSICAL else GRID
	)
	root.add_child(mesh)


func _make_material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
