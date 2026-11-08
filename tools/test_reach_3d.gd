extends SceneTree
## Dev tool: automated "can the player get there" playtest. Usage:
##   godot --path . --script res://tools/test_reach_3d.gd -- <output_dir>
## For every 3D district it flood-fills the map from the spawn points following the real
## movement rules (walk in the current world, swap worlds only on a cell that is open in
## both) and checks that every terminal, switch, pickup, NPC, beacon and exit can be
## reached. Gates are treated as open (they open when their puzzle is solved), so this finds
## rooms that are sealed off by walls, not puzzle logic. Untyped on purpose (autoloads).

const SCENES: Array = [
	"res://scenes3d/hub_3d.tscn",
	"res://scenes3d/district_01_3d.tscn",
	"res://scenes3d/district_02_3d.tscn",
	"res://scenes3d/district_03_3d.tscn",
	"res://scenes3d/relay_tower_3d.tscn",
]

var _results: PackedStringArray = PackedStringArray()
var _failed: bool = false


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://dev_test_save.json"
	_run()


func _check(label: String, condition: bool) -> void:
	_results.append("%s  %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		_failed = true


func _open(layers: Node, layer: int, cx: int, cy: int) -> bool:
	return cx >= 0 and cy >= 0 and cx < layers.map_size.x and cy < layers.map_size.y \
		and not layers.is_wall(layer, cx, cy)


## All (cell, world) states the player can stand in, from the given start cells.
func _flood(layers: Node, starts: Array) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array = []
	for cell: Vector2 in starts:
		var key := Vector3i(int(cell.x), int(cell.y), 0)
		seen[key] = true
		queue.append(key)
	var steps: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var here: Vector3i = queue.pop_back()
		for step: Vector2i in steps:
			var next := Vector3i(here.x + step.x, here.y + step.y, here.z)
			if not seen.has(next) and _open(layers, here.z, next.x, next.y):
				seen[next] = true
				queue.append(next)
		# Swapping worlds is only possible where both worlds are open.
		var flipped := Vector3i(here.x, here.y, 1 - here.z)
		if not seen.has(flipped) and _open(layers, 0, here.x, here.y) and _open(layers, 1, here.x, here.y):
			seen[flipped] = true
			queue.append(flipped)
	return seen


## Can the player be within one cell of `pos` in a world this object exists in?
func _reachable(seen: Dictionary, layers: Node, pos: Vector3, worlds: Array) -> bool:
	var cx: int = int(floor(pos.x / layers.TILE))
	var cy: int = int(floor(pos.z / layers.TILE))
	for w: int in worlds:
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				if seen.has(Vector3i(cx + dx, cy + dy, w)):
					return true
	return false


func _run() -> void:
	for path: String in SCENES:
		var scene: Node = (load(path) as PackedScene).instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		var layers: Node = scene._layers
		var starts: Array = scene._spawn_cells().values()
		var seen: Dictionary = _flood(layers, starts)
		var name: String = path.get_file()
		var checked: int = 0
		var bad: PackedStringArray = PackedStringArray()

		for node: Node in get_nodes_in_group("interactable3d"):
			var n3: Node3D = node as Node3D
			var worlds: Array = [0, 1]
			var realm: int = int(node.get("realm")) if node.get("realm") != null else 2
			if realm == 0:
				worlds = [0]
			elif realm == 1:
				worlds = [1]
			checked += 1
			if not _reachable(seen, layers, n3.global_position, worlds):
				bad.append("%s at (%.0f, %.0f)" % [node.get_script().get_global_name(), n3.global_position.x, n3.global_position.z])
		for group: String in ["exit3d", "beacon3d"]:
			for node: Node in get_nodes_in_group(group):
				var n3: Node3D = node as Node3D
				checked += 1
				if not _reachable(seen, layers, n3.global_position, [0, 1]):
					bad.append("%s at (%.0f, %.0f)" % [group, n3.global_position.x, n3.global_position.z])
		# The cells the player spawns in must themselves be open.
		for cell: Vector2 in starts:
			checked += 1
			if not _open(layers, 0, int(cell.x), int(cell.y)):
				bad.append("spawn cell %s is a wall" % cell)

		# Control: a flood that starts inside solid wall goes nowhere, so the spawn area must
		# then read as unreachable. This proves the check can actually fail.
		var sealed: Dictionary = _flood(layers, [Vector2(0, 0)])
		_check("%s: control: flooding from inside a wall reaches nothing" % name,
			not _reachable(sealed, layers, layers.cell_to_world(starts[0]), [0, 1]))
		_check("%s: all %d targets reachable%s" % [name, checked, "" if bad.is_empty() else "  UNREACHABLE: " + ", ".join(bad)], bad.is_empty())
		scene.queue_free()
		await process_frame

	root.get_node("GameState").delete_save()
	print("\n".join(_results))
	print("RESULT: %s" % ("FAILED" if _failed else "ALL PASSED"))
	quit(1 if _failed else 0)
