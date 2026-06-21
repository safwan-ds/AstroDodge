extends Node

signal finished()


const LOADING_SCREEN := preload("res://states/loading/loading_screen.tscn")
const SCENES_TO_PRELOAD := [
	"res://entities/asteroid/asteroid.tscn",
	"res://entities/voltstar/voltstar.tscn",
	"res://entities/voltstar/voltshot/voltshot.tscn",
	"res://entities/player/bullet/bullet.tscn",
	"res://collectibles/j_unit/j_unit.tscn",
	"res://statics/overcharge_station/overcharge_station.tscn",
]
const SHADERS_TO_PRELOAD := [
	"res://visuals/shaders/vhs.gdshader",
	"res://visuals/shaders/space_warp.gdshader",
	"res://visuals/shaders/blur.gdshader",
	"res://visuals/shaders/shatter.gdshader",
	"res://visuals/shaders/black_border.gdshader",
]

var _loading := false
var _loading_screen: CanvasLayer
var _status_label: Label
var _progress_bar: ProgressBar
var _warming_root: Node2D


func preload_all() -> void:
	if _loading:
		return
	_loading = true

	_build_loading_screen()

	# Stop all players immediately to prevent audio during loading
	for player in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
	for player in get_tree().root.find_children("*", "AudioStreamPlayer2D", true, false):
		player.stop()

	var total := SHADERS_TO_PRELOAD.size() + SCENES_TO_PRELOAD.size()
	var idx := 0

	# 1. Load shaders (CPU-cache only)
	for path in SHADERS_TO_PRELOAD:
		_update_progress(float(idx) / float(total) * 100.0, "Shader: " + path.get_file())
		if ResourceLoader.exists(path):
			ResourceLoader.load(path)
		idx += 1
		await get_tree().process_frame

	# 2. Set up warming world
	var saved_world := Global.current_world
	_warming_root = Node2D.new()
	_warming_root.name = "_WarmingRoot"
	_warming_root.visible = false
	var warming_camera := Camera2D.new()
	warming_camera.name = "Camera"
	_warming_root.add_child(warming_camera)
	get_tree().root.add_child(_warming_root)
	Global.current_world = _warming_root

	# 3. Warm scenes — instantiate + process frames for GPU particles
	for path in SCENES_TO_PRELOAD:
		_update_progress(float(idx) / float(total) * 100.0, "Warming: " + path.get_file())
		idx += 1

		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = ResourceLoader.load(path)
		if not scene:
			continue

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
	await get_tree().create_timer(0.15).timeout
	_loading_screen.queue_free()
	_loading_screen = null
	_loading = false
	finished.emit()


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


func _build_loading_screen() -> void:
	_loading_screen = LOADING_SCREEN.instantiate()
	add_child(_loading_screen)
	_status_label = _loading_screen.get_node("Center/VBox/Status") as Label
	_progress_bar = _loading_screen.get_node("Center/VBox/Progress") as ProgressBar


func _update_progress(value: float, label: String) -> void:
	if _progress_bar:
		_progress_bar.value = value
	if _status_label:
		_status_label.text = label
