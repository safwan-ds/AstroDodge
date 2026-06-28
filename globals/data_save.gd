class_name DataSave extends Resource
## Serializable resource for persistent collectible counters.[br]
## Saved and loaded via [ResourceSaver]/[ResourceLoader].

## Per-type collectible count array. Indexed by [enum Global.CollectibleType].
@export var collectibles_counter: Array[int]


## Persist this resource to disk at [member Global.SAVE_FILE_PATH].[br]
## Returns [enum ResourceSaver.Error] code.
func save() -> int:
	if FileAccess.file_exists(Global.SAVE_FILE_PATH):
		var file := FileAccess.open(Global.SAVE_FILE_PATH, FileAccess.WRITE)
		file.close()

	return ResourceSaver.save(self, Global.SAVE_FILE_PATH)
