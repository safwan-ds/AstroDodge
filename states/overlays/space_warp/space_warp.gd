extends ColorRect
## Full-screen shader overlay that creates distortion ripples on explosions.[br]
## Supports multiple overlapping warps — each explosion adds an entry that
## decays independently. The shader composites all active warps per frame.

const MAX_WARPS := 8
## Rise time in seconds (intensity 0 → 1).
const RISE_TIME := 0.15
## Fall time in seconds (intensity 1 → 0).
const FALL_TIME := 1.5


@onready var _material: ShaderMaterial = material as ShaderMaterial

## Active explosions, each: {pos, scale, age}.
var _active_warps: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	Global.explosion_occurred.connect(_on_explosion_occurred)


func _on_explosion_occurred(world_position: Vector2, world_scale: float) -> void:
	if not is_inside_tree():
		return

	_active_warps.append({
		pos = world_position,
		scale = world_scale,
		age = 0.0,
	})

	if _active_warps.size() > MAX_WARPS:
		_active_warps.pop_front()


func _process(delta: float) -> void:
	if _active_warps.is_empty():
		return

	var camera := get_viewport().get_camera_2d()
	if not camera:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Age all active warps, remove dead ones.
	var i := 0
	while i < _active_warps.size():
		var entry: Dictionary = _active_warps[i]
		entry.age += delta
		if entry.age > RISE_TIME + FALL_TIME:
			_active_warps.remove_at(i)
		else:
			i += 1

	if _active_warps.is_empty():
		return

	# Pack into shader arrays (always 8 elements, warp_count = how many to use).
	var count := mini(_active_warps.size(), MAX_WARPS)
	var origins := PackedVector2Array()
	var intensities := PackedFloat32Array()
	var radii := PackedFloat32Array()
	origins.resize(MAX_WARPS)
	intensities.resize(MAX_WARPS)
	radii.resize(MAX_WARPS)

	for j in MAX_WARPS:
		if j < count:
			var entry: Dictionary = _active_warps[j]
			var screen_pos: Vector2 = camera.get_canvas_transform() * entry.pos
			origins[j] = screen_pos / viewport_size

			# Intensity curve: quick rise, slow decay.
			if entry.age < RISE_TIME:
				intensities[j] = entry.age / RISE_TIME
			else:
				intensities[j] = maxf(0.0, 1.0 - (entry.age - RISE_TIME) / FALL_TIME)

			radii[j] = clampf(0.08 * entry.scale, 0.02, 0.6)
		else:
			origins[j] = Vector2.ZERO
			intensities[j] = 0.0
			radii[j] = 0.0

	_material.set_shader_parameter("warp_origins", origins)
	_material.set_shader_parameter("warp_intensities", intensities)
	_material.set_shader_parameter("warp_radii", radii)
	_material.set_shader_parameter("warp_count", count)
