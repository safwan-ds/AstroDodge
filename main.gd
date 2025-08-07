class_name Main extends Node

@export_group("Links to Nodes")
@export var world_2d: Node2D
@export var gui: CanvasLayer
@export var popups: CanvasLayer
@export var transitions: CanvasLayer
@export var first_transition_in: Control

@export_group("States")
@export var main_menu: PackedScene
@export var main_menu_bg: PackedScene
@export var gameplay_scene: PackedScene
@export var gameplay_gui: PackedScene
@export var transition_scene: PackedScene

@export_group("Cursors")
@export var primary_cursor: PortableCompressedTexture2D
@export var crosshair_cursor: PortableCompressedTexture2D

var selected_world: PackedScene
var selected_gui: PackedScene

var current_world: Node2D:
	set(node):
		if current_world:
			current_world.queue_free()
		current_world = node
		Global.current_world = current_world
var current_gui: Control:
	set(node):
		if current_gui:
			current_gui.queue_free()
		current_gui = node
		Global.current_gui = current_gui

@onready var selected_cursor := primary_cursor
@onready var selected_cursor_hotspot := Vector2.ZERO


func _ready():
	first_transition_in.get_node("AnimationPlayer").play_backwards("dissolve")
	Global.change_state.connect(_change_state)
	Global.show_popup.connect(_show_popup)
	Global.quit_game.connect(_quit_game)
	current_world = world_2d.get_child(0)
	current_gui = gui.get_child(0)
	await first_transition_in.get_node("AnimationPlayer").animation_finished
	first_transition_in.queue_free()


func _change_state(state: Global.GameState):
	var transition_data := await _transition_in()
	for node in [world_2d, gui]:
		for child in node.get_children():
			child.queue_free()

	match state:
		Global.GameState.MAIN_MENU:
			selected_world = main_menu_bg
			selected_gui = main_menu
			selected_cursor = primary_cursor
			selected_cursor_hotspot = Vector2.ZERO
		Global.GameState.GAMEPLAY:
			selected_world = gameplay_scene
			selected_gui = gameplay_gui
			selected_cursor = crosshair_cursor
			selected_cursor_hotspot = Vector2(15, 15)

	current_world = selected_world.instantiate()
	world_2d.add_child(current_world)
	current_gui = selected_gui.instantiate()
	gui.add_child(current_gui)
	Input.set_custom_mouse_cursor(selected_cursor, Input.CURSOR_ARROW, selected_cursor_hotspot)
	Global.current_state = state
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


func _show_popup(popup: PackedScene):
	if not popups.get_children():
		popups.add_child(popup.instantiate())


func _quit_game() -> void:
	await _transition_in()
	get_tree().quit()
