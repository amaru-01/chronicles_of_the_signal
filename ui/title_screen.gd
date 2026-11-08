extends Control
## Title screen. Browsers block audio until a click or key press, so every
## web build should start here.

const GAME_SCENE: String = "res://scenes/world/district_01.tscn"
## The 3D game starts in the hub (see scripts3d/world_map_3d.gd).
const GAME_3D_DISTRICT: String = "3d_hub"
const HERO_START_X: float = -100.0
const HERO_END_X: float = 1380.0

@onready var _continue: Button = $Center/VBox/ContinueButton
@onready var _start: Button = $Center/VBox/StartButton
@onready var _start_3d: Button = $Center/VBox/Start3DButton
@onready var _quit: Button = $Center/VBox/QuitButton
@onready var _hero: CharacterSprite = $Hero
@onready var _fx: ScreenFX = $ScreenFX


func _ready() -> void:
	_start.pressed.connect(_on_start_pressed)
	_continue.pressed.connect(_on_continue_pressed)
	_continue.visible = GameState.has_save()
	_continue.text = "Continue (3D)" if GameState.saved_district().begins_with("3d_") else "Continue"
	_start_3d.pressed.connect(_on_start_3d_pressed)
	# The 3D game targets desktop; the browser build stays the 2D demo.
	_start_3d.visible = not OS.has_feature("web")
	Audio.play_music("title")
	_quit.pressed.connect(get_tree().quit)
	_quit.visible = not OS.has_feature("web")  # web builds can't quit
	(_continue if _continue.visible else (_start_3d if _start_3d.visible else _start)).grab_focus()
	_walk_hero()
	_glitch_loop()


func _on_continue_pressed() -> void:
	if GameState.load_game():
		SceneManager.change_scene(GameState.district_scene())


func _on_start_pressed() -> void:
	GameState.reset()
	GameState.delete_save()
	SceneManager.change_scene(GAME_SCENE)


func _on_start_3d_pressed() -> void:
	GameState.reset()
	GameState.delete_save()
	WorldMap3D.travel(GAME_3D_DISTRICT, "start")


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
