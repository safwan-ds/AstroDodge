class_name Main extends Node

@export var world_2d: Node2D
@export var gui: CanvasLayer
@export var transitions: CanvasLayer
@export var fps_label: Label
@export var first_transition_in: Control

# All States
@export var main_menu: PackedScene
@export var main_menu_bg: PackedScene
@export var gameplay_scene: PackedScene
@export var gameplay_gui: PackedScene
@export var transition_scene: PackedScene

var prev_window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var current_window_mode: int
var current_world: PackedScene
var current_gui: PackedScene


func _ready():
	first_transition_in.get_node("AnimationPlayer").play_backwards("dissolve")
	Global.change_state_sign.connect(_change_state)
	Global.quit_game_signal.connect(_quit_game)
	current_world = main_menu_bg
	current_gui = main_menu
	await first_transition_in.get_node("AnimationPlayer").animation_finished
	first_transition_in.queue_free()


func _input(event):
	if event.is_action_pressed("full_screen"):
		current_window_mode = DisplayServer.window_get_mode()
		if current_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(prev_window_mode)
		else:
			prev_window_mode = current_window_mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_update_interval_timeout() -> void:
	fps_label.set_deferred("text", int(Engine.get_frames_per_second()))


func _change_state(state: Global.GameState):
	var transition_data := await _transition_in()
	for g in [world_2d, gui]:
		for child in g.get_children():
			child.queue_free()

	match state:
		Global.GameState.MAIN_MENU:
			current_world = main_menu_bg
			current_gui = main_menu
			AudioManager.stop_music()
		Global.GameState.GAMEPLAY:
			current_world = gameplay_scene
			current_gui = gameplay_gui
			AudioManager.play_music(AudioManager.Music.GAMEPLAY)

	world_2d.add_child(current_world.instantiate())
	gui.add_child(current_gui.instantiate())
	_transition_out(transition_data)


func _transition_in() -> Array:
	var transition_node: Control = transition_scene.instantiate()
	transitions.add_child(transition_node)
	var transition_animation: AnimationPlayer = transition_node.get_node("AnimationPlayer")
	transition_animation.play("dissolve")
	await transition_animation.animation_finished
	return [transition_node, transition_animation]


func _transition_out(transition_data: Array) -> void:
	var transition_node: Control = transition_data[0]
	var transition_animation: AnimationPlayer = transition_data[1]
	transition_animation.play_backwards("dissolve")
	await transition_animation.animation_finished
	transition_node.queue_free()


func _quit_game() -> void:
	await _transition_in()
	get_tree().quit()