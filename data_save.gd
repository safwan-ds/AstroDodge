class_name DataSave extends Resource

@export var collectibles_counter: Array[int]


func save() -> int:
	if FileAccess.file_exists(Global.SAVE_FILE_PATH):
		var file := FileAccess.open(Global.SAVE_FILE_PATH, FileAccess.WRITE)
		file.close()

	return ResourceSaver.save(self, Global.SAVE_FILE_PATH)
