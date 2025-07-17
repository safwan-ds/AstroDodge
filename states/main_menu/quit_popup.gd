extends Control

@export var animation_player: AnimationPlayer

var canceled := false

func _ready():
	animation_player.play("quit_popup")


func _on_quit_button_pressed() -> void:
	if not canceled:
		get_tree().quit()


func _on_cancel_button_pressed() -> void:
	canceled = true
	animation_player.play_backwards("quit_popup")
	await animation_player.animation_finished
	queue_free()
