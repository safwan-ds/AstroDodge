extends Node

@export var sfx: AudioStreamPlayer
@export var music: AudioStreamPlayer

@export var hover: AudioStreamWAV
@export var click: AudioStreamWAV

var rng: RandomNumberGenerator

enum Sfx {HOVER, CLICK}


func _ready():
	rng = RandomNumberGenerator.new()


func play_sfx(sfx_type: Sfx):
	sfx.set_deferred("pitch_scale", rng.randf_range(0.9, 1.1))
	match sfx_type:
		Sfx.HOVER:
			sfx.stream = hover
		Sfx.CLICK:
			sfx.stream = click
	sfx.play()