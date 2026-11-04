class_name Player
extends CharacterBody2D
## Top-down player. 300 px/s matches the old Arcade speed (5 px/frame at 60 fps).

const SPEED: float = 300.0

## Half-size of the collision box, used by WorldLayers to test a layer swap.
const HALF_SIZE: float = 12.0


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()


## Corner points of the player's box in global space.
func get_corners() -> Array[Vector2]:
	var p: Vector2 = global_position
	return [
		p + Vector2(-HALF_SIZE, -HALF_SIZE),
		p + Vector2(HALF_SIZE, -HALF_SIZE),
		p + Vector2(-HALF_SIZE, HALF_SIZE),
		p + Vector2(HALF_SIZE, HALF_SIZE),
	]
