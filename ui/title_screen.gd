extends Control
## Title screen. Browsers block audio until a click or key press, so every
## web build should start here.

const GAME_SCENE: String = "res://scenes/world/test_world.tscn"
const HERO_START_X: float = -100.0
const HERO_END_X: float = 1380.0

@onready var _start: Button = $Center/VBox/StartButton
@onready var _quit: Button = $Center/VBox/QuitButton
@onready var _hero: CharacterSprite = $Hero
@onready var _fx: ScreenFX = $ScreenFX


func _ready() -> void:
	_start.pressed.connect(_on_start_pressed)
	_quit.pressed.connect(get_tree().quit)
	_quit.visible = not OS.has_feature("web")  # web builds can't quit
	_start.grab_focus()
	_walk_hero()
	_glitch_loop()


func _on_start_pressed() -> void:
	GameState.reset()
	SceneManager.change_scene(GAME_SCENE)


## The runner crosses the bottom of the screen forever.
func _walk_hero() -> void:
	_hero.play("walk_right")
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_hero, "position:x", HERO_END_X, 12.0).from(HERO_START_X)


## A glitch burst every few seconds (a child Timer dies with this scene).
func _glitch_loop() -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		_fx.pulse(0.6, 0.3)
		timer.start(randf_range(3.0, 6.0))
	)
	timer.start(randf_range(2.0, 4.0))
