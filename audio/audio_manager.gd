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
## Main menu music.
@export var main_menu_music: AudioStream
## Gameplay music.
@export var gameplay_music: AudioStream

const MUSIC_DUCK_DB := -12.0

var rng := RandomNumberGenerator.new()
var _music_tween: Tween

## Disconnect any running music tween. Call before starting a new fade to
## prevent competing tweens on [member music.volume_db].
func _kill_music_tween() -> void:
	if _music_tween:
		_music_tween.kill()


func _ready() -> void:
	Global.change_state.connect(_on_change_state)
	Global.pause_toggled.connect(_on_pause_toggled)
	music.process_mode = PROCESS_MODE_ALWAYS


func _on_change_state(state: Global.GameState) -> void:
	match state:
		Global.GameState.MAIN_MENU:
			play_music(Music.MAIN_MENU)
		Global.GameState.GAMEPLAY:
			play_music(Music.GAMEPLAY)


## Duck or restore music volume on pause. Kills any running fade first to
## avoid competing with [method _fade_in] or [method _fade_out].
func _on_pause_toggled(is_paused: bool) -> void:
	var target_db := MUSIC_DUCK_DB if is_paused else 0.0
	if not music.playing:
		return
	_kill_music_tween()
	var tween := create_tween()
	_music_tween = tween
	tween.tween_property(music, "volume_db", target_db, 0.3).set_trans(Tween.TRANS_QUAD)


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


## Stop current track and start [param music_type] with a 2-second fade-in.
## Any in-progress fade (from [method stop_music] or [method _on_pause_toggled])
## is killed first to prevent tween fights.
func play_music(music_type: Music, volume: float = 0.0) -> void:
	_kill_music_tween()

	music.stop()
	match music_type:
		Music.MAIN_MENU:
			music.stream = main_menu_music
		Music.GAMEPLAY:
			music.stream = gameplay_music
	_fade_in(music, 1.0, volume)
	music.play()


## Fade out current music over 3 seconds, then stop it.
func stop_music() -> void:
	if music.playing:
		_fade_out(music, 3.0)


## Fade [param audio_player] from silence to [param target_db] over [param duration].
func _fade_in(audio_player: AudioStreamPlayer, duration: float = 1.0, target_db: float = 0.0) -> void:
	_kill_music_tween()
	audio_player.volume_db = linear_to_db(0.0001)
	_music_tween = create_tween()
	_music_tween.tween_property(audio_player, "volume_db", target_db, duration).set_trans(Tween.TRANS_LINEAR)


## Fade [param audio_player] to silence over [param duration], then stop it.
func _fade_out(audio_player: AudioStreamPlayer, duration: float = 1.0) -> void:
	_kill_music_tween()
	var tween := create_tween()
	_music_tween = tween
	tween.tween_property(audio_player, "volume_db", linear_to_db(0.0001), duration).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(func():
		audio_player.stop()
	)
