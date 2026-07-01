class_name DataSave extends Resource
## Serializable resource for persistent collectible counters.[br]
## Saved and loaded via [ResourceSaver]/[ResourceLoader].
## Uses a dirty flag + one-shot timer (driven by Global) so saves
## happen at most once per second after the last collectible pick-up.

var _dirty := false

## Per-type collectible count array. Indexed by [enum Global.CollectibleType].
@export var collectibles_counter: Array[int]


## Flag data as unsaved and trigger the debounce timer in Global.[br]
## Called from [Collectible] on each pick-up.
func mark_dirty() -> void:
	if not _dirty:
		_dirty = true
		Global._start_data_save_timer()


## Force-write to disk if dirty. Clears dirty flag.[br]
## Returns [enum ResourceSaver.Error] code.
func flush() -> int:
	if not _dirty:
		return OK
	_dirty = false
	return ResourceSaver.save(self, Global.SAVE_FILE_PATH)
