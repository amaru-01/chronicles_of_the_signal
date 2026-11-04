class_name CharacterSprite
extends AnimatedSprite2D
## Builds walk/idle animations from a sprite sheet and faces the right way.
##
## Sheet layout (32x48 cells): columns = [idle, walk1..walk4],
## rows = [down, left, right, up]. Replace the PNG with your own art that
## follows the same layout and nothing else needs to change.

const DIRECTIONS: Array[String] = ["down", "left", "right", "up"]
const WALK_FPS: float = 9.0

@export var sheet: Texture2D
@export var cell_size: Vector2i = Vector2i(32, 48)

var facing: String = "down"


func _ready() -> void:
	sprite_frames = _build_frames()
	play("idle_down")


## Call every physics frame with the current velocity.
func update_motion(velocity: Vector2) -> void:
	var moving: bool = velocity.length() > 1.0
	if moving:
		if absf(velocity.x) > absf(velocity.y):
			facing = "left" if velocity.x < 0.0 else "right"
		else:
			facing = "up" if velocity.y < 0.0 else "down"
	play(("walk_" if moving else "idle_") + facing)


func face_towards(point: Vector2) -> void:
	var delta: Vector2 = point - global_position
	if absf(delta.x) > absf(delta.y):
		facing = "left" if delta.x < 0.0 else "right"
	else:
		facing = "up" if delta.y < 0.0 else "down"
	play("idle_" + facing)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row: int in DIRECTIONS.size():
		var dir: String = DIRECTIONS[row]
		var idle: String = "idle_" + dir
		frames.add_animation(idle)
		frames.set_animation_loop(idle, true)
		frames.set_animation_speed(idle, 1.0)
		frames.add_frame(idle, _cell(0, row))
		var walk: String = "walk_" + dir
		frames.add_animation(walk)
		frames.set_animation_loop(walk, true)
		frames.set_animation_speed(walk, WALK_FPS)
		for col: int in range(1, 5):
			frames.add_frame(walk, _cell(col, row))
	return frames


func _cell(col: int, row: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = Rect2(col * cell_size.x, row * cell_size.y, cell_size.x, cell_size.y)
	return tex
