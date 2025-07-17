extends Node2D


func _input(event):
	if event.is_action_pressed("back"):
		Global.change_state(Global.GameState.MAIN_MENU)