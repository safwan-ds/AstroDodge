extends CanvasLayer

@export var input_text: LineEdit
@export var output_text: RichTextLabel
@export var auto_complete_list: ItemList

var _expression := Expression.new()
var _valid_commands: Array
var _history: Array[String]
var _selected_history_index := -1

@onready var regex := RegEx.new()


# Main Dev Console class methods
func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	hide()
	regex.compile(r"\w+\(?[\w\s\,\"]*\)?")
	_valid_commands = get_script().get_script_method_list().map(func(method: Dictionary) -> String:
		return method.name
	).filter(func(method_name: String) -> bool:
		return not method_name.begins_with("_")
	)

	output_text.clear()
	output_text.push_bold()
	output_text.push_color(Color.WHITE)
	output_text.add_text("Welcome to the Dev Console!\n")
	output_text.add_text("Type a command and press Enter.\n")
	output_text.add_text("Type 'help' for a list of commands.\n")


func _input(event):
	if event is InputEventKey and event.pressed:
		if _history.size() > 0:
			if event.keycode == KEY_UP:
				_selected_history_index = clamp(_selected_history_index + 1, 0, _history.size() - 1)
				input_text.text = _history[_selected_history_index]
				input_text.set_deferred("caret_column", input_text.text.length())
			if event.keycode == KEY_DOWN:
				_selected_history_index = clamp(_selected_history_index - 1, -1, _history.size() - 1)
				input_text.text = _history[_selected_history_index] if _selected_history_index >= 0 else ""
				input_text.set_deferred("caret_column", input_text.text.length())


func _on_input_text_text_changed(new_text: String) -> void:
	var current_caret_column := input_text.caret_column
	input_text.text = regex.search(new_text).get_string() if regex.search(new_text) else ""
	input_text.caret_column = clamp(current_caret_column, 0, input_text.text.length())
	_show_auto_complete()


func _show_auto_complete() -> void:
	var command := input_text.text.strip_edges()
	if command == "":
		auto_complete_list.hide()
		return

	var matches := []
	for valid_command in _valid_commands:
		if valid_command.begins_with(command):
			matches.append(valid_command)

	if matches.size() == 0:
		auto_complete_list.hide()
		return

	auto_complete_list.clear()
	for match in matches:
		auto_complete_list.add_item(match)
	auto_complete_list.show()
	auto_complete_list.select(0)


func _on_auto_complete_list_item_selected(index: int) -> void:
	var command = auto_complete_list.get_item_text(index)
	input_text.text = command
	input_text.set_deferred("caret_column", input_text.text.length())
	auto_complete_list.hide()
	input_text.grab_focus()


func _on_input_text_text_submitted(command: String) -> void:
	input_text.clear()
	input_text.grab_focus()
	_selected_history_index = -1
	
	output_text.push_bold()
	output_text.push_color(Color.WHITE)
	output_text.add_text("> " + command + "\n")

	command = command.strip_edges()
	if command == "":
		return

	if command in _history:
		_history.erase(command)
	_history.insert(0, command)

	if not command.ends_with(")"):
		command += "()"

	var error := _expression.parse(command)
	if error != OK:
		output_text.push_color(Color.RED)
		output_text.add_text("Error: " + _expression.get_error_text() + "\n")
		return

	if command.split("(")[0] not in _valid_commands:
		output_text.push_color(Color.RED)
		output_text.add_text("Unknown command: " + command.split("(")[0] + "\n")
		return

	var result = _expression.execute([], self)
	if not _expression.has_execute_failed():
		output_text.push_color(Color.GREEN)
		output_text.add_text(str(result) + "\n")


# Custom Dev Console commands
func clear() -> String:
	output_text.clear()
	return "Cleared!"


func help():
	return ", ".join(_valid_commands)


func modify_hp(new_hp: float) -> Variant:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player._hp = new_hp
		return player._hp
	return null


func game_over() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player._hp = 0.0


func get_nodes_in_group(group_name: String) -> Array:
	return get_tree().get_nodes_in_group(group_name)


func destroy_all_asteroids() -> void:
	for asteroid in get_tree().get_nodes_in_group("asteroids"):
		asteroid._die()


func destroy_all_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy._die()


func reload() -> void:
	get_tree().reload_current_scene()


func reload_current_state() -> void:
	Global.change_state.emit(Global.current_state)


func shake_camera(intensity: int = 1) -> void:
	Global.trigger_camera_shake.emit(intensity)


func pause() -> String:
	get_tree().paused = not get_tree().paused
	return "Game paused!" if get_tree().paused else "Game resumed!"


func quit() -> void:
	get_tree().quit()
