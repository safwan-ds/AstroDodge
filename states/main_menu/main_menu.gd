extends Control
## Main menu screen with logo animation and buttons for New Game / Quit.

@export var quit_popup: PackedScene

@export var continue_button: Button # TODO: make it visible when there is a saved game
@export var animation_player: AnimationPlayer
@export_group("Debug")
@export var collectibles_label: Label


func _ready() -> void:
	animation_player.play("logo_loop")
	animation_player.seek(
		randf() * animation_player.get_animation("logo_loop").length,
		true,
	)
	collectibles_label.text = "Collectibles: " + str(Global.data_save.collectibles_counter)


func _input(event):
	if event.is_action_pressed("back"):
		_quit_popup_show()


func _on_quit_button_pressed() -> void:
	_quit_popup_show()


func _on_new_game_button_pressed() -> void:
	Global.change_state.emit(Global.GameState.GAMEPLAY)


func _quit_popup_show() -> void:
	Global.show_popup.emit(quit_popup)
