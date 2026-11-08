class_name Gps3D
extends Control
## The GPS: a green arrow that orbits the player on screen and points the way to the
## current objective, with the distance and a short label. The district computes the
## target and the screen-space direction and calls show_arrow(); this class only draws.

const ARROW_COLOR: Color = Color(0.35, 1.0, 0.55)
const RADIUS: float = 118.0

var _centre: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.UP
var _text: String = ""
var _shown: bool = false
var _time: float = 0.0
var _font: Font = load("res://assets/fonts/cyber_mono.ttf")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## centre: the player's position on screen; direction: unit vector on screen.
func show_arrow(centre: Vector2, direction: Vector2, text: String) -> void:
	_centre = centre
	_direction = direction
	_text = text
	_shown = true
	queue_redraw()


func hide_arrow() -> void:
	if _shown:
		_shown = false
		queue_redraw()


func is_showing() -> bool:
	return _shown


func _process(delta: float) -> void:
	_time += delta
	if _shown:
		queue_redraw()


func _draw() -> void:
	if not _shown:
		return
	# The arrow slides in and out a little so it reads as "this way".
	var pulse: float = sin(_time * 5.0) * 7.0
	var tip: Vector2 = _centre + _direction * (RADIUS + pulse)
	var side: Vector2 = _direction.orthogonal()
	var points := PackedVector2Array([
		tip + _direction * 32.0,
		tip - _direction * 16.0 + side * 26.0,
		tip - _direction * 4.0,
		tip - _direction * 16.0 - side * 26.0,
	])
	var shadow := PackedVector2Array()
	for p: Vector2 in points:
		shadow.append(p + Vector2(2, 3))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.55))
	draw_colored_polygon(points, ARROW_COLOR)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.02, 0.15, 0.08), 2.0)

	# The label sits beyond the arrow, on the side away from the player, kept on screen.
	var size: Vector2 = get_viewport_rect().size
	var label_pos: Vector2 = tip + _direction * 44.0
	label_pos.y = clampf(label_pos.y + 8.0, 60.0, size.y - 60.0)
	var width: float = 460.0
	var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
	var left: float = label_pos.x - width * 0.5
	if _direction.x < -0.35:
		align = HORIZONTAL_ALIGNMENT_RIGHT
		left = label_pos.x - width
	elif _direction.x > 0.35:
		align = HORIZONTAL_ALIGNMENT_LEFT
		left = label_pos.x
	left = clampf(left, 8.0, size.x - width - 8.0)
	draw_string_outline(_font, Vector2(left, label_pos.y), _text, align, width, 18, 6, Color(0.02, 0.0, 0.06))
	draw_string(_font, Vector2(left, label_pos.y), _text, align, width, 18, ARROW_COLOR)
