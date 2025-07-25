class_name QuitPopup extends Control

@export var animation_player: AnimationPlayer

var canceled := false

func _ready():
	animation_player.play("quit_popup")


func _on_quit_button_pressed() -> void:
	if not canceled:
		Global.quit_game.emit()


func _on_cancel_button_pressed() -> void:
	close()


func close() -> void:
	canceled = true
	animation_player.play_backwards("quit_popup")
	await animation_player.animation_finished
	queue_free()