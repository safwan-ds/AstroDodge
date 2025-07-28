extends Control

@export var quit_popup_scene: PackedScene

@export var continue_button: Button # TODO: make it visible when there is a saved game
@export var animation_player: AnimationPlayer

var _quit_popup: QuitPopup


func _ready():
	randomize()
	var anim_length := animation_player.get_animation("logo_loop").length
	var random_start_time := randf() * anim_length
	animation_player.play("logo_loop")
	animation_player.seek(random_start_time, true)


func _input(event):
	if event.is_action_pressed("back"):
		_quit_popup_show()


func _on_quit_button_pressed() -> void:
	_quit_popup_show()


func _on_new_game_button_pressed() -> void:
	Global.change_state.emit(Global.GameState.GAMEPLAY)


func _quit_popup_show() -> void:
	if not _quit_popup:
		_quit_popup = quit_popup_scene.instantiate()
		Global.show_popup.emit(_quit_popup)
	else:
		_quit_popup.close()
