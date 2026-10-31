extends Node
## نظام الصوت — موسيقى · مؤثرات · إعدادات
## الجزء 12 | أبو كردوم

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9
var muted: bool = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var _current_music: String = ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)
	# من الإعدادات
	if SettingsManager and SettingsManager.settings.has("audio"):
		var a: Dictionary = SettingsManager.settings["audio"]
		master_volume = float(a.get("master_volume", 0.8))
		music_volume = float(a.get("music_volume", 0.7))
		sfx_volume = float(a.get("sfx_volume", 0.9))
		muted = bool(a.get("muted", false))
	_apply_volumes()
	print("[AudioManager] جاهز")

func _apply_volumes() -> void:
	var m := 0.0 if muted else master_volume
	AudioServer.set_bus_volume_db(0, linear_to_db(maxi(0.001, m)))
	if music_player:
		music_player.volume_db = linear_to_db(maxi(0.001, music_volume * (0.0 if muted else 1.0)))
	if sfx_player:
		sfx_player.volume_db = linear_to_db(maxi(0.001, sfx_volume * (0.0 if muted else 1.0)))

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_persist()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_persist()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_persist()

func set_muted(v: bool) -> void:
	muted = v
	_apply_volumes()
	_persist()

func play_music(path: String, force: bool = false) -> void:
	if path == _current_music and music_player.playing and not force:
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = stream
	music_player.play()
	_current_music = path

func stop_music() -> void:
	if music_player:
		music_player.stop()
	_current_music = ""

func play_sfx(path: String) -> void:
	if muted:
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

func play_ui_click() -> void:
	play_sfx("res://assets/audio/ui_click.wav")

func play_ui_confirm() -> void:
	play_sfx("res://assets/audio/ui_confirm.wav")

func _persist() -> void:
	if SettingsManager:
		SettingsManager.settings["audio"] = {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"muted": muted
		}
		SettingsManager.save_settings()
