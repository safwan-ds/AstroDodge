class_name LoadingScreen extends CanvasLayer
## Holds [member scenes_to_preload] and [member shaders_to_preload] configured in-editor.[br]
## Consumed by [LoadingScreen] autoload during [method LoadingScreen.preload_all].

@export_group("Links to Nodes")
@export var status_label: Label
@export var progress_bar: ProgressBar
@export_group("Preload Config")
@export var scenes_to_preload: Array[PackedScene]
@export var shaders_to_preload: Array[Shader]
