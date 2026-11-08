class_name WorldMap3D
extends RefCounted
## Registry of the 3D districts and the travel helper. District ids are prefixed "3d_"
## so they never clash with the 2D game's ids in GameState (checkpoints, saves).

const HUB: String = "3d_hub"

const DISTRICTS: Dictionary = {
	"3d_hub": {"title": "VANTAGE PLAZA", "scene": "res://scenes3d/hub_3d.tscn"},
	"3d_district_01": {"title": "DISTRICT 01 - STATIC ROW", "scene": "res://scenes3d/district_01_3d.tscn"},
	"3d_district_02": {"title": "DISTRICT 02 - THE ARCHIVE", "scene": "res://scenes3d/district_02_3d.tscn"},
	"3d_district_03": {"title": "DISTRICT 03 - NEON MARKET", "scene": "res://scenes3d/district_03_3d.tscn"},
	"3d_relay_tower": {"title": "THE RELAY TOWER", "scene": "res://scenes3d/relay_tower_3d.tscn"},
}


static func title_of(district_id: String) -> String:
	return str((DISTRICTS.get(district_id, {}) as Dictionary).get("title", district_id.to_upper()))


static func scene_of(district_id: String) -> String:
	return str((DISTRICTS.get(district_id, {}) as Dictionary).get("scene", ""))


## Flag set the first time the player touches a beacon in `district_id`.
static func fast_travel_flag(district_id: String) -> String:
	return "ft_" + district_id


static func is_unlocked(district_id: String) -> bool:
	return district_id == HUB or GameState.flags.has(fast_travel_flag(district_id))


## Go to a district. `spawn` names the entry point (see District3D._spawn_cells);
## an empty string uses the last checkpoint, or the district's "start" point.
static func travel(district_id: String, spawn: String = "") -> void:
	var path: String = scene_of(district_id)
	if path == "":
		push_error("WorldMap3D: unknown district %s" % district_id)
		return
	GameState.flags["spawn_3d"] = spawn
	GameState.current_district = district_id
	GameState.current_layer = GameState.WorldLayer.PHYSICAL
	SceneManager.change_scene(path)
