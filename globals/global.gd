extends Node
## Global autoload singleton for signals, shared state, enums, and save data.[br]
## Lives across all scenes.
signal change_state(state: GameState) ## Emitted when transitioning between MAIN_MENU and GAMEPLAY.
signal show_popup(popup: PackedScene) ## Emitted to display a popup (e.g., quit confirmation).
signal quit_game ## Emitted to start the quit sequence.
signal trigger_camera_shake(intensity: int) ## Emitted to shake the camera with given intensity.
signal explosion_occurred(world_position: Vector2, world_scale: float) ## Emitted on entity death with world position and entity scale (consumed by SpaceWarp overlay).
signal item_collected ## Emitted when any collectible is picked up.
signal pause_toggled(is_paused: bool) ## Emitted when the game is paused or resumed.

enum GameState {MAIN_MENU, GAMEPLAY}
enum CollectibleType {J_UNIT, CAP_UNIT, DDRX_CHIP, M2_CHIP, ASM_UNIT}

const COLLECTIBLE_NAMES: Dictionary = {
	CollectibleType.J_UNIT: "J-unit",
	CollectibleType.CAP_UNIT: "Cap-unit",
	CollectibleType.DDRX_CHIP: "DDRx-chip",
	CollectibleType.M2_CHIP: "M2-chip",
	CollectibleType.ASM_UNIT: "ASM-unit",
}
const SAVE_FILE_PATH = "user://data_save.res"

var data_save: DataSave
var current_world: Node2D
var current_gui: Control
var current_state: GameState = GameState.MAIN_MENU

var _prev_window_mode := DisplayServer.WINDOW_MODE_WINDOWED
var _current_window_mode: DisplayServer.WindowMode

var _data_save_timer: SceneTreeTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if FileAccess.file_exists(SAVE_FILE_PATH):
		data_save = load(SAVE_FILE_PATH)
		if data_save == null or not data_save is DataSave:
			push_warning("Save file corrupted, creating new data.")
			_create_new_data_save()
		elif data_save.collectibles_counter.size() != CollectibleType.size():
			_create_new_data_save()


func _input(event) -> void:
	if event.is_action_pressed("full_screen"):
		_current_window_mode = DisplayServer.window_get_mode()
		if _current_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(_prev_window_mode)
		else:
			_prev_window_mode = _current_window_mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if OS.is_debug_build():
		if event.is_action_pressed("_dev_console") and DevConsole:
			DevConsole.visible = not DevConsole.visible
			if DevConsole.visible:
				DevConsole.input_text.grab_focus()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		data_save.flush()


func _start_data_save_timer() -> void:
	if _data_save_timer:
		return
	_data_save_timer = get_tree().create_timer(1.0)
	_data_save_timer.timeout.connect(_on_data_save_timer_timeout)


func _on_data_save_timer_timeout() -> void:
	_data_save_timer = null
	data_save.flush()


func _create_new_data_save() -> void:
	data_save = DataSave.new()
	data_save.collectibles_counter.resize(CollectibleType.size())
