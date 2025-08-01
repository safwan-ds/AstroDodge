extends Node
signal change_state(state: GameState)
signal show_popup(popup: PackedScene)
signal quit_game
signal trigger_camera_shake(intensity: int)

enum GameState {MAIN_MENU, GAMEPLAY}

# Current game state
var current_world: Node2D
var current_gui: Control
var current_state: GameState = GameState.MAIN_MENU

# Screen mode switching
var _prev_window_mode := DisplayServer.WINDOW_MODE_WINDOWED
var _current_window_mode: DisplayServer.WindowMode


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event):
	if event.is_action_pressed("full_screen"):
		_current_window_mode = DisplayServer.window_get_mode()
		if _current_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(_prev_window_mode)
		else:
			_prev_window_mode = _current_window_mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Debugging inputs
	if OS.is_debug_build():
		if event.is_action_pressed("_dev_console") and DevConsole:
			DevConsole.visible = not DevConsole.visible
			DevConsole.input_text.grab_focus()
