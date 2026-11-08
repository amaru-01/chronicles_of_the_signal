class_name Minimap3D
extends Control
## Corner map of the current district. Shows the walls of the *current world* (so the
## Physical and Digital layouts differ, like the real thing), the player, active
## enemies, beacons and exits. The two wall images are built once from the text map.

const CELL_PX: int = 3
const REDRAW_INTERVAL: float = 0.1

var _layers: WorldLayers3D
var _player: Node3D
var _textures: Dictionary = {}  # WorldLayer -> ImageTexture
var _timer: float = 0.0
## World position of the GPS goal (Vector3) or null; drawn as a pulsing green diamond.
var gps_target: Variant = null


func setup(layers: WorldLayers3D, player: Node3D) -> void:
	_layers = layers
	_player = player
	custom_minimum_size = Vector2(layers.map_size.x, layers.map_size.y) * CELL_PX + Vector2(4, 4)
	size = custom_minimum_size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_textures[GameState.WorldLayer.PHYSICAL] = _build_texture(GameState.WorldLayer.PHYSICAL)
	_textures[GameState.WorldLayer.DIGITAL] = _build_texture(GameState.WorldLayer.DIGITAL)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = REDRAW_INTERVAL
		queue_redraw()


func _draw() -> void:
	if _layers == null:
		return
	var origin := Vector2(2, 2)
	var area := Vector2(_layers.map_size.x, _layers.map_size.y) * CELL_PX
	draw_rect(Rect2(Vector2.ZERO, area + Vector2(4, 4)), Color(0, 0, 0, 0.55))
	draw_texture_rect(_textures[GameState.current_layer], Rect2(origin, area), false)
	var edge: Color = (
		Color(0.2, 0.9, 1.0, 0.9) if GameState.current_layer == GameState.WorldLayer.DIGITAL
		else Color(1.0, 0.3, 0.6, 0.9)
	)
	draw_rect(Rect2(Vector2.ZERO, area + Vector2(4, 4)), edge, false, 1.0)

	for node: Node in get_tree().get_nodes_in_group("beacon3d"):
		_dot(origin, node as Node3D, Color(0.2, 1.0, 0.9), 4)
	for node: Node in get_tree().get_nodes_in_group("exit3d"):
		_dot(origin, node as Node3D, Color(1.0, 0.85, 0.2), 4)
	for node: Node in get_tree().get_nodes_in_group("enemy3d"):
		var enemy := node as Enemy3D
		if enemy and enemy.active:
			_dot(origin, enemy, Color(1.0, 0.25, 0.3), 3)
	if gps_target is Vector3:
		var goal: Vector3 = gps_target
		var gp := origin + Vector2(goal.x, goal.z) / WorldLayers3D.TILE * CELL_PX
		var r: float = 4.0 + sin(Time.get_ticks_msec() / 150.0) * 1.2
		draw_colored_polygon(PackedVector2Array([
			gp + Vector2(0, -r), gp + Vector2(r, 0), gp + Vector2(0, r), gp + Vector2(-r, 0)]),
			Color(0.35, 1.0, 0.55))
	if is_instance_valid(_player):
		_dot(origin, _player, Color.WHITE, 5)


func _dot(origin: Vector2, node: Node3D, color: Color, dot_size: int) -> void:
	if node == null:
		return
	var p := Vector2(node.global_position.x, node.global_position.z) / WorldLayers3D.TILE * CELL_PX
	draw_rect(Rect2(origin + p - Vector2(dot_size, dot_size) / 2.0, Vector2(dot_size, dot_size)), color)


func _build_texture(layer: GameState.WorldLayer) -> ImageTexture:
	var image := Image.create(_layers.map_size.x, _layers.map_size.y, false, Image.FORMAT_RGBA8)
	var wall: Color = (
		Color(0.55, 0.2, 0.45) if layer == GameState.WorldLayer.PHYSICAL else Color(0.0, 0.6, 0.75)
	)
	var floor_color := Color(0.06, 0.05, 0.14, 0.9)
	for y: int in _layers.map_size.y:
		for x: int in _layers.map_size.x:
			image.set_pixel(x, y, wall if _layers.is_wall(layer, x, y) else floor_color)
	return ImageTexture.create_from_image(image)
