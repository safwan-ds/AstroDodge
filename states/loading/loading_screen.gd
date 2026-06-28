## Controls the loading screen and GPU-warms scenes before gameplay.
## Configure scenes_to_preload and shaders_to_preload in loading_screen.tscn inspector.
extends CanvasLayer

signal finished()

@export var scenes_to_preload: Array[PackedScene]
@export var shaders_to_preload: Array[Shader]

var _loading := false
var _status_label: Label
var _progress_bar: ProgressBar
var _warming_root: Node2D


func _ready() -> void:
	_status_label = $Center/VBox/Status as Label
	_progress_bar = $Center/VBox/Progress as ProgressBar


func preload_all() -> void:
	if _loading:
		return
	_loading = true

	await get_tree().process_frame
	_stop_audio()

	var total := shaders_to_preload.size() + scenes_to_preload.size()
	var idx := 0

	# 1. Shaders are preloaded at compile time — process frames for GPU compilation
	for shader in shaders_to_preload:
		_update_progress(float(idx) / float(total) * 100.0, "Shader: " + shader.resource_path.get_file())
		idx += 1
		await get_tree().process_frame

	# 2. Set up warming world
	var saved_world := Global.current_world
	_warming_root = Node2D.new()
	_warming_root.name = "_WarmingRoot"
	_warming_root.visible = false
	_warming_root.process_mode = PROCESS_MODE_DISABLED
	var warming_camera := Camera2D.new()
	warming_camera.name = "Camera"
	_warming_root.add_child(warming_camera)
	get_tree().root.add_child(_warming_root)
	Global.current_world = _warming_root

	# 3. Warm scenes — instantiate + process frames for GPU particles
	for scene in scenes_to_preload:
		_update_progress(float(idx) / float(total) * 100.0, "Warming: " + scene.resource_path.get_file())
		idx += 1

		var instance := scene.instantiate()
		_warming_root.add_child(instance)
		_warm_particles(instance)
		await get_tree().process_frame
		await get_tree().process_frame

	# 4. Clean up warming world
	get_tree().root.remove_child(_warming_root)
	_warming_root.queue_free()
	_warming_root = null
	Global.current_world = saved_world

	# 5. Extra GPU catch-up frames
	_update_progress(100.0, "Compiling...")
	for _i in range(5):
		await get_tree().process_frame

	_update_progress(100.0, "Ready!")
	# Unmute audio buses — the 0.15s delay absorbs any unmute pop/click
	for i in AudioServer.get_bus_count():
		AudioServer.set_bus_mute(i, false)
	await get_tree().create_timer(0.15).timeout
	hide()
	_loading = false
	finished.emit()


func _stop_audio() -> void:
	for player in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
	for player in get_tree().root.find_children("*", "AudioStreamPlayer2D", true, false):
		player.stop()
	for i in AudioServer.get_bus_count():
		AudioServer.set_bus_mute(i, true)


func _warm_particles(node: Node) -> void:
	for child in node.find_children("*", "GPUParticles2D", true, false):
		var particles := child as GPUParticles2D
		if particles and not particles.emitting:
			particles.restart()
			particles.emitting = true
	var self_particles := node as GPUParticles2D
	if self_particles and not self_particles.emitting:
		self_particles.restart()
		self_particles.emitting = true


func _update_progress(value: float, label: String) -> void:
	if _progress_bar:
		_progress_bar.value = value
	if _status_label:
		_status_label.text = label
