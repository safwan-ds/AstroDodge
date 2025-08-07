extends Node
# Global signals
signal change_state(state: GameState)
signal show_popup(popup: PackedScene)
signal quit_game
# Gameplay signals
signal trigger_camera_shake(intensity: int)
signal item_collected

enum GameState {MAIN_MENU, GAMEPLAY}
enum CollectibleType {J_UNIT, C_UNIT, DDX6_CHIP, MX3_CHIP, ASM_UNIT}
const COLLECTIBLE_TYPE_STRINGS = {
	CollectibleType.J_UNIT: "J-unit",
	CollectibleType.C_UNIT: "C-unit",
	CollectibleType.DDX6_CHIP: "DDx6-chip",
	CollectibleType.MX3_CHIP: "Mx3-chip",
	CollectibleType.ASM_UNIT: ".asm-unit",
}
const SAVE_FILE_PATH = "user://data_save.res"

# Data save
var data_save: DataSave

# Current game state
var current_world: Node2D
var current_gui: Control
var current_state: GameState = GameState.MAIN_MENU

# Screen mode switching
var _prev_window_mode := DisplayServer.WINDOW_MODE_WINDOWED
var _current_window_mode: DisplayServer.WindowMode


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if FileAccess.file_exists(SAVE_FILE_PATH):
		data_save = load(SAVE_FILE_PATH)
	else:
		data_save = DataSave.new()
		data_save.collectibles_counter.resize(CollectibleType.size())


func _input(event) -> void:
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
