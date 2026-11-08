extends SceneTree
## Dev tool: measures frame cost in every 3D district (vsync off). Usage:
##   godot --path . --resolution 1280x720 --script res://tools/perf_3d.gd -- <output_dir>
##   (add --rendering-method forward_plus --rendering-driver vulkan to compare renderers)
## Prints average / worst frame time, draw calls, objects and script time per district, and
## saves a screenshot of each. Uses a throwaway save. Untyped on purpose (autoloads).

const SCENES: Array = [
	["hub", "res://scenes3d/hub_3d.tscn"],
	["district_01", "res://scenes3d/district_01_3d.tscn"],
	["district_02", "res://scenes3d/district_02_3d.tscn"],
	["district_03", "res://scenes3d/district_03_3d.tscn"],
	["relay_tower", "res://scenes3d/relay_tower_3d.tscn"],
]
const WARMUP: int = 60
const SAMPLES: int = 240

var _out: String = "."
var _index: int = 0
var _scene: Node
var _frame: int = 0
var _times: PackedFloat64Array = PackedFloat64Array()
var _draw_calls: float = 0.0
var _objects: float = 0.0
var _script_ms: float = 0.0
var _lines: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_load(0)


func _load(i: int) -> void:
	if _scene != null:
		_scene.queue_free()
	root.get_node("GameState").reset()
	_scene = (load(SCENES[i][1]) as PackedScene).instantiate()
	root.add_child(_scene)
	_frame = 0
	_times.clear()
	_draw_calls = 0.0
	_objects = 0.0
	_script_ms = 0.0


func _process(delta: float) -> bool:
	_frame += 1
	if _frame > WARMUP and _frame <= WARMUP + SAMPLES:
		_times.append(delta * 1000.0)
		_draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		_objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		_script_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	elif _frame == WARMUP + SAMPLES + 1:
		var sum: float = 0.0
		var worst: float = 0.0
		for t: float in _times:
			sum += t
			worst = maxf(worst, t)
		var avg: float = sum / _times.size()
		_lines.append("%-12s avg %6.2f ms (%5.0f fps)  worst %6.2f ms  draw calls %5.0f  objects %5.0f  process %5.2f ms  nodes %d" % [
			SCENES[_index][0], avg, 1000.0 / avg, worst, _draw_calls / SAMPLES, _objects / SAMPLES,
			_script_ms / SAMPLES, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		root.get_texture().get_image().save_png("%s/perf_%s.png" % [_out, SCENES[_index][0]])
		_index += 1
		if _index >= SCENES.size():
			print("RENDERER: %s" % RenderingServer.get_current_rendering_method())
			print("GPU: %s" % RenderingServer.get_video_adapter_name())
			print("\n".join(_lines))
			root.get_node("GameState").delete_save()
			quit()
		else:
			_load(_index)
	return false
