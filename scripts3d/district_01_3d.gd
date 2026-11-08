class_name District3D
extends Node
## Phase 1 prototype: District 01 (Static Row) in 3D.
##
## The 3D scene renders into a small SubViewport (VIEW_SIZE) that is upscaled with
## nearest-neighbour filtering for the pixel-art look. The HUD, effects and the
## swap wipe live at full resolution on top. Everything is built in code from the
## same text map the 2D game uses.

const VIEW_SIZE: Vector2i = Vector2i(480, 270)
const WIPE_SHADER: Shader = preload("res://shaders3d/glitch_wipe.gdshader")
const SCREEN_FX_SCENE: PackedScene = preload("res://fx/screen_fx.tscn")
const PAUSE_SCENE: PackedScene = preload("res://ui/pause_menu.tscn")
const SCENE_PATH: String = "res://scenes3d/district_01_3d.tscn"

const NEON_COLORS: Array[Color] = [
	Color(1.0, 0.15, 0.45), Color(0.1, 0.9, 1.0), Color(0.55, 0.3, 1.0),
	Color(1.0, 0.55, 0.1), Color(0.2, 0.5, 1.0), Color(1.0, 0.2, 0.2),
]

@export var district_id: String = "district_01"
@export var district_title: String = "DISTRICT 01 - STATIC ROW"

var _viewport: SubViewport
var _view: TextureRect
var _wipe: ColorRect
var _wipe_material: ShaderMaterial
var _wipe_tween: Tween
var _layers: WorldLayers3D
var _player: Player3D
var _rig: CameraRig3D
var _world_env: WorldEnvironment
var _env_physical: Environment
var _env_digital: Environment
var _rain: GPUParticles3D
var _fx: ScreenFX
var _hint_tier: Dictionary = {}

var _hp_bar: ProgressBar
var _signal_bar: ProgressBar
var _world_label: Label
var _prompt_label: Label
var _notice: Label


func _ready() -> void:
	_ensure_input_actions()
	GameState.current_district = district_id
	_build_view()
	_build_world()
	_build_hud()

	_fx = SCREEN_FX_SCENE.instantiate()
	_fx.react_to_layer_swap = false  # the wipe replaces the generic glitch pulse
	add_child(_fx)
	add_child(PAUSE_SCENE.instantiate())

	_layers.swap_blocked.connect(_on_swap_blocked)
	_layers.layer_changed.connect(_on_layer_changed)
	_player.target_changed.connect(_on_target_changed)
	GameState.integrity_changed.connect(func(_v: int) -> void: _on_integrity_changed())
	GameState.signal_lost.connect(_on_signal_lost)
	_apply_world_look(GameState.current_layer)
	_refresh_hud()


func _process(_delta: float) -> void:
	_layers.update_cutaway(_player.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.minigame_active:
		return
	if event.is_action_pressed("hint") and not Dialogue.is_active:
		get_viewport().set_input_as_handled()
		_show_hint()
	elif Dialogue.is_active:
		return
	elif event.is_action_pressed("toggle_layer"):
		get_viewport().set_input_as_handled()
		_swap()
	elif event.is_action_pressed("interact"):
		# Mark handled first, or the dialogue box would see the same press and skip a line.
		get_viewport().set_input_as_handled()
		_player.try_interact()
	elif event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_player.attack()


# --- view (low-resolution render, upscaled) ------------------------------------

func _build_view() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "View"
	canvas.layer = -1
	add_child(canvas)

	var aspect := AspectRatioContainer.new()
	aspect.ratio = float(VIEW_SIZE.x) / float(VIEW_SIZE.y)
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(aspect)

	_viewport = SubViewport.new()
	_viewport.name = "PixelViewport"
	_viewport.size = VIEW_SIZE
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_view = TextureRect.new()
	_view.texture = _viewport.get_texture()
	_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_view.stretch_mode = TextureRect.STRETCH_SCALE
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.add_child(_view)

	_wipe_material = ShaderMaterial.new()
	_wipe_material.shader = WIPE_SHADER
	_wipe = ColorRect.new()
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe.material = _wipe_material
	_wipe.visible = false
	_view.add_child(_wipe)


# --- 3D world -------------------------------------------------------------------

func _build_world() -> void:
	_layers = WorldLayers3D.new()
	_layers.name = "Layers"
	_viewport.add_child(_layers)

	_env_physical = _make_environment(
		Color(0.02, 0.01, 0.05), Color(0.28, 0.3, 0.6), 1.2, Color(0.08, 0.06, 0.2), 0.01, 0.9
	)
	_env_digital = _make_environment(
		Color(0.01, 0.0, 0.06), Color(0.2, 0.1, 0.5), 0.6, Color(0.12, 0.02, 0.32), 0.008, 1.1
	)
	_world_env = WorldEnvironment.new()
	_world_env.environment = _env_physical
	_viewport.add_child(_world_env)

	_player = Player3D.new()
	_player.name = "Player"
	_viewport.add_child(_player)
	_player.global_position = _layers.cell_to_world(Vector2(3, 3))

	_rig = CameraRig3D.new()
	_rig.name = "CameraRig"
	_rig.target = _player
	var size: Vector2 = _layers.world_size()
	_rig.bounds = Rect2(Vector2(6.5, 4.0), size - Vector2(13.0, 7.0))
	_viewport.add_child(_rig)
	_player.camera_yaw = _rig.yaw_degrees

	_rain = _make_rain()
	_rig.add_child(_rain)

	_build_physical_dressing(_layers.physical_root)
	_build_digital_dressing(_layers.digital_root)
	_spawn_objects()


func _spawn_objects() -> void:
	var fixer := Npc3D.new()
	fixer.name = "Fixer"
	fixer.realm = Interactable3D.Realm.PHYSICAL
	fixer.speaker = "FIXER"
	fixer.lines = [
		"Signal's weak out here. The wall splits this district in two, but only in the real world.",
		"Press Space. The Grid has no wall. Get across, find the terminal, and open the gate for me.",
	] as Array[String]
	fixer.alt_if_hacked = "term_gate"
	fixer.alt_lines = ["You opened it. Maybe you're not just another ghost in the wire."] as Array[String]
	_viewport.add_child(fixer)
	fixer.global_position = _layers.cell_to_world(Vector2(6, 4))

	var terminal := Terminal3D.new()
	terminal.name = "GateTerminal"
	terminal.realm = Interactable3D.Realm.PHYSICAL
	terminal.terminal_id = "term_gate"
	_viewport.add_child(terminal)
	terminal.global_position = _layers.cell_to_world(Vector2(30, 12))

	var door := Door3D.new()
	door.name = "GateDoor"
	door.required_terminal = "term_gate"
	_viewport.add_child(door)
	# The wall at column 20 has a two-row gap (rows 9 and 10); the door fills it.
	door.global_position = Vector3(20.5 * WorldLayers3D.TILE, 0.0, 10.0 * WorldLayers3D.TILE)

	_add_drone(Vector2(22, 14), Vector3(12.0, 0.0, 0.0))
	_add_drone(Vector2(40, 3), Vector3(0.0, 0.0, 10.0))
	_add_drone(Vector2(9, 13), Vector3(10.0, 0.0, 0.0))


func _add_drone(cell: Vector2, patrol: Vector3) -> void:
	var drone := Drone3D.new()
	drone.patrol_offset = patrol
	_viewport.add_child(drone)
	drone.global_position = _layers.cell_to_world(cell)


func _make_environment(
	background: Color, ambient: Color, ambient_energy: float, fog: Color, fog_density: float, glow: float
) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = background
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	env.fog_enabled = true
	env.fog_light_color = fog
	env.fog_density = fog_density
	env.glow_enabled = true
	env.glow_intensity = glow
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	return env


func _make_rain() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Rain"
	particles.amount = 900
	particles.lifetime = 0.6
	particles.preprocess = 0.6
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-30, -30, -30), Vector3(60, 60, 60))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Biased away from the camera (which sits at +z): drops right in front of the lens
	# would render as huge bars.
	process.emission_shape_offset = Vector3(0.0, 0.0, -4.0)
	process.emission_box_extents = Vector3(15.0, 0.1, 8.0)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 0.0
	process.initial_velocity_min = 26.0
	process.initial_velocity_max = 32.0
	process.gravity = Vector3.ZERO
	particles.process_material = process
	var streak := BoxMesh.new()
	streak.size = Vector3(0.018, 0.55, 0.018)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 0.75, 1.0, 0.4)
	streak.material = material
	particles.draw_pass_1 = streak
	particles.position = Vector3(0.0, 15.0, 0.0)
	return particles


## Neon signs, lights and bins: only exist in the Physical world.
func _build_physical_dressing(root: Node3D) -> void:
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.4, 0.45, 0.9)
	moon.light_energy = 0.8
	moon.rotation_degrees = Vector3(-62.0, 25.0, 0.0)
	root.add_child(moon)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var tile: float = WorldLayers3D.TILE
	var signs: Array[Vector2i] = []
	var bins: Array[Vector2i] = []
	for cy: int in range(0, _layers.map_size.y - 1):
		for cx: int in _layers.map_size.x:
			var here: String = _layers.char_at(cx, cy)
			var south: String = _layers.char_at(cx, cy + 1)
			if (here == "#" or here == "P") and south == ".":
				signs.append(Vector2i(cx, cy))
			if here == "." and south == "." and _layers.char_at(cx, cy - 1) == "#":
				bins.append(Vector2i(cx, cy))

	# Neon pools of light at fixed spots across the map. Kept to 6: the Compatibility
	# renderer drops lights beyond 8 per mesh, and long wall blocks overlap them all.
	var lamp_spots: Array[Vector2] = [
		Vector2(5, 3), Vector2(13, 9), Vector2(25, 5), Vector2(30, 13), Vector2(40, 9), Vector2(10, 18),
	]
	for i: int in lamp_spots.size():
		var lamp := OmniLight3D.new()
		lamp.light_color = NEON_COLORS[i % NEON_COLORS.size()]
		lamp.light_energy = 3.2
		lamp.omni_range = 13.0
		lamp.position = _layers.cell_to_world(lamp_spots[i]) + Vector3(0.0, 2.6, 0.0)
		root.add_child(lamp)

	# Wall dressing on the south faces (the faces the low camera sees): neon signs,
	# doors, pipes. Every piece is registered for the cut-away so it disappears with
	# the wall block it belongs to.
	var door_material := StandardMaterial3D.new()
	door_material.albedo_color = Color(0.05, 0.05, 0.09)
	door_material.metallic = 0.5
	door_material.roughness = 0.45
	var pipe_material := StandardMaterial3D.new()
	pipe_material.albedo_color = Color(0.08, 0.09, 0.12)
	pipe_material.metallic = 0.6
	pipe_material.roughness = 0.4

	var last_x: int = -99
	for cell: Vector2i in signs:
		if rng.randf() > 0.4 or absi(cell.x - last_x) < 3:
			continue
		last_x = cell.x
		var wall_x: float = (cell.x + 0.5) * tile
		var face_z: float = (cell.y + 1) * tile
		var color: Color = NEON_COLORS[rng.randi() % NEON_COLORS.size()]
		var kind: float = rng.randf()
		if kind < 0.3:
			# A door with a lit lintel sign.
			var door_mesh := _box(Vector3(1.3, 2.5, 0.1), door_material)
			door_mesh.position = Vector3(wall_x, 1.25, face_z + 0.05)
			root.add_child(door_mesh)
			_cut(door_mesh, cell, tile)
			var lintel := _box(Vector3(1.1, 0.22, 0.06), _neon_material(color))
			lintel.position = Vector3(wall_x, 2.85, face_z + 0.05)
			root.add_child(lintel)
			_cut(lintel, cell, tile)
		else:
			var vertical: bool = kind < 0.65
			var sign_size := Vector3(0.7, 2.4, 0.06) if vertical else Vector3(2.0, 0.55, 0.06)
			var sign_mesh := _box(sign_size, _neon_material(color))
			var height: float = rng.randf_range(2.2, 3.3) if vertical else rng.randf_range(2.6, 3.8)
			sign_mesh.position = Vector3(wall_x, height, face_z + 0.05)
			root.add_child(sign_mesh)
			_cut(sign_mesh, cell, tile)
		if rng.randf() < 0.5:
			var pipe := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.1
			cylinder.bottom_radius = 0.1
			cylinder.height = WorldLayers3D.WALL_HEIGHT
			cylinder.radial_segments = 8
			pipe.mesh = cylinder
			pipe.material_override = pipe_material
			pipe.position = Vector3(wall_x + tile * 0.4, WorldLayers3D.WALL_HEIGHT / 2.0, face_z + 0.12)
			root.add_child(pipe)
			_cut(pipe, cell, tile)

	var bin_material := StandardMaterial3D.new()
	bin_material.albedo_color = Color(0.06, 0.1, 0.09)
	bin_material.roughness = 0.5
	bin_material.metallic = 0.4
	var placed: int = 0
	for cell: Vector2i in bins:
		if placed >= 26 or rng.randf() > 0.12:
			continue
		placed += 1
		var bin := _box(Vector3(0.9, 1.1, 0.8), bin_material)
		bin.position = Vector3((cell.x + 0.5) * tile, 0.55, cell.y * tile + 0.6)
		root.add_child(bin)
		# Bins sit in front of the wall row above them, so they share its cut-away.
		_layers.register_cutaway(
			bin, cell.x * tile, (cell.x + 1) * tile, (cell.y - 1) * tile, GameState.WorldLayer.PHYSICAL
		)


func _box(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	return mesh_instance


## Register a wall-mounted prop so it hides together with its wall block.
func _cut(node: Node3D, wall_cell: Vector2i, tile: float) -> void:
	_layers.register_cutaway(
		node, wall_cell.x * tile, (wall_cell.x + 1) * tile, wall_cell.y * tile, GameState.WorldLayer.PHYSICAL
	)


## Hologram orbs: Digital-only pickups-to-be that bob above glowing rings.
func _build_digital_dressing(root: Node3D) -> void:
	var orb_cells: Array[Vector2] = [
		Vector2(8, 9), Vector2(14, 5), Vector2(27, 8), Vector2(31, 17), Vector2(40, 7), Vector2(12, 18),
	]
	for cell: Vector2 in orb_cells:
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.32
		sphere.height = 0.64
		sphere.radial_segments = 12
		sphere.rings = 6
		orb.mesh = sphere
		orb.material_override = _neon_material(Color(0.85, 0.3, 1.0), 3.0)
		var base: Vector3 = _layers.cell_to_world(cell)
		orb.position = base + Vector3(0, 1.1, 0)
		root.add_child(orb)
		var tween: Tween = orb.create_tween().set_loops()
		tween.tween_property(orb, "position:y", 1.4, 1.1).set_trans(Tween.TRANS_SINE)
		tween.tween_property(orb, "position:y", 0.9, 1.1).set_trans(Tween.TRANS_SINE)

		var ring := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.55
		disc.bottom_radius = 0.55
		disc.height = 0.04
		disc.radial_segments = 16
		ring.mesh = disc
		ring.material_override = _neon_material(Color(0.1, 0.9, 1.0), 2.2)
		ring.position = base + Vector3(0, 0.03, 0)
		root.add_child(ring)


func _neon_material(color: Color, energy: float = 3.2) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.02, 0.02, 0.03)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


# --- world swap -----------------------------------------------------------------

func _swap() -> void:
	var before: GameState.WorldLayer = GameState.current_layer
	var old_frame: ImageTexture = ImageTexture.create_from_image(_viewport.get_texture().get_image())
	_layers.toggle(_player)
	if GameState.current_layer != before:
		_play_wipe(old_frame)


func _play_wipe(old_frame: Texture2D) -> void:
	if _wipe_tween:
		_wipe_tween.kill()
	_wipe_material.set_shader_parameter("old_tex", old_frame)
	_wipe_material.set_shader_parameter("progress", 0.0)
	_wipe.visible = true
	_wipe_tween = create_tween()
	_wipe_tween.tween_method(_set_wipe, 0.0, 1.0, 0.5)
	_wipe_tween.finished.connect(func() -> void: _wipe.visible = false)
	_fx.pulse(0.45, 0.25)


func _set_wipe(value: float) -> void:
	_wipe_material.set_shader_parameter("progress", value)


func _on_layer_changed(layer: GameState.WorldLayer) -> void:
	Audio.sfx("swap")
	_apply_world_look(layer)
	_refresh_hud()


func _apply_world_look(layer: GameState.WorldLayer) -> void:
	var physical: bool = layer == GameState.WorldLayer.PHYSICAL
	_world_env.environment = _env_physical if physical else _env_digital
	_rain.visible = physical
	Audio.play_music("physical" if physical else "digital")


func _on_swap_blocked() -> void:
	Audio.sfx("hack_fail", -6.0)
	_fx.flash(Color(1.0, 0.1, 0.2, 0.35), 0.3)
	_show_notice("Can't swap: you'd be stuck inside something solid")


func _on_integrity_changed() -> void:
	_fx.pulse(0.6, 0.3)
	_fx.flash(Color(1.0, 0.1, 0.2, 0.3), 0.4)
	_refresh_hud()


func _on_signal_lost() -> void:
	if Dialogue.is_active:
		await Dialogue.finished
	Audio.sfx("lost")
	Dialogue.start("SYSTEM", ["SIGNAL LOST.", "Rebooting from the last safe point..."])
	await Dialogue.finished
	GameState.restore_signal()
	GameState.current_layer = GameState.WorldLayer.PHYSICAL
	SceneManager.change_scene(SCENE_PATH)


# --- hints ------------------------------------------------------------------------

func _objectives() -> Array[Dictionary]:
	return [
		{
			"done": func() -> bool: return GameState.is_hacked("term_gate"),
			"tiers": [
				"The wall in the middle of the alley only exists in the real world.",
				"Press SPACE to swap into the Grid, where the wall is gone, and cross it.",
				"Cross in the Grid, swap back, and hack the terminal on the east side. Strike drones with J.",
			],
		},
		{
			"done": func() -> bool: return false,
			"tiers": ["The gate is open. This is the end of the prototype slice. Try striking a drone (J) in the Grid."],
		},
	]


func _show_hint() -> void:
	Audio.sfx("click")
	var objectives: Array[Dictionary] = _objectives()
	for i: int in objectives.size():
		var objective: Dictionary = objectives[i]
		var done: Callable = objective["done"]
		if done.call():
			continue
		var tiers: Array = objective["tiers"]
		var shown: int = _hint_tier.get(i, 0)
		var text: String = tiers[mini(shown, tiers.size() - 1)]
		_hint_tier[i] = mini(shown + 1, tiers.size())
		var more: String = "" if shown >= tiers.size() - 1 else "  (press H again for more help)"
		Dialogue.start("HINT", ["%s%s" % [text, more]] as Array[String])
		return


# --- HUD (full resolution, above the pixel view) ----------------------------------

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 5
	add_child(hud)

	# Top left: HP and SIGNAL bars.
	var bars := PanelContainer.new()
	bars.position = Vector2(16, 14)
	hud.add_child(bars)
	var column := VBoxContainer.new()
	bars.add_child(column)
	_hp_bar = _add_bar_row(column, "HP:    ", Color(1.0, 0.25, 0.3))
	_signal_bar = _add_bar_row(column, "SIGNAL:", Color(0.2, 0.9, 1.0))
	_world_label = Label.new()
	_world_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_world_label)

	# Top centre: game title.
	var title_panel := PanelContainer.new()
	var title := Label.new()
	title.text = "CHRONICLES OF THE SIGNAL"
	title.add_theme_font_size_override("font_size", 16)
	title_panel.add_child(title)
	hud.add_child(title_panel)
	_pin(title_panel, 0.5, 0.0, 14.0)

	# Top right: district name.
	var district_panel := PanelContainer.new()
	var district := Label.new()
	district.text = district_title
	district.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	district_panel.add_child(district)
	hud.add_child(district_panel)
	_pin(district_panel, 1.0, 0.0, 14.0)

	# Bottom centre: swap prompt.
	var swap_panel := PanelContainer.new()
	var swap := Label.new()
	swap.text = "[SPACE] SWAP REALITY"
	swap.add_theme_font_size_override("font_size", 24)
	swap.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	swap_panel.add_child(swap)
	hud.add_child(swap_panel)
	_pin(swap_panel, 0.5, 1.0, 22.0)

	# Bottom right: contextual prompts.
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(_prompt_label)
	_pin(_prompt_label, 1.0, 1.0, 18.0)

	# Notices just above the swap prompt.
	_notice = Label.new()
	_notice.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_notice.offset_left = -400.0
	_notice.offset_right = 400.0
	_notice.offset_top = -110.0
	_notice.offset_bottom = -80.0
	_notice.modulate.a = 0.0
	hud.add_child(_notice)
	_update_prompt(null)


## Pin a control to an anchor point (0, 0.5 or 1 on each axis) and let it grow toward
## the screen interior to fit its content, so right/bottom items are never clipped.
func _pin(control: Control, anchor_x: float, anchor_y: float, margin: float) -> void:
	control.anchor_left = anchor_x
	control.anchor_right = anchor_x
	control.anchor_top = anchor_y
	control.anchor_bottom = anchor_y
	var dx: float = margin * (1.0 - 2.0 * anchor_x) if anchor_x != 0.5 else 0.0
	var dy: float = margin * (1.0 - 2.0 * anchor_y) if anchor_y != 0.5 else 0.0
	control.offset_left = dx
	control.offset_right = dx
	control.offset_top = dy
	control.offset_bottom = dy
	control.grow_horizontal = (
		Control.GROW_DIRECTION_BOTH if anchor_x == 0.5
		else (Control.GROW_DIRECTION_BEGIN if anchor_x == 1.0 else Control.GROW_DIRECTION_END)
	)
	control.grow_vertical = (
		Control.GROW_DIRECTION_BOTH if anchor_y == 0.5
		else (Control.GROW_DIRECTION_BEGIN if anchor_y == 1.0 else Control.GROW_DIRECTION_END)
	)


func _add_bar_row(parent: Control, label_text: String, color: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return bar


func _refresh_hud() -> void:
	var grid: bool = GameState.current_layer == GameState.WorldLayer.DIGITAL
	_world_label.text = "WORLD: %s" % ("DIGITAL" if grid else "PHYSICAL")
	_hp_bar.value = GameState.player_health
	_signal_bar.value = GameState.player_signal_integrity


func _on_target_changed(target: Interactable3D) -> void:
	_update_prompt(target)


func _update_prompt(target: Interactable3D) -> void:
	var interact: String = "[E] %s" % target.prompt_text if target else "[E] INTERACT"
	_prompt_label.text = "%s\n[J] STRIKE\n[H] HINT" % interact
	_prompt_label.modulate = Color.WHITE if target else Color(1, 1, 1, 0.55)


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(_notice, "modulate:a", 0.0, 0.5)


## The attack action is registered in code so project.godot's input map stays untouched.
func _ensure_input_actions() -> void:
	if InputMap.has_action("attack"):
		return
	InputMap.add_action("attack")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	InputMap.action_add_event("attack", key)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_B
	InputMap.action_add_event("attack", pad)
