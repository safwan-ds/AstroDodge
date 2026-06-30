extends Control

@export_group("Links to Nodes")
@export var score_label: Label
@export var hp_bar: TextureProgressBar
@export var speed_bar: TextureProgressBar
@export var pause_label: Label
@export var game_over_label: Label
@export var collectibles_counter_label: Label

@onready var gameplay := Global.current_world
@onready var player: Player = gameplay.player

var hp_tween: Tween


func _ready() -> void:
	Global.item_collected.connect(_on_item_collected)
	_on_item_collected()

	player.is_hurt.connect(_on_player_is_hurt)
	player.is_healed.connect(_on_player_is_healed)
	player.is_dead.connect(_on_player_is_dead)

	_set_values()
	hp_bar.value = player.hp

	game_over_label.hide()
	game_over_label.visible_ratio = 0.0

	Global.change_state.connect(_on_change_state)


func _process(_delta) -> void:
	_set_values()


func _input(event):
	if event.is_action_pressed("back"):
		if gameplay.paused or gameplay.game_over:
			gameplay.paused = false
			get_tree().paused = false
			Global.change_state.emit(Global.GameState.MAIN_MENU)
		else:
			gameplay.paused = true
			get_tree().paused = true
			pause_label.show()
			Global.pause_toggled.emit(true)

	if event.is_action_pressed("up"):
		if gameplay.paused:
			gameplay.paused = false
			pause_label.hide()
			get_tree().paused = false
			Global.pause_toggled.emit(false)

		if gameplay.game_over:
			Global.change_state.emit(Global.GameState.GAMEPLAY)


func _set_values() -> void:
	if not gameplay.game_over:
		score_label.text = "Score: " + str(int(gameplay.score)) + "\n(x" + str(snapped(gameplay.score_multiplier, 0.01)) + ")"
		speed_bar.value = player.speed


func _flash_hp_bar(target_hp: float, flash_color: Color) -> void:
	if hp_tween:
		hp_tween.kill()
	hp_bar.tint_progress = flash_color
	hp_tween = create_tween().set_parallel()
	hp_tween.tween_property(hp_bar, "value", target_hp, 0.5).set_trans(Tween.TRANS_QUAD)
	hp_tween.tween_property(hp_bar, "tint_progress", Color.WHITE, 0.5).set_trans(Tween.TRANS_QUAD)


func _on_item_collected() -> void:
	collectibles_counter_label.text = str(gameplay.collectibles_counter_temp)


func _on_player_is_hurt(hp: float) -> void:
	_flash_hp_bar(hp, Color(1, 0, 0))


func _on_player_is_healed(hp: float) -> void:
	_flash_hp_bar(hp, Color(0, 1, 0))


func _on_player_is_dead() -> void:
	AudioManager.stop_music()
	score_label.text = "Score: " + str(int(gameplay.score))
	pause_label.hide()
	game_over_label.show()
	create_tween().tween_property(game_over_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_QUAD)


## Stop processing input when leaving the current state for a different one.
## Does NOT disable on same-state emissions (e.g. game-over restart) to avoid
## locking the GUI if the transition guard rejects the request.
func _on_change_state(state: Global.GameState) -> void:
	if state != Global.current_state:
		set_process_mode(PROCESS_MODE_DISABLED)
