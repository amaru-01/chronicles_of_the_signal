class_name District3D
extends Node
## Base class for every 3D district (hub, District 01, District 02, ...).
##
## A district scene is just a Node with a subclass of this script. The subclass sets
## `district_id` / `map_path` and overrides `_populate()` (spawn terminals, doors,
## enemies, exits...), `_objectives()` (hints) and optionally `_spawn_cells()`.
##
## The 3D scene renders into a small SubViewport (VIEW_SIZE) that is upscaled with
## nearest-neighbour filtering for the pixel-art look. The HUD, effects and the
## swap wipe live at full resolution on top. Everything is built in code from the
## same text map the 2D game uses.

const VIEW_SIZE: Vector2i = Vector2i(480, 270)
const WIPE_SHADER: Shader = preload("res://shaders3d/glitch_wipe.gdshader")
const SCREEN_FX_SCENE: PackedScene = preload("res://fx/screen_fx.tscn")
const PAUSE_SCENE: PackedScene = preload("res://ui/pause_menu.tscn")

const NEON_COLORS: Array[Color] = [
	Color(1.0, 0.15, 0.45), Color(0.1, 0.9, 1.0), Color(0.55, 0.3, 1.0),
	Color(1.0, 0.55, 0.1), Color(0.2, 0.5, 1.0), Color(1.0, 0.2, 0.2),
]

@export var district_id: String = "3d_district_01"
@export_file("*.txt") var map_path: String = "res://scenes/world/maps/district_01.txt"

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
var _minimap: Minimap3D
var _hud: CanvasLayer
var _travel_menu: FastTravelMenu3D
var _weather_tween: Tween
var _journal: JournalMenu3D
var _quest_label: Label
var _quest_timer: float = 0.0
var _notice_queue: Array[String] = []
var _notice_busy: bool = false
var _saved_label: Label
var _saved_tween: Tween
var _regen_timer: float = 0.0

var _hp_bar: ProgressBar
var _signal_bar: ProgressBar
var _world_label: Label
var _prompt_label: Label
var _notice: Label


func _ready() -> void:
	_ensure_input_actions()
	GameState.current_district = district_id
	GameState.flags["visited_" + district_id] = true  # quest objectives ("reach The Archive")
	GameState.current_district = district_id
	_build_view()
	_build_world()
	_build_hud()
	_build_quest_hud()

	_fx = SCREEN_FX_SCENE.instantiate()
	_fx.react_to_layer_swap = false  # the wipe replaces the generic glitch pulse
	add_child(_fx)
	add_child(PAUSE_SCENE.instantiate())
	_travel_menu = FastTravelMenu3D.new()
	add_child(_travel_menu)
	_journal = JournalMenu3D.new()
	add_child(_journal)
	_build_minimap()

	_layers.swap_blocked.connect(_on_swap_blocked)
	_layers.layer_changed.connect(_on_layer_changed)
	_player.target_changed.connect(_on_target_changed)
	GameState.integrity_changed.connect(func(_v: int) -> void: _on_integrity_changed())
	GameState.health_changed.connect(func(_v: int) -> void: _on_health_changed())
	GameState.signal_lost.connect(_on_signal_lost)
	GameState.checkpoint_reached.connect(func() -> void:
		Audio.sfx("pickup")
		_show_notice("Beacon linked: fast travel unlocked")
	)
	_apply_world_look(GameState.current_layer)
	_refresh_hud()


func _process(delta: float) -> void:
	_layers.update_cutaway(_player.global_position)
	_quest_timer -= delta
	if _quest_timer <= 0.0:
		_quest_timer = 0.5
		_poll_quests()
	_regenerate_signal(delta)
	_update_exit_labels()


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
	elif event.is_action_pressed("pulse"):
		get_viewport().set_input_as_handled()
		_player.fire_pulse()
	elif event.is_action_pressed("fast_travel"):
		get_viewport().set_input_as_handled()
		_travel_menu.open()
	elif event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		_journal.open()


# --- exit labels (full-resolution text pinned to 3D doorways) ------------------------

const LABEL_RANGE: float = 16.0
var _exit_labels: Dictionary = {}  # ExitZone3D -> Label


## The pixel viewport is too coarse for readable text, so doorway names are HUD labels
## placed at the projected position of each exit and faded out with distance.
func _update_exit_labels() -> void:
	if _rig == null or _rig.camera == null or _hud == null:
		return
	var camera: Camera3D = _rig.camera
	var scale: Vector2 = _view.size / Vector2(VIEW_SIZE)
	for node: Node in get_tree().get_nodes_in_group("exit3d"):
		var zone := node as ExitZone3D
		if zone == null or zone.label_text == "":
			continue
		var label: Label = _exit_labels.get(zone)
		if label == null:
			label = Label.new()
			label.text = zone.label_text
			label.add_theme_color_override("font_color", zone.color.lightened(0.35))
			label.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06))
			label.add_theme_constant_override("outline_size", 8)
			label.add_theme_font_size_override("font_size", 20)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_hud.add_child(label)
			_hud.move_child(label, 0)  # behind the bars and dialogue
			_exit_labels[zone] = label
		var anchor: Vector3 = zone.global_position + Vector3(0.0, 3.7, 0.0)
		var distance: float = camera.global_position.distance_to(anchor)
		var visible_now: bool = not camera.is_position_behind(anchor) and distance < LABEL_RANGE
		label.visible = visible_now
		if visible_now:
			label.modulate.a = clampf((LABEL_RANGE - distance) / 5.0, 0.0, 1.0)
			var screen: Vector2 = _view.global_position + camera.unproject_position(anchor) * scale
			label.position = screen - label.size * 0.5


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
	_layers.map_path = map_path
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
	_player.global_position = _spawn_position()

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
	_populate()
	_start_weather()
	GameState.save_game()  # autosave on entering a district: Continue resumes here


func _add_drone(cell: Vector2, patrol: Vector3) -> void:
	_add_enemy(Drone3D.new(), cell, patrol)


func _add_enemy(enemy: Enemy3D, cell: Vector2, patrol: Vector3) -> void:
	enemy.patrol_offset = patrol
	# Position BEFORE add_child: enemies record their patrol start in _ready.
	enemy.position = _layers.cell_to_world(cell)
	_viewport.add_child(enemy)


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
	rng.seed = district_id.hash()
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

	# Neon pools of light spread across the map (a 3x2 grid of sample points, each snapped
	# to the nearest floor cell). Kept to 6: the Compatibility renderer drops lights
	# beyond 8 per mesh, and long wall blocks overlap them all.
	var lamp_index: int = 0
	for gy: int in 2:
		for gx: int in 3:
			var sample := Vector2(
				_layers.map_size.x * (gx + 0.5) / 3.0, _layers.map_size.y * (gy + 0.5) / 2.0
			)
			var lamp := OmniLight3D.new()
			lamp.light_color = NEON_COLORS[lamp_index % NEON_COLORS.size()]
			lamp.light_energy = 3.2
			lamp.omni_range = 13.0
			lamp.position = _layers.cell_to_world(_nearest_floor(sample)) + Vector3(0.0, 2.6, 0.0)
			root.add_child(lamp)
			lamp_index += 1

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
	var orb_rng := RandomNumberGenerator.new()
	orb_rng.seed = district_id.hash() + 1
	var orb_cells: Array[Vector2] = []
	for i: int in 6:
		var sample := Vector2(
			orb_rng.randf_range(2.0, _layers.map_size.x - 2.0), orb_rng.randf_range(2.0, _layers.map_size.y - 2.0)
		)
		orb_cells.append(_nearest_floor(sample))
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


func _on_health_changed() -> void:
	_player.hurt_flash()
	_fx.flash(Color(1.0, 0.1, 0.2, 0.3), 0.4)
	_refresh_hud()


func _on_signal_lost() -> void:
	if Dialogue.is_active:
		await Dialogue.finished
	Audio.sfx("lost")
	Dialogue.start("SYSTEM", ["SIGNAL LOST.", "Rebooting from the last safe point..."])
	await Dialogue.finished
	GameState.restore_signal()
	GameState.restore_health()
	GameState.current_layer = GameState.WorldLayer.PHYSICAL
	SceneManager.change_scene(scene_file_path)


# --- hints ------------------------------------------------------------------------

## Override in each district. Each entry: {"done": Callable, "tiers": [vague, ..., explicit]}.
## Objectives are checked in order; the first not-done one is hinted.
func _objectives() -> Array[Dictionary]:
	return []


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
	_hud = hud

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
	district.text = WorldMap3D.title_of(district_id)
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
	_prompt_label.text = "%s\n[J] STRIKE  [K] PULSE\n[H] HINT  [T] TRAVEL  [TAB] JOURNAL" % interact
	_prompt_label.modulate = Color.WHITE if target else Color(1, 1, 1, 0.55)


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(_notice, "modulate:a", 0.0, 0.5)


## Actions are registered in code so project.godot's input map stays untouched.
func _ensure_input_actions() -> void:
	_add_action("attack", KEY_J, MOUSE_BUTTON_LEFT, JOY_BUTTON_B)
	_add_action("pulse", KEY_K, MOUSE_BUTTON_RIGHT, JOY_BUTTON_RIGHT_SHOULDER)  # X is "hint"
	_add_action("fast_travel", KEY_T, MOUSE_BUTTON_NONE, JOY_BUTTON_LEFT_SHOULDER)
	_add_action("journal", KEY_TAB, MOUSE_BUTTON_NONE, JOY_BUTTON_BACK)


func _add_action(action: String, key_code: Key, mouse_button: MouseButton, pad_button: JoyButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var key := InputEventKey.new()
	key.physical_keycode = key_code
	InputMap.action_add_event(action, key)
	if mouse_button != MOUSE_BUTTON_NONE:
		var click := InputEventMouseButton.new()
		click.button_index = mouse_button
		InputMap.action_add_event(action, click)
	if pad_button != JOY_BUTTON_INVALID:
		var pad := InputEventJoypadButton.new()
		pad.button_index = pad_button
		InputMap.action_add_event(action, pad)


# --- hooks and helpers for district subclasses -------------------------------------

## Override: spawn this district's terminals, doors, enemies, exits, NPCs...
func _populate() -> void:
	pass


## Override to name entry points: {"start": cell, "from_hub": cell, ...}. Cells are map cells.
func _spawn_cells() -> Dictionary:
	return {"start": Vector2(3, 3)}


## Where the player appears: a named entry (set by the exit they came through) first,
## then the last beacon, then "start".
func _spawn_position() -> Vector3:
	var cells: Dictionary = _spawn_cells()
	var wanted: String = str(GameState.flags.get("spawn_3d", ""))
	GameState.flags["spawn_3d"] = ""  # consumed: a reboot should use the beacon instead
	if wanted != "" and cells.has(wanted):
		return _layers.cell_to_world(cells[wanted])
	if GameState.checkpoints.has(district_id):
		var saved: Vector2 = GameState.checkpoints[district_id]
		return Vector3(saved.x, 0.0, saved.y)
	return _layers.cell_to_world(cells.get("start", Vector2(3, 3)))


## Place a node at a map cell (x, z in cells; the cell centre).
func _place(node: Node3D, cell: Vector2) -> void:
	node.position = _layers.cell_to_world(cell)  # set before add_child: _ready may read it
	_viewport.add_child(node)


## Place a node using the 2D game's pixel coordinates (32 px per tile), so the 2D
## district layouts can be ported by copying their numbers.
func _place_px(node: Node3D, pixel: Vector2) -> void:
	node.position = _px_offset(pixel)
	_viewport.add_child(node)


## A 2D pixel position/offset as 3D metres on the ground plane.
func _px_offset(pixel: Vector2) -> Vector3:
	return Vector3(pixel.x / 32.0 * WorldLayers3D.TILE, 0.0, pixel.y / 32.0 * WorldLayers3D.TILE)


func _add_enemy_px(enemy: Enemy3D, pixel: Vector2, patrol_px: Vector2, move_speed: float = 3.2) -> void:
	enemy.patrol_offset = _px_offset(patrol_px)
	enemy.speed = move_speed
	_place_px(enemy, pixel)


func _add_exit(cell: Vector2, target: String, target_spawn: String, label: String,
		requires_id: String = "", locked_lines: Array[String] = [],
		color: Color = Color(1.0, 0.85, 0.2)) -> ExitZone3D:
	var zone := ExitZone3D.new()
	zone.target_district = target
	zone.target_spawn = target_spawn
	zone.label_text = label
	zone.requires_id = requires_id
	zone.color = color
	if not locked_lines.is_empty():
		zone.locked_lines = locked_lines
	_place(zone, cell)
	return zone


func _add_beacon(cell: Vector2) -> Checkpoint3D:
	var beacon := Checkpoint3D.new()
	beacon.district_id = district_id
	beacon.add_to_group("beacon3d")
	_place(beacon, cell)
	return beacon


## The floor cell nearest to `cell` (floor in both worlds, so props never sit in a wall).
func _nearest_floor(cell: Vector2) -> Vector2:
	var cx: int = clampi(roundi(cell.x), 0, _layers.map_size.x - 1)
	var cy: int = clampi(roundi(cell.y), 0, _layers.map_size.y - 1)
	for radius: int in 12:
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if _layers.char_at(cx + dx, cy + dy) == ".":
					return Vector2(cx + dx, cy + dy)
	return Vector2(cx, cy)


# --- quests -----------------------------------------------------------------------------

func _build_quest_hud() -> void:
	_quest_label = Label.new()
	_quest_label.add_theme_font_size_override("font_size", 14)
	_quest_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(_quest_label)
	_pin(_quest_label, 1.0, 0.0, 14.0)
	_quest_label.offset_top += 46.0  # just under the district name
	_quest_label.offset_bottom += 46.0
	_saved_label = Label.new()
	_saved_label.text = "SAVED"
	_saved_label.add_theme_font_size_override("font_size", 13)
	_saved_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7))
	_saved_label.modulate.a = 0.0
	_hud.add_child(_saved_label)
	_pin(_saved_label, 0.0, 1.0, 14.0)
	GameState.saved.connect(_flash_saved)
	_refresh_tracker()


func _flash_saved() -> void:
	if _saved_tween:
		_saved_tween.kill()
	_saved_label.modulate.a = 1.0
	_saved_tween = create_tween()
	_saved_tween.tween_interval(0.8)
	_saved_tween.tween_property(_saved_label, "modulate:a", 0.0, 0.6)


## Echo Core: signal integrity creeps back up on its own (quietly: no damage flash).
func _regenerate_signal(delta: float) -> void:
	var amount: int = Items3D.regen_per_tick()
	if amount <= 0 or Dialogue.is_active:
		return
	_regen_timer -= delta
	if _regen_timer > 0.0:
		return
	_regen_timer = 1.5
	if GameState.player_signal_integrity < GameState.MAX_SIGNAL_INTEGRITY:
		GameState.player_signal_integrity = mini(GameState.MAX_SIGNAL_INTEGRITY, GameState.player_signal_integrity + amount)
		_refresh_hud()


## Tick the quest log; announce anything that happened.
func _poll_quests() -> void:
	for event: Dictionary in Quests3D.evaluate():
		match event["type"]:
			"quest_start":
				_queue_notice("New quest: %s" % event["quest"])
			"objective":
				_queue_notice("Objective complete: %s" % event["text"])
			"quest_done":
				var reward: String = str(event["text"])
				_queue_notice("Quest complete: %s%s" % [event["quest"], ("  -  " + reward) if reward != "" else ""])
				Audio.sfx("hack_ok", -4.0)
	_refresh_tracker()


func _refresh_tracker() -> void:
	var tracked: Dictionary = Quests3D.tracked()
	_quest_label.text = "" if tracked.is_empty() else "%s\n> %s" % [tracked["quest"], tracked["text"]]


## Notices appear one after another so quest messages never overwrite each other.
func _queue_notice(text: String) -> void:
	_notice_queue.append(text)
	_pump_notices()


func _pump_notices() -> void:
	if _notice_busy or _notice_queue.is_empty():
		return
	_notice_busy = true
	_show_notice(_notice_queue.pop_front())
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		_notice_busy = false
		_pump_notices()
	)


# --- minimap and weather --------------------------------------------------------------

func _build_minimap() -> void:
	_minimap = Minimap3D.new()
	_minimap.position = Vector2(16, 104)
	_hud.add_child(_minimap)
	_minimap.setup(_layers, _player)


## Rain swells and thins on a slow cycle, and the fog thickens with it.
func _start_weather() -> void:
	_weather_tween = create_tween().set_loops()
	_weather_tween.tween_property(_rain, "amount_ratio", 0.3, 16.0).set_trans(Tween.TRANS_SINE)
	_weather_tween.parallel().tween_property(_env_physical, "fog_density", 0.006, 16.0).set_trans(Tween.TRANS_SINE)
	_weather_tween.tween_property(_rain, "amount_ratio", 1.0, 16.0).set_trans(Tween.TRANS_SINE)
	_weather_tween.parallel().tween_property(_env_physical, "fog_density", 0.016, 16.0).set_trans(Tween.TRANS_SINE)


# --- builders for the common puzzle pieces (2D pixel coordinates) --------------------------

func _add_terminal(pixel: Vector2, id: String, realm: Interactable3D.Realm, word_length: int = 6,
		time_limit: float = 30.0, attempts: int = 4, fail_damage: int = 20, reward_item: String = "") -> void:
	var terminal := Terminal3D.new()
	terminal.terminal_id = id
	terminal.realm = realm
	terminal.word_length = word_length
	terminal.time_limit = time_limit
	terminal.attempts = attempts
	terminal.fail_damage = fail_damage
	terminal.reward_item = reward_item
	_place_px(terminal, pixel)


func _add_door(pixel: Vector2, required: String, extra: Array[String], realm: Interactable3D.Realm) -> void:
	var door := Door3D.new()
	door.required_terminal = required
	door.extra_required = extra
	door.realm = realm
	_place_px(door, pixel)


func _add_switch(pixel: Vector2, id: String, duration: float) -> void:
	var lever := Switch3D.new()
	lever.switch_id = id
	lever.duration = duration
	lever.realm = Interactable3D.Realm.DIGITAL
	_place_px(lever, pixel)


func _add_fragment(id: String, pixel: Vector2, memory: Array[String]) -> void:
	var fragment := Pickup3D.new()
	fragment.item_id = id
	fragment.realm = Interactable3D.Realm.DIGITAL
	fragment.memory_lines = memory
	_place_px(fragment, pixel)
