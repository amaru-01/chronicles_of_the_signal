class_name Quests3D
extends RefCounted
## Data-driven quest log (data3d/quests.json). State lives in GameState.flags["quests3d"]
## so it is saved with the game. Call `evaluate()` regularly: it starts quests whose
## prerequisites are met, ticks objectives, completes quests and hands out rewards, and
## returns what happened so the HUD can announce it.
##
## Objective conditions ("cond"):
##   {"type": "hacked", "id": ...}            a terminal / switch id has been hacked
##   {"type": "hacked_all", "ids": [...]}     all of them
##   {"type": "flag", "id": ...}              GameState.flags has a truthy value
##   {"type": "items", "prefix": ..., "count": n}   n inventory items with that id prefix
##   {"type": "counter", "id": ..., "count": n}     flags[id] >= n (e.g. "kills")
##   {"type": "visited", "id": district_id}   the player has entered that district

const DATA_PATH: String = "res://data3d/quests.json"
const STATE_KEY: String = "quests3d"

static var _defs: Array = []


static func defs() -> Array:
	if _defs.is_empty():
		var resource: JSON = load(DATA_PATH) as JSON
		if resource != null and resource.data is Dictionary:
			_defs = (resource.data as Dictionary).get("quests", [])
		else:
			push_error("Quests3D: cannot read %s" % DATA_PATH)
	return _defs


static func _state() -> Dictionary:
	if not GameState.flags.has(STATE_KEY) or not GameState.flags[STATE_KEY] is Dictionary:
		GameState.flags[STATE_KEY] = {}
	return GameState.flags[STATE_KEY]


static func get_def(quest_id: String) -> Dictionary:
	for quest: Dictionary in defs():
		if quest["id"] == quest_id:
			return quest
	return {}


## "locked" (prerequisites not met yet), "active" or "done".
static func status(quest_id: String) -> String:
	var entry: Variant = _state().get(quest_id)
	if entry is Dictionary:
		return str((entry as Dictionary).get("state", "locked"))
	return "locked"


static func objective_done(quest_id: String, index: int) -> bool:
	var entry: Variant = _state().get(quest_id)
	if entry is Dictionary:
		return ((entry as Dictionary).get("obj", {}) as Dictionary).has(str(index))
	return false


static func check(cond: Dictionary) -> bool:
	match str(cond.get("type", "")):
		"hacked":
			return GameState.is_hacked(str(cond["id"]))
		"hacked_all":
			for id: Variant in cond["ids"]:
				if not GameState.is_hacked(str(id)):
					return false
			return true
		"flag":
			return bool(GameState.flags.get(str(cond["id"]), false))
		"items":
			return progress(cond).x >= int(cond["count"])
		"counter":
			return progress(cond).x >= int(cond["count"])
		"visited":
			return bool(GameState.flags.get("visited_" + str(cond["id"]), false))
	return false


## (have, need) for countable conditions, otherwise (0, 0).
static func progress(cond: Dictionary) -> Vector2i:
	match str(cond.get("type", "")):
		"hacked_all":
			var have: int = 0
			for id: Variant in cond["ids"]:
				if GameState.is_hacked(str(id)):
					have += 1
			return Vector2i(have, (cond["ids"] as Array).size())
		"items":
			var count: int = 0
			for item: String in GameState.inventory:
				if item.begins_with(str(cond["prefix"])):
					count += 1
			return Vector2i(mini(count, int(cond["count"])), int(cond["count"]))
		"counter":
			return Vector2i(mini(int(GameState.flags.get(str(cond["id"]), 0)), int(cond["count"])), int(cond["count"]))
	return Vector2i.ZERO


## Objective text with progress, e.g. "Collect the memory fragments (2/4)".
static func objective_text(objective: Dictionary) -> String:
	var counts: Vector2i = progress(objective["cond"])
	if counts.y > 0:
		return "%s (%d/%d)" % [objective["text"], counts.x, counts.y]
	return str(objective["text"])


## Start, tick and complete quests. Returns events:
##   {"type": "quest_start", "quest": title}
##   {"type": "objective", "quest": title, "text": objective text}
##   {"type": "quest_done", "quest": title, "text": reward text}
static func evaluate() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var state: Dictionary = _state()
	var changed: bool = true
	var passes: int = 0
	while changed and passes < 6:  # a quest finishing can unlock the next one
		changed = false
		passes += 1
		for quest: Dictionary in defs():
			var id: String = quest["id"]
			if status(id) == "locked":
				var ready: bool = true
				for required: Variant in quest.get("requires", []):
					if status(str(required)) != "done":
						ready = false
				if not ready:
					continue
				state[id] = {"state": "active", "obj": {}}
				events.append({"type": "quest_start", "quest": quest["title"]})
				changed = true
			if status(id) == "done":
				continue
			var entry: Dictionary = state[id]
			var objectives: Array = quest["objectives"]
			var all_done: bool = true
			for i: int in objectives.size():
				if (entry["obj"] as Dictionary).has(str(i)):
					continue
				if check((objectives[i] as Dictionary)["cond"]):
					(entry["obj"] as Dictionary)[str(i)] = true
					events.append({"type": "objective", "quest": quest["title"], "text": (objectives[i] as Dictionary)["text"]})
					changed = true
				else:
					all_done = false
			if all_done:
				entry["state"] = "done"
				var reward: Dictionary = quest.get("reward", {})
				for item: Variant in reward.get("items", []):
					if not GameState.inventory.has(str(item)):
						GameState.add_item(str(item))
				events.append({"type": "quest_done", "quest": quest["title"], "text": str(reward.get("text", ""))})
				changed = true
	if not events.is_empty():
		GameState.save_game()
	return events


## What the HUD tracker shows: the first unfinished objective of the first active main
## quest (else side quest). Returns {} when nothing is active.
static func tracked() -> Dictionary:
	for kind: String in ["main", "side"]:
		for quest: Dictionary in defs():
			if quest["kind"] != kind or status(quest["id"]) != "active":
				continue
			var objectives: Array = quest["objectives"]
			for i: int in objectives.size():
				if not objective_done(quest["id"], i):
					return {"quest": quest["title"], "text": objective_text(objectives[i])}
	return {}
