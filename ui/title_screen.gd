extends Control
## Title screen: New Game (plays the intro), Continue (resumes the saved district) and Quit.

const INTRO_SCENE: String = "res://scenes3d/intro_3d.tscn"
const HERO_START_X: float = -100.0
const HERO_END_X: float = 1380.0

@onready var _continue: Button = $Center/VBox/ContinueButton
@onready var _new_game: Button = $Center/VBox/NewGameButton
@onready var _quit: Button = $Center/VBox/QuitButton
@onready var _hero: Sprite2D = $Hero
@onready var _fx: ScreenFX = $ScreenFX


func _ready() -> void:
	_new_game.pressed.connect(_on_new_game_pressed)
	_continue.pressed.connect(_on_continue_pressed)
	_continue.visible = GameState.has_save()
	Audio.play_music("title")
	_quit.pressed.connect(get_tree().quit)
	_quit.visible = not OS.has_feature("web")  # web builds can't quit
	(_continue if _continue.visible else _new_game).grab_focus()
	_walk_hero()
	_glitch_loop()


func _process(_delta: float) -> void:
	# Walk cycle: sheet row 2 is "facing right", columns 1 to 4 are the walk frames.
	_hero.frame_coords = Vector2i(1 + int(Time.get_ticks_msec() / 130.0) % 4, 2)


func _on_continue_pressed() -> void:
	if GameState.load_game():
		SceneManager.change_scene(GameState.district_scene())
	else:
		# Unreadable save: hide the dead button instead of doing nothing. The file is left
		# alone so it can still be inspected; New Game overwrites it.
		push_warning("Title: save file could not be read")
		_continue.visible = false
		_new_game.grab_focus()


func _on_new_game_pressed() -> void:
	GameState.reset()
	GameState.delete_save()
	# The opening cinematic plays first; it hands over to the hub when it ends.
	SceneManager.change_scene(INTRO_SCENE)


## The runner crosses the bottom of the screen forever.
func _walk_hero() -> void:
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
