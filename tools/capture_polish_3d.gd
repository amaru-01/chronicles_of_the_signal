extends SceneTree
## Dev tool: screenshots of an exit label and the lighting in each district. Usage:
##   godot --path . --script res://tools/capture_polish_3d.gd -- <output_dir>
## Untyped on purpose (autoloads do not exist when a --script SceneTree compiles).

var _out: String = "."
var _scene: Node
var _frame: int = 0
var _index: int = 0
const SHOTS: Array = [
	["res://scenes3d/hub_3d.tscn", "polish_hub"],
	["res://scenes3d/district_01_3d.tscn", "polish_d01"],
	["res://scenes3d/district_02_3d.tscn", "polish_d02"],
	["res://scenes3d/district_03_3d.tscn", "polish_d03"],
	["res://scenes3d/relay_tower_3d.tscn", "polish_tower"],
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	_load(0)


func _load(i: int) -> void:
	if _scene != null:
		_scene.queue_free()
	_scene = (load(SHOTS[i][0]) as PackedScene).instantiate()
	root.add_child(_scene)
	_frame = 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		# Stand a few metres in front of the nearest exit so its label is in frame.
		var exits: Array = get_nodes_in_group("exit3d")
		if exits.size() > 0:
			var e: Node3D = exits[0]
			_scene._player.global_position = e.global_position + Vector3(0.0, 0.0, 4.5)
	if _frame == 40:
		root.get_texture().get_image().save_png("%s/%s.png" % [_out, SHOTS[_index][1]])
		# Second view: the middle of the map, where walls and props are.
		var props: Array = get_nodes_in_group("prop3d")
		print("%s: %d props" % [SHOTS[_index][1], props.size()])
		if props.size() > 0:
			var prop: Node3D = props[props.size() / 2]
			_scene._player.global_position = prop.global_position + Vector3(0.0, -prop.global_position.y, 9.0)
	if _frame == 80:
		root.get_texture().get_image().save_png("%s/%s_mid.png" % [_out, SHOTS[_index][1]])
		_index += 1
		if _index >= SHOTS.size():
			root.get_node("GameState").delete_save()
			quit()
		else:
			_load(_index)
	return false
