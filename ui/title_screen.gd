extends Control
## Title screen. Browsers block audio until a click or key press, so every
## web build should start here.

const GAME_SCENE: String = "res://scenes/world/test_world.tscn"

@onready var _start: Button = $Center/VBox/StartButton
@onready var _quit: Button = $Center/VBox/QuitButton


func _ready() -> void:
	_start.pressed.connect(_on_start_pressed)
	_quit.pressed.connect(get_tree().quit)
	_quit.visible = not OS.has_feature("web")  # web builds can't quit
	_start.grab_focus()


func _on_start_pressed() -> void:
	GameState.reset()
	SceneManager.change_scene(GAME_SCENE)
