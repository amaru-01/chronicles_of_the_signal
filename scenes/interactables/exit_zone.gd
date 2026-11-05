class_name ExitZone
extends Area2D
## Walk into this to leave the district. Loads `next_scene` if it exists,
## otherwise shows a placeholder message (until the next district is built).

@export_file("*.tscn") var next_scene: String = "res://ui/end_screen.tscn"
@export var next_district: String = "district_01"
@export var placeholder_lines: Array[String] = ["The way on is not built yet.", "End of District 01."]

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	if next_scene != "" and ResourceLoader.exists(next_scene):
		GameState.current_district = next_district
		SceneManager.change_scene(next_scene)
		return
	Dialogue.start("SYSTEM", placeholder_lines)
	await Dialogue.finished
	body.global_position += Vector2(-64, 0)  # step back so it can trigger again
	_triggered = false
