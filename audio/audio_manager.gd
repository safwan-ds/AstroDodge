extends Node
## Singleton for SFX and music playback. SFX gets randomized pitch.[br]
## Music uses fade-in/fade-out transitions.

enum SFX {HOVER, CLICK, LOSE, BOOM, SHOOT, PICKUP}
enum Music {MAIN_MENU, GAMEPLAY}

@export var sfx: AudioStreamPlayer
@export var music: AudioStreamPlayer

## Hover sound effect.
@export var hover: AudioStreamWAV
## Click sound effect.
@export var click: AudioStreamWAV
## Lose / death sound effect.
@export var lose: AudioStreamWAV
## Explosion sound effect.
@export var boom: AudioStreamWAV
## Shoot sound effect.
@export var shoot: AudioStreamWAV
## Collectible pickup sound effect.
@export var pickup: AudioStreamWAV

## Background music for gameplay / menus.
@export var gameplay_music: AudioStreamOggVorbis

const MUSIC_DUCK_DB := -12.0

var rng := RandomNumberGenerator.new()

## Connected to Global.change_state to handle music across game states.
func _ready() -> void:
	Global.change_state.connect(_on_change_state)
	Global.pause_toggled.connect(_on_pause_toggled)
	music.process_mode = PROCESS_MODE_ALWAYS


func _on_change_state(state: Global.GameState) -> void:
	match state:
		Global.GameState.MAIN_MENU:
			stop_music()
		Global.GameState.GAMEPLAY:
			play_music(Music.GAMEPLAY)


func _on_pause_toggled(is_paused: bool) -> void:
	var target_db := MUSIC_DUCK_DB if is_paused else 0.0
	if music.playing:
		create_tween().tween_property(music, "volume_db", target_db, 0.3).set_trans(Tween.TRANS_QUAD)


## Play a sound effect with randomized pitch and optional [param volume] offset.
func play_sfx(sfx_type: SFX, volume: float = 0.0) -> void:
	sfx.set_deferred("pitch_scale", rng.randf_range(0.8, 1.2))
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
		SFX.SHOOT:
			sfx.stream = shoot
		SFX.PICKUP:
			sfx.stream = pickup
	sfx.play()


## Start looping music with a fade-in (no-op if already playing).
func play_music(music_type: Music) -> void:
	match music_type:
		Music.MAIN_MENU:
			music.stream = gameplay_music
		Music.GAMEPLAY:
			music.stream = gameplay_music
	if not music.playing:
		_fade_in(music)
		music.play()


## Fade out and stop the currently playing music.
func stop_music() -> void:
	if music.playing:
		_fade_out(music)


func _fade_in(audio_player: AudioStreamPlayer, duration: float = 1.0) -> void:
	audio_player.volume_db = linear_to_db(0.0001)
	create_tween().tween_property(audio_player, "volume_db", 0, duration).set_trans(Tween.TRANS_LINEAR)


func _fade_out(audio_player: AudioStreamPlayer, duration: float = 1.0) -> void:
	var tween := create_tween().tween_property(
		audio_player, "volume_db", linear_to_db(0.0001), duration,
	).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	audio_player.stop()
