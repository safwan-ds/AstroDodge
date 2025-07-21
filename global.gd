extends Node
signal change_state_sign(state: GameState)
signal quit_game_signal

enum GameState {MAIN_MENU, GAMEPLAY}


func change_state(state: GameState):
	change_state_sign.emit(state)


func quit_game():
	quit_game_signal.emit()
