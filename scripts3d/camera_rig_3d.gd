class_name CameraRig3D
extends Node3D
## Fixed-angle follow camera (like the reference image). The rig tracks the target
## on the ground plane; the Camera3D sits at a fixed offset and looks at the rig.

@export var target: Node3D
## Low camera behind the player, looking slightly down (about 17 degrees), like the
## reference image. `look_height` aims at the character's chest rather than the feet.
@export var offset: Vector3 = Vector3(0.0, 3.2, 6.6)
@export var look_height: float = 1.2
@export var yaw_degrees: float = 0.0
@export var follow_speed: float = 7.0
@export var fov: float = 52.0

var camera: Camera3D
## Ground-plane limits (x, z) the rig is clamped to, so the void is never framed.
var bounds: Rect2 = Rect2(-1000, -1000, 2000, 2000)


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = fov
	camera.near = 0.3
	camera.far = 140.0
	add_child(camera)
	camera.position = offset.rotated(Vector3.UP, deg_to_rad(yaw_degrees))
	_aim()
	if target:
		global_position = _clamped(target.global_position)


func _process(delta: float) -> void:
	if target == null:
		return
	var goal: Vector3 = _clamped(target.global_position)
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_aim()


func _aim() -> void:
	camera.look_at(global_position + Vector3(0.0, look_height, 0.0), Vector3.UP)


func _clamped(point: Vector3) -> Vector3:
	return Vector3(
		clampf(point.x, bounds.position.x, bounds.end.x),
		0.0,
		clampf(point.z, bounds.position.y, bounds.end.y)
	)
