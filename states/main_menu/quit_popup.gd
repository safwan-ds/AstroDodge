class_name QuitPopup extends Control
## Quit confirmation popup. Animated entrance/exit.[br]
## Emits [signal Global.quit_game] on confirm.

@export var animation_player: AnimationPlayer

var canceled := false


func _ready():
	animation_player.play("quit_popup")


func _input(event):
	if event.is_action_pressed("back"):
		close()


func _on_quit_button_pressed() -> void:
	if not canceled:
		Global.quit_game.emit()


func _on_cancel_button_pressed() -> void:
	close()


## Play exit animation then queue_free. Sets [member canceled] flag to prevent double-action.
func close() -> void:
	canceled = true
	animation_player.play_backwards("quit_popup")
	await animation_player.animation_finished
	queue_free()
