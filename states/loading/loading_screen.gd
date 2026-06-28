extends Node
## Manages the loading screen UI and GPU-warms scenes before gameplay.
## Autoload singleton — call [method preload_all] on game start.

signal finished()

const LOADING_SCENE := preload("res://states/loading/loading_screen.tscn")

var _loading := false
var _loading_scene: CanvasLayer
var _status_label: Label
var _progress_bar: ProgressBar
var _warming_root: Node2D


## Preload all scenes and shaders: display loading UI, mute audio,
## warm GPU particles, unmute, then free the loading scene.
## Idempotent — guarded by [member _loading].
func preload_all() -> void:
	if _loading:
		return
	_loading = true

	_loading_scene = LOADING_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(_loading_scene)
	await get_tree().process_frame
	_status_label = _loading_scene.get_node("Center/VBox/Status") as Label
	_progress_bar = _loading_scene.get_node("Center/VBox/Progress") as ProgressBar

	await get_tree().process_frame
	_stop_audio()

	var scenes_to_preload: Array[PackedScene] = _loading_scene.scenes_to_preload
	var shaders_to_preload: Array[Shader] = _loading_scene.shaders_to_preload
	var total := shaders_to_preload.size() + scenes_to_preload.size()
	var idx := 0

	for shader in shaders_to_preload:
		_update_progress(float(idx) / float(total) * 100.0, "Shader: " + shader.resource_path.get_file())
		idx += 1
		await get_tree().process_frame

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

	for scene in scenes_to_preload:
		_update_progress(float(idx) / float(total) * 100.0, "Warming: " + scene.resource_path.get_file())
		idx += 1

		var instance: Node2D = scene.instantiate()
		_warming_root.add_child(instance)
		_warm_particles(instance)
		await get_tree().process_frame
		await get_tree().process_frame

	get_tree().root.remove_child(_warming_root)
	_warming_root.queue_free()
	_warming_root = null
	Global.current_world = saved_world

	_update_progress(100.0, "Compiling...")
	for _i in range(5):
		await get_tree().process_frame

	_update_progress(100.0, "Ready!")

	for i in AudioServer.get_bus_count():
		AudioServer.set_bus_mute(i, false)

	await get_tree().create_timer(0.15).timeout

	_loading_scene.queue_free()
	_loading_scene = null
	_status_label = null
	_progress_bar = null
	_loading = false
	finished.emit()


## Stop all [AudioStreamPlayer]s and mute all audio buses to prevent noise during loading.
func _stop_audio() -> void:
	for player in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
	for player in get_tree().root.find_children("*", "AudioStreamPlayer2D", true, false):
		player.stop()
	for i in AudioServer.get_bus_count():
		AudioServer.set_bus_mute(i, true)


## Instantiate and tick each GPUParticles2D in [param node] to compile GPU pipelines.
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
