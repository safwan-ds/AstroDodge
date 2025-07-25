extends Node

@export var sfx: AudioStreamPlayer
@export var music: AudioStreamPlayer

@export var hover: AudioStreamWAV
@export var click: AudioStreamWAV
@export var lose: AudioStreamWAV
@export var boom: AudioStreamWAV

@export var gameplay_music: AudioStreamOggVorbis

var rng := RandomNumberGenerator.new()

enum SFX {HOVER, CLICK, LOSE, BOOM}
enum Music {MAIN_MENU, GAMEPLAY}


func play_sfx(sfx_type: SFX, volume: float = 1.0) -> void:
	sfx.set_deferred("pitch_scale", rng.randf_range(0.9, 1.1))
	sfx.set_deferred("volume_db", volume)
	match sfx_type:
		SFX.HOVER:
			sfx.stream = hover
		SFX.CLICK:
			sfx.stream = click
		SFX.LOSE:
			sfx.stream = lose
		SFX.BOOM:
			sfx.stream = boom
	sfx.play()


func play_music(music_type: Music) -> void:
	match music_type:
		Music.MAIN_MENU:
			music.stream = gameplay_music
		Music.GAMEPLAY:
			music.stream = gameplay_music
	if not music.playing:
		_fade_in(music)
		music.play()

	
func stop_music() -> void:
	if music.playing:
		_fade_out(music)


func _fade_in(audio_player: AudioStreamPlayer, duration: float = 1.0) -> void:
	audio_player.volume_db = linear_to_db(0.0001)
	create_tween().tween_property(audio_player, "volume_db", 0, duration).set_trans(Tween.TRANS_LINEAR)


func _fade_out(audio_player: AudioStreamPlayer, duration: float = 1.0) -> void:
	var tween := create_tween().tween_property(audio_player, "volume_db", linear_to_db(0.0001), duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	audio_player.stop()
