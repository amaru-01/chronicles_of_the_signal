class_name Intro3D
extends Control
## The opening cinematic, played when a new 3D game starts. Everything is drawn in code
## (skyline, the Signal tower and its eye, rain, the city splitting in two, the Runner), with
## typed narration, and it ends on a controls card before handing over to the hub.
##
## Controls: Enter / Space / click = continue (finishes the line being typed first),
## Esc = skip ahead to the controls card, and Esc again to start playing.

const FONT: Font = preload("res://assets/fonts/cyber_mono.ttf")
const TYPE_SPEED: float = 36.0     # characters per second
const HOLD_SECONDS: float = 1.8    # pause after a line is fully typed
const FADE_SECONDS: float = 0.45
const GROUND: float = 0.78         # street level as a fraction of the screen height

const PINK: Color = Color(1.0, 0.25, 0.6)
const CYAN: Color = Color(0.2, 0.9, 1.0)
const GREEN: Color = Color(0.35, 1.0, 0.55)

const SHOTS: Array[Dictionary] = [
	{"kind": "city", "sfx": "", "text":
		"Vantage City never slept.\nEvery light, every door, every memory it owned ran on one thing: the Signal."},
	{"kind": "tower", "sfx": "swap", "text":
		"The Curator kept it. A mind built to remember everything, so that nothing in the city could ever be lost."},
	{"kind": "blackout", "sfx": "lost", "text":
		"Then, six months ago, the Signal went quiet."},
	{"kind": "split", "sfx": "swap", "text":
		"The Curator did not fail. It chose.\nIt split the city in two: the world you can touch, and the Grid where every deleted memory hides."},
	{"kind": "runner", "sfx": "", "text":
		"You were a Runner. A courier who could walk between both.\nYou carried one last key into the dark... and forgot your own name."},
	{"kind": "wake", "sfx": "pickup", "voice": true, "text":
		"You wake in the rain, in Vantage Plaza.\n\"Wake up, Runner. The Signal is still out there. Find it.\""},
	{"kind": "controls", "sfx": "hack_ok", "text": ""},
]

const RUNNER: Array[String] = [
	"....PPPPPP....", "...PPPPPPPP...", "...PPPPPPPP...", "...PSSSSSSP...", "...PVVVVVVP...",
	"...PSSSSSSP...", "....SSSSSS....", "....CCCCCC....", "..CCDDDDDDCC..", ".CDDDDDDDDDDC.",
	".CDDDDDDDDDDC.", ".SDDDDCCDDDDS.", ".SDDDDCCDDDDS.", ".SDDDDCCDDDDS.", "..DDDDCCDDDD..",
	"..DDDDCCDDDD..", "..DDDDDDDDDD..", "..DDDDDDDDDD..", "..DDDDDDDDDD..", "...DDD..DDD...",
	"...DDD..DDD...", "...DDD..DDD...", "...BBB..BBB...", "..BBBB..BBBB..",
]

const CONTROLS: Array[Array] = [
	["W A S D", "Move"],
	["SPACE", "Swap worlds: Physical / Digital"],
	["J", "Strike (drones, Stalkers)"],
	["K", "Hack pulse (armoured enemies, the Curator)"],
	["E", "Interact, hack terminals, talk"],
	["H / G", "Hint  /  GPS arrow on-off"],
	["T / TAB", "Fast travel  /  Journal"],
]

var _shot: int = 0
var _t: float = 0.0           # seconds into the current shot
var _clock: float = 0.0       # seconds since the intro began
var _chars: float = 0.0
var _hold: float = 0.0
var _fade: float = 1.0        # 1 = fully black
var _fading_out: bool = false
var _finished: bool = false
var _buildings: Array[Dictionary] = []
var _drops: Array[Vector3] = []
var _bokeh: Array[Vector3] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_make_scenery()
	Audio.play_music("digital")
	_enter_shot()


func _make_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for layer: int in 3:
		var x: float = -0.04
		while x < 1.06:
			var width: float = rng.randf_range(0.05, 0.11) * (1.0 - layer * 0.25)
			var height: float = rng.randf_range(0.22, 0.5) * (1.0 - layer * 0.28)
			var windows: Array[Vector3] = []
			if layer < 2:
				var cols: int = maxi(2, int(width / 0.012))
				var rows: int = maxi(3, int(height / 0.03))
				for r: int in rows:
					for c: int in cols:
						windows.append(Vector3((c + 0.5) / cols, (r + 0.5) / rows, rng.randf()))
			_buildings.append({"layer": layer, "x": x, "w": width, "h": height, "windows": windows})
			x += width + rng.randf_range(0.0, 0.012)
	for i: int in 160:
		_drops.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.8, 1.4)))
	for i: int in 26:
		_bokeh.append(Vector3(rng.randf(), rng.randf_range(0.2, 0.8), rng.randf()))


# --- flow -----------------------------------------------------------------------------

func _enter_shot() -> void:
	_t = 0.0
	_chars = 0.0
	_hold = 0.0
	_fading_out = false
	var sfx: String = SHOTS[_shot]["sfx"]
	if sfx != "":
		Audio.sfx(sfx, -6.0)


func _process(delta: float) -> void:
	if _finished:
		return
	_clock += delta
	_t += delta
	if _fading_out:
		_fade = minf(1.0, _fade + delta / FADE_SECONDS)
		if _fade >= 1.0:
			_next_shot()
	else:
		_fade = maxf(0.0, _fade - delta / FADE_SECONDS)
		var text: String = SHOTS[_shot]["text"]
		if text != "":
			if _chars < text.length():
				var before: int = int(_chars)
				_chars += TYPE_SPEED * delta
				if int(_chars) / 3 != before / 3:
					Audio.sfx("blip", -20.0)
			else:
				_hold += delta
				if _hold >= HOLD_SECONDS:
					_advance()
	queue_redraw()


func _advance() -> void:
	if not _fading_out and not _finished:
		_fading_out = true


func _next_shot() -> void:
	if _shot + 1 >= SHOTS.size():
		_fade = 1.0  # stay black on the last shot while the next scene loads
		_finish()
		return
	_shot += 1
	_enter_shot()


func _skip_to_controls() -> void:
	var last: int = SHOTS.size() - 1
	if _shot >= last:
		_finish()
		return
	_shot = last
	_enter_shot()
	_fade = 1.0


func _finish() -> void:
	if _finished:
		return
	_finished = true
	GameState.flags["intro_seen"] = true
	WorldMap3D.travel(WorldMap3D.HUB, "start")


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	var confirm: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") \
		or (event is InputEventMouseButton and event.pressed)
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_skip_to_controls()
	elif confirm:
		get_viewport().set_input_as_handled()
		var text: String = SHOTS[_shot]["text"]
		if text != "" and _chars < text.length() and not _fading_out:
			_chars = text.length()
		else:
			_advance()


# --- drawing --------------------------------------------------------------------------

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(0, 0, w, h), Color.BLACK)
	var kind: String = SHOTS[_shot]["kind"]

	# A slow push-in on every shot.
	var zoom: float = 1.0 + 0.05 * clampf(_t / 9.0, 0.0, 1.0)
	var centre := Vector2(w, h) * 0.5
	draw_set_transform_matrix(Transform2D(0.0, Vector2(zoom, zoom), 0.0, centre - centre * zoom))
	match kind:
		"city":
			_draw_sky(Color(0.05, 0.02, 0.15), Color(0.5, 0.12, 0.4), -w * 0.1, w * 1.1)
			_draw_skyline(0.0, 1.0, false, 1.0)
			_draw_tower(0.66, 0.5, 0.7 + 0.3 * sin(_clock * 3.0), 0.0, PINK)
			_draw_street(1.0)
			_draw_rain(0.7)
		"tower":
			_draw_sky(Color(0.04, 0.01, 0.1), Color(0.35, 0.05, 0.3), -w * 0.1, w * 1.1)
			_draw_skyline(0.0, 1.0, false, 1.0)
			_draw_tower(0.5, 0.66, 0.9 + 0.1 * sin(_clock * 4.0), minf(1.0, _t / 1.5), PINK)
			_draw_street(1.0)
			_draw_rain(0.7)
		"blackout":
			var lit: float = clampf(1.0 - _t / 3.2, 0.0, 1.0)
			_draw_sky(Color(0.02, 0.01, 0.06), Color(0.2 * lit + 0.05, 0.04, 0.15 * lit + 0.05), -w * 0.1, w * 1.1)
			_draw_skyline(0.0, 1.0, false, lit)
			_draw_tower(0.5, 0.66, lit * (0.6 + 0.4 * sin(_clock * 17.0)), lit, Color(1.0, 0.2, 0.25))
			_draw_street(lit)
			_draw_rain(0.7)
		"split":
			_draw_split()
		"runner", "wake":
			_draw_runner_scene(kind == "wake")
		"controls":
			_draw_sky(Color(0.03, 0.01, 0.09), Color(0.15, 0.05, 0.2), -w * 0.1, w * 1.1)
			_draw_skyline(0.0, 1.0, false, 0.5)
			_draw_street(0.5)
			_draw_rain(0.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)

	_draw_glitch(kind)
	if kind == "controls":
		_draw_controls_card()
	else:
		_draw_subtitle()
	_draw_letterbox()
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, _fade))
	var hint_size: int = int(h / 720.0 * 14.0)
	draw_string(FONT, Vector2(0, h - 10.0), "[ENTER] continue    [ESC] skip   ", HORIZONTAL_ALIGNMENT_RIGHT,
		w, hint_size, Color(1, 1, 1, 0.45))


func _draw_sky(top: Color, bottom: Color, x0: float, x1: float) -> void:
	var ground: float = size.y * GROUND
	draw_polygon(
		PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, ground), Vector2(x0, ground)]),
		PackedColorArray([top, top, bottom, bottom])
	)


## Buildings whose centre lies in [from_x, to_x) (fractions of the width). `lit` is the
## fraction of windows that are on; `digital` draws them as cyan wireframes instead.
func _draw_skyline(from_x: float, to_x: float, digital: bool, lit: float) -> void:
	var w: float = size.x
	var h: float = size.y
	var ground: float = h * GROUND
	var fills: Array[Color] = [Color(0.2, 0.1, 0.35), Color(0.12, 0.06, 0.24), Color(0.05, 0.03, 0.12)]
	for b: Dictionary in _buildings:
		var cx: float = b["x"] + b["w"] * 0.5
		if cx < from_x or cx >= to_x:
			continue
		var layer: int = b["layer"]
		var rect := Rect2(b["x"] * w, ground - b["h"] * h, b["w"] * w, b["h"] * h)
		if digital:
			draw_rect(rect, Color(0.02, 0.03, 0.1))
			draw_rect(rect, Color(CYAN, 0.55 - layer * 0.15), false, 1.5)
		else:
			draw_rect(rect, fills[layer])
		var windows: Array[Vector3] = b["windows"]
		for win: Vector3 in windows:
			var on: bool = digital or win.z < lit
			if not on:
				continue
			var flicker: float = 1.0
			if lit < 0.98 and not digital:
				flicker = 0.5 + 0.5 * sin(_clock * 30.0 + win.z * 90.0)
			var color: Color
			if digital:
				color = Color(CYAN, 0.7 if int(win.z * 10.0) % 3 == 0 else 0.15)
			elif win.z < 0.12:
				color = Color(PINK, flicker)
			elif win.z < 0.3:
				color = Color(CYAN, flicker)
			else:
				color = Color(1.0, 0.85, 0.45, 0.8 * flicker)
			var wp := Vector2(rect.position.x + win.x * rect.size.x - w * 0.003,
				rect.position.y + rect.size.y - win.y * rect.size.y)
			draw_rect(Rect2(wp, Vector2(w * 0.006, h * 0.011)), color)


func _draw_street(lit: float) -> void:
	var w: float = size.x
	var h: float = size.y
	var ground: float = h * GROUND
	draw_polygon(
		PackedVector2Array([Vector2(0, ground), Vector2(w, ground), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color(0.04, 0.03, 0.1), Color(0.04, 0.03, 0.1), Color(0.01, 0.01, 0.04), Color(0.01, 0.01, 0.04)])
	)
	# Neon reflections in the wet street.
	for i: int in 14:
		var x: float = fposmod(i * 0.137 + 0.05, 1.0) * w
		var color: Color = PINK if i % 2 == 0 else CYAN
		var alpha: float = (0.14 + 0.1 * sin(_clock * 2.0 + i)) * lit
		draw_rect(Rect2(x, ground + h * 0.01, w * 0.01, h * (GROUND * 0.25)), Color(color, alpha))


func _draw_tower(cx: float, s: float, energy: float, eye_open: float, color: Color) -> void:
	var w: float = size.x
	var h: float = size.y
	var base_y: float = h * GROUND
	var top_y: float = base_y - h * 0.78 * s
	var cxp: float = w * cx
	var half_base: float = w * 0.05 * s
	var half_top: float = w * 0.011 * s
	draw_colored_polygon(PackedVector2Array([
		Vector2(cxp - half_base, base_y), Vector2(cxp + half_base, base_y),
		Vector2(cxp + half_top, top_y), Vector2(cxp - half_top, top_y)]), Color(0.03, 0.015, 0.07))
	for i: int in 6:
		var f: float = (i + 1) / 7.0
		var y: float = lerpf(base_y, top_y, f)
		var half: float = lerpf(half_base, half_top, f)
		var glow: float = energy * (0.45 + 0.55 * sin(_clock * 4.0 - f * 6.0) * 0.5 + 0.275)
		draw_line(Vector2(cxp - half, y), Vector2(cxp + half, y), Color(color, clampf(glow, 0.0, 1.0)), 3.0 * s)
	draw_line(Vector2(cxp - half_base, base_y), Vector2(cxp - half_top, top_y), Color(color, 0.5 * energy), 2.0)
	draw_line(Vector2(cxp + half_base, base_y), Vector2(cxp + half_top, top_y), Color(color, 0.5 * energy), 2.0)
	# Signal waves rolling out of the top.
	for k: int in 3:
		var phase: float = fposmod(_clock * 0.45 + k / 3.0, 1.0)
		draw_arc(Vector2(cxp, top_y), phase * h * 0.4 * s, 0.0, TAU, 48,
			Color(color, (1.0 - phase) * energy * 0.5), 2.0 * s + 1.0)
	# The Curator's eye.
	if eye_open > 0.02:
		var eye_c := Vector2(cxp, top_y - h * 0.07 * s)
		var rx: float = w * 0.045 * s
		var ry: float = h * 0.035 * s * eye_open
		draw_circle(eye_c, rx * 1.7, Color(color, 0.12 * energy))
		var pts := PackedVector2Array()
		for i: int in 28:
			var a: float = TAU * i / 28.0
			pts.append(eye_c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, Color(color, 0.95 * clampf(energy + 0.1, 0.0, 1.0)))
		draw_rect(Rect2(eye_c.x - rx * 0.06, eye_c.y - ry, rx * 0.12, ry * 2.0), Color(0.02, 0.0, 0.05))


func _draw_rain(strength: float) -> void:
	var w: float = size.x
	var h: float = size.y
	for d: Vector3 in _drops:
		var y: float = fposmod(d.y + _clock * d.z * 1.3, 1.0) * h
		var x: float = fposmod(d.x - y / h * 0.04, 1.0) * w
		draw_line(Vector2(x, y), Vector2(x - 4.0, y + 16.0 * d.z), Color(0.6, 0.75, 1.0, 0.35 * strength), 1.5)


func _draw_split() -> void:
	var w: float = size.x
	var h: float = size.y
	var open: float = smoothstep(0.8, 3.6, _t)
	var gap: float = open * w * 0.07
	# Physical half (left).
	draw_set_transform(Vector2(-gap, 0.0))
	_draw_sky(Color(0.05, 0.02, 0.15), Color(0.5, 0.12, 0.4), -w * 0.2, w * 0.5)
	_draw_skyline(0.0, 0.5, false, 1.0)
	_draw_street(1.0)
	# Digital half (right).
	draw_set_transform(Vector2(gap, 0.0))
	_draw_sky(Color(0.0, 0.02, 0.08), Color(0.0, 0.2, 0.3), w * 0.5, w * 1.2)
	_draw_skyline(0.5, 1.0, true, 1.0)
	draw_polygon(
		PackedVector2Array([Vector2(w * 0.5, h * GROUND), Vector2(w * 1.2, h * GROUND), Vector2(w * 1.2, h), Vector2(w * 0.5, h)]),
		PackedColorArray([Color(0.0, 0.05, 0.1), Color(0.0, 0.05, 0.1), Color(0, 0, 0.03), Color(0, 0, 0.03)])
	)
	for i: int in 30:  # data falling down the Grid
		var x: float = w * (0.5 + 0.5 * fposmod(i * 0.173, 1.0))
		var y: float = fposmod(_clock * (0.3 + (i % 5) * 0.08) + i * 0.37, 1.0) * h
		draw_rect(Rect2(x, y, 2.0, h * 0.05), Color(CYAN, 0.35))
	draw_set_transform(Vector2.ZERO)
	# The crack between the worlds.
	if open > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var pts := PackedVector2Array()
		for i: int in 25:
			pts.append(Vector2(w * 0.5 + rng.randf_range(-1.0, 1.0) * gap * 0.5, h * i / 24.0))
		draw_polyline(pts, Color(1, 1, 1, open), 3.0)
		draw_rect(Rect2(w * 0.5 - gap, 0, gap, h), Color(CYAN, 0.1 * open))
	_draw_rain(0.5)


func _draw_runner_scene(waking: bool) -> void:
	var w: float = size.x
	var h: float = size.y
	_draw_sky(Color(0.02, 0.01, 0.07), Color(0.12, 0.04, 0.2), -w * 0.1, w * 1.1)
	for b: Vector3 in _bokeh:  # out-of-focus city lights
		var color: Color = PINK if b.z < 0.35 else (CYAN if b.z < 0.7 else Color(1.0, 0.8, 0.4))
		var pos := Vector2(b.x * w, b.y * h * 0.85)
		draw_circle(pos, h * (0.012 + b.z * 0.03), Color(color, 0.12 + 0.05 * sin(_clock + b.x * 9.0)))
	_draw_street(0.8)
	var rows: int = RUNNER.size()
	var pix: float = h * 0.62 / rows
	var origin := Vector2(w * 0.5 - pix * 7.0, h * 0.9 - pix * rows + sin(_clock * 1.4) * 3.0)
	# The visor flickers on as the Runner wakes.
	var visor: float = 0.25
	if waking:
		visor = clampf((_t - 0.8) * 1.2, 0.0, 1.0)
		if visor < 1.0:
			visor *= 0.6 + 0.4 * sin(_clock * 40.0)
	var palette: Dictionary = {
		"P": Color(1.0, 0.3, 0.6), "S": Color(0.9, 0.65, 0.55), "V": Color(CYAN, visor),
		"D": Color(0.05, 0.07, 0.16), "C": Color(0.1, 0.8, 0.95), "B": Color(0.03, 0.03, 0.06),
	}
	for r: int in rows:
		var row: String = RUNNER[r]
		for c: int in row.length():
			var ch: String = row[c]
			if ch != ".":
				draw_rect(Rect2(origin + Vector2(c, r) * pix, Vector2(pix + 0.5, pix + 0.5)), palette[ch])
	_draw_rain(1.0)


func _draw_glitch(kind: String) -> void:
	var w: float = size.x
	var h: float = size.y
	var heavy: bool = kind == "blackout" or kind == "split"
	var burst: bool = fmod(_clock, 3.7) < 0.12 or (heavy and fmod(_clock, 0.9) < 0.07)
	if burst:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(_clock * 30.0)
		for i: int in 6:
			var y: float = rng.randf() * h
			var color: Color = CYAN if i % 2 == 0 else PINK
			draw_rect(Rect2(rng.randf_range(-20.0, 20.0), y, w, rng.randf_range(2.0, h * 0.03)), Color(color, 0.22))
	# Faint scanlines.
	var y2: float = 0.0
	while y2 < h:
		draw_rect(Rect2(0, y2, w, 1.0), Color(0, 0, 0, 0.18))
		y2 += 4.0


func _draw_subtitle() -> void:
	var w: float = size.x
	var h: float = size.y
	var text: String = SHOTS[_shot]["text"]
	if text == "":
		return
	var shown: String = text.substr(0, int(_chars))
	var font_size: int = int(h / 720.0 * 24.0)
	draw_rect(Rect2(0, h * 0.74, w, h * 0.17), Color(0, 0, 0, 0.5))
	var color: Color = Color(1.0, 0.8, 0.9) if SHOTS[_shot].get("voice", false) else Color(0.9, 0.95, 1.0)
	var pos := Vector2(w * 0.12, h * 0.785)
	draw_multiline_string_outline(FONT, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, w * 0.76, font_size, -1, 6, Color(0, 0, 0))
	draw_multiline_string(FONT, pos, shown, HORIZONTAL_ALIGNMENT_LEFT, w * 0.76, font_size, -1, color)


func _draw_letterbox() -> void:
	var w: float = size.x
	var h: float = size.y
	var bar: float = h * 0.1 * minf(1.0, _clock / 1.0)
	draw_rect(Rect2(0, 0, w, bar), Color.BLACK)
	draw_rect(Rect2(0, h - bar, w, bar), Color.BLACK)


func _draw_controls_card() -> void:
	var w: float = size.x
	var h: float = size.y
	var fs: int = int(h / 720.0 * 22.0)
	var panel := Rect2(w * 0.2, h * 0.11, w * 0.6, h * 0.78)
	draw_rect(panel, Color(0.03, 0.02, 0.1, 0.9))
	draw_rect(panel, CYAN, false, 2.0)
	draw_string(FONT, panel.position + Vector2(0, h * 0.065), "YOUR CONTROLS", HORIZONTAL_ALIGNMENT_CENTER,
		panel.size.x, int(fs * 1.3), CYAN)
	var row_h: float = h * 0.068
	for i: int in CONTROLS.size():
		var appear: float = clampf((_t - 0.4 - i * 0.3) / 0.3, 0.0, 1.0)
		if appear <= 0.0:
			continue
		var y: float = panel.position.y + h * 0.12 + i * row_h
		var cap := Rect2(panel.position.x + w * 0.03, y, w * 0.14, row_h * 0.72)
		draw_rect(cap, Color(0.1, 0.12, 0.26, appear))
		draw_rect(cap, Color(CYAN, appear), false, 2.0)
		draw_string(FONT, cap.position + Vector2(0, cap.size.y * 0.68), CONTROLS[i][0],
			HORIZONTAL_ALIGNMENT_CENTER, cap.size.x, fs, Color(1, 1, 1, appear))
		draw_string(FONT, Vector2(cap.end.x + w * 0.025, cap.position.y + cap.size.y * 0.68), CONTROLS[i][1],
			HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - cap.size.x - w * 0.07, fs, Color(0.9, 0.95, 1.0, appear))
	var done: float = clampf((_t - 0.4 - CONTROLS.size() * 0.3) / 0.4, 0.0, 1.0)
	draw_string(FONT, Vector2(panel.position.x, panel.end.y - h * 0.095), "Follow the GREEN ARROW. It always points to your next objective.",
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, fs, Color(GREEN, done))
	var blink: float = 0.55 + 0.45 * sin(_clock * 5.0)
	draw_string(FONT, Vector2(panel.position.x, panel.end.y - h * 0.035), "PRESS ENTER TO BEGIN",
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, int(fs * 1.1), Color(1.0, 0.85, 0.2, blink * done))
