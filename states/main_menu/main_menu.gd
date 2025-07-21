extends Control

@export var quit_popup_scene: PackedScene

@export var continue_button: Button # TODO: make it visible when there is a saved game
@export var animation_player: AnimationPlayer

var _quit_popup: QuitPopup


func _ready():
	# Initialize the random number generator
	# It's good practice to call randomize() once at the start of your game
	# (e.g., in your main scene's _ready() or a global autoload script)
	# If you call it multiple times, it won't hurt, but once is sufficient for the app lifecycle.
	randomize()

	# Get the length of the animation
	var anim_length = animation_player.get_animation("logo_loop").length

	# Generate a random time within the animation's duration
	# randf() returns a random float between 0.0 and 1.0
	var random_start_time = randf() * anim_length

	# Play the animation
	animation_player.play("logo_loop")

	# Seek to the random time
	animation_player.seek(random_start_time, true)


func _input(event):
	if event.is_action_pressed("back"):
		_quit_popup_show()


func _on_quit_button_pressed() -> void:
	_quit_popup_show()


func _on_new_game_button_pressed() -> void:
	Global.change_state(Global.GameState.GAMEPLAY)


func _quit_popup_show() -> void:
	if not _quit_popup:
		# Instantiate the quit popup scene if it hasn't been created yet
		_quit_popup = quit_popup_scene.instantiate()
		get_parent().get_parent().get_node("Popups").add_child(_quit_popup)
	else:
		# If it already exists, just show it
		_quit_popup.close()
