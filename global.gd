extends Node
signal change_state_sign(state: GameState)

enum GameState {MAIN_MENU, GAMEPLAY}


func change_state(state: GameState):
	change_state_sign.emit(state)