class_name Player
extends CharacterBody2D
## Top-down player. 300 px/s matches the old Arcade speed (5 px/frame at 60 fps).

const SPEED: float = 300.0

## The collision box is just the feet, so the head can overlap walls (top-down look).
const FEET_SIZE: Vector2 = Vector2(16, 12)
const FEET_OFFSET: Vector2 = Vector2(0, 16)

var _nearby: Array[Interactable] = []
var _target: Interactable
var _step_timer: float = 0.0

@onready var _sprite: CharacterSprite = $Sprite
@onready var _interact_area: Area2D = $InteractArea


func _ready() -> void:
	add_to_group("player")
	_interact_area.area_entered.connect(_on_area_entered)
	_interact_area.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	if Dialogue.is_active:
		velocity = Vector2.ZERO
	else:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
	_sprite.update_motion(velocity)
	_step_timer -= delta
	if velocity.length() > 1.0 and _step_timer <= 0.0:
		_step_timer = 0.32
		Audio.sfx("step", -8.0)
	_update_target()


func _unhandled_input(event: InputEvent) -> void:
	if Dialogue.is_active or not event.is_action_pressed("interact"):
		return
	if is_instance_valid(_target):
		get_viewport().set_input_as_handled()
		_target.interact(self)


## The feet box in global space (what physically collides).
func get_rect() -> Rect2:
	return Rect2(global_position + FEET_OFFSET - FEET_SIZE / 2.0, FEET_SIZE)


## Corner points of the feet box in global space.
func get_corners() -> Array[Vector2]:
	var r: Rect2 = get_rect()
	return [r.position, r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), r.end]


## Pick the closest interactable in range and show only its prompt.
func _update_target() -> void:
	var best: Interactable = null
	var best_distance: float = INF
	for candidate: Interactable in _nearby:
		if not is_instance_valid(candidate):
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	if best != _target:
		if is_instance_valid(_target):
			_target.set_prompt_visible(false)
		_target = best
	if is_instance_valid(_target):
		_target.set_prompt_visible(not Dialogue.is_active)


func _on_area_entered(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable and not _nearby.has(interactable):
		_nearby.append(interactable)


func _on_area_exited(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable:
		_nearby.erase(interactable)
		interactable.set_prompt_visible(false)
