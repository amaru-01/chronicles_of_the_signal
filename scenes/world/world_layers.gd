class_name WorldLayers
extends Node2D
## Owns the Physical <-> Digital toggle (port of LayerManager).
##
## Each world is a TileMapLayer. Setting `enabled = false` on a layer hides it
## AND removes its collision, so one flag swaps both visuals and physics.
## Needs Godot 4.3+ (TileMapLayer).
##
## TEST-ROOM ONLY: the tilesets are built from the PNGs in assets/tiles and the
## room is laid out in code. Replace `_build_test_room()` with real TileMapLayer
## nodes authored in the editor when you build District 01.

signal layer_changed(layer: GameState.WorldLayer)
signal swap_blocked

const TILE_SIZE: int = 32
const ROOM_SIZE: Vector2i = Vector2i(40, 20)
const PHYSICAL_COLLISION_BIT: int = 2  # physics layer "world_physical"
const DIGITAL_COLLISION_BIT: int = 3   # physics layer "world_digital"

const TILE_WALL: Vector2i = Vector2i(0, 0)
const TILE_FLOOR: Vector2i = Vector2i(1, 0)
const TILE_FLOOR_ALT: Vector2i = Vector2i(2, 0)

const PHYSICAL_TILES: Texture2D = preload("res://assets/tiles/physical_tiles.png")
const DIGITAL_TILES: Texture2D = preload("res://assets/tiles/digital_tiles.png")

@export var player: Player

var physical: TileMapLayer
var digital: TileMapLayer


func _ready() -> void:
	physical = _make_layer(PHYSICAL_TILES, PHYSICAL_COLLISION_BIT)
	digital = _make_layer(DIGITAL_TILES, DIGITAL_COLLISION_BIT)
	physical.name = "Physical"
	digital.name = "Digital"
	add_child(physical)
	add_child(digital)
	_build_test_room()
	_apply_layer(GameState.current_layer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_layer") and not Dialogue.is_active:
		toggle()


func toggle() -> void:
	var target: GameState.WorldLayer = (
		GameState.WorldLayer.DIGITAL
		if GameState.current_layer == GameState.WorldLayer.PHYSICAL
		else GameState.WorldLayer.PHYSICAL
	)
	set_layer(target)


func set_layer(target: GameState.WorldLayer) -> void:
	if target == GameState.current_layer:
		return
	# DESIGN DECISION: block the swap if it would put the player inside a wall.
	# Alternatives: push the player out, or damage them as a game mechanic.
	if player != null and _would_trap_player(target):
		swap_blocked.emit()
		return
	_apply_layer(target)
	layer_changed.emit(target)


func _apply_layer(layer: GameState.WorldLayer) -> void:
	physical.enabled = layer == GameState.WorldLayer.PHYSICAL
	digital.enabled = layer == GameState.WorldLayer.DIGITAL
	GameState.set_layer(layer)  # emits GameState.layer_changed for interactables


func _layer_node(layer: GameState.WorldLayer) -> TileMapLayer:
	return physical if layer == GameState.WorldLayer.PHYSICAL else digital


func _would_trap_player(target: GameState.WorldLayer) -> bool:
	if _is_player_inside_wall(_layer_node(target)):
		return true
	var player_rect: Rect2 = player.get_rect()
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		var interactable := node as Interactable
		if interactable and interactable.blocks_swap(target, player_rect):
			return true
	return false


func _is_player_inside_wall(target: TileMapLayer) -> bool:
	for corner: Vector2 in player.get_corners():
		var cell: Vector2i = target.local_to_map(target.to_local(corner))
		if target.get_cell_atlas_coords(cell) == TILE_WALL:
			return true
	return false


# --- test-room generation ----------------------------------------------------

func _make_layer(texture: Texture2D, collision_bit: int) -> TileMapLayer:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1 << (collision_bit - 1))
	tile_set.set_physics_layer_collision_mask(0, 0)

	# 3-tile atlas: [wall][floor][floor variant]
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(TILE_WALL)
	source.create_tile(TILE_FLOOR)
	source.create_tile(TILE_FLOOR_ALT)
	tile_set.add_source(source, 0)

	var half: float = TILE_SIZE / 2.0
	var data: TileData = source.get_tile_data(TILE_WALL, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	]))

	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	return layer


func _build_test_room() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # same floor pattern in both worlds
	for x: int in ROOM_SIZE.x:
		for y: int in ROOM_SIZE.y:
			var border: bool = x == 0 or y == 0 or x == ROOM_SIZE.x - 1 or y == ROOM_SIZE.y - 1
			var floor_tile: Vector2i = TILE_FLOOR_ALT if rng.randf() < 0.18 else TILE_FLOOR
			var tile: Vector2i = TILE_WALL if border else floor_tile
			physical.set_cell(Vector2i(x, y), 0, tile)
			digital.set_cell(Vector2i(x, y), 0, tile)

	# Physical: a divider across the room with a gap (filled by the Door).
	for y: int in range(1, ROOM_SIZE.y - 1):
		if y != 9 and y != 10:
			physical.set_cell(Vector2i(20, y), 0, TILE_WALL)
	# Digital: no divider, but a solid block on the left side.
	for x: int in range(8, 14):
		for y: int in range(8, 12):
			digital.set_cell(Vector2i(x, y), 0, TILE_WALL)
