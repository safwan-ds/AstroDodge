extends Node
signal change_state(state: GameState)
signal quit_game
signal trigger_camera_shake(strength: int)

enum GameState {MAIN_MENU, GAMEPLAY}

# Screen mode switching
var prev_window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var current_window_mode: int

# Current game state
var current_world: Node2D
var current_gui: Control
var current_state: GameState = GameState.MAIN_MENU


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event):
	if event.is_action_pressed("full_screen"):
		current_window_mode = DisplayServer.window_get_mode()
		if current_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(prev_window_mode)
		else:
			prev_window_mode = current_window_mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Debugging inputs
	if OS.is_debug_build():
		if event.is_action_pressed("_dev_console"):
			DevConsole.visible = not DevConsole.visible
			DevConsole.input_text.grab_focus()
