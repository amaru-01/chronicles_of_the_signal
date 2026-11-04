extends CanvasLayer
## Pause overlay. Runs while the tree is paused (process_mode = Always).

const TITLE_SCENE: String = "res://ui/title_screen.tscn"

@onready var _resume: Button = $Dim/Center/VBox/ResumeButton
@onready var _menu: Button = $Dim/Center/VBox/MenuButton
@onready var _quit: Button = $Dim/Center/VBox/QuitButton


func _ready() -> void:
	visible = false
	_resume.pressed.connect(_set_paused.bind(false))
	_menu.pressed.connect(func() -> void: SceneManager.change_scene(TITLE_SCENE))
	_quit.pressed.connect(get_tree().quit)
	_quit.visible = not OS.has_feature("web")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not Dialogue.is_active and not GameState.minigame_active:
		get_viewport().set_input_as_handled()
		_set_paused(not get_tree().paused)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if paused:
		_resume.grab_focus()
