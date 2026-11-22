extends Node

# Kaiser Shuttle - Centralized Audio & Playlist Manager
signal track_changed(track_idx: int, track_info: Dictionary)
signal playback_state_changed(is_playing: bool)
signal volume_settings_changed(master_val: float, music_val: float, sfx_val: float)

const PLAYLIST: Array[Dictionary] = [
	{
		"id": "tokyo2020",
		"title": "Tokyo 2020: Badminton",
		"artist": "Sonic Olympic Games OST",
		"path": "res://assets/audio/bgm_tokyo2020.ogg"
	},
	{
		"id": "soundtrack02",
		"title": "Soundtrack 02",
		"artist": "Badminton Arena",
		"path": "res://assets/audio/bgm_soundtrack02.ogg"
	},
	{
		"id": "soundtrack03",
		"title": "Soundtrack 03",
		"artist": "Victory Drive",
		"path": "res://assets/audio/bgm_soundtrack03.ogg"
	},
	{
		"id": "lobby",
		"title": "Kaiser Anthem",
		"artist": "Sảnh Chờ BWF",
		"path": "res://assets/audio/lobby_theme.ogg"
	}
]

var current_track_idx: int = 0  # Mặc định là bài Tokyo 2020
var is_playing: bool = true

# 5 mức âm lượng (0, 1, 2, 3, 4, 5)
# 0 = 0% (Tắt tiếng), 1 = 20%, 2 = 40%, 3 = 60%, 4 = 80%, 5 = 100%
var master_step: int = 5
var music_step: int = 4
var sfx_step: int = 5

var bgm_match_enabled: bool = true   # Tùy chọn Tắt nhạc nền trong trận
var squeak_enabled: bool = true       # Tiếng rít giày sàn đấu

var bgm_player: AudioStreamPlayer = null
var stream_cache: Dictionary = {}
var is_in_match: bool = false
var _audio_unlocked: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_load_settings()
	_setup_bgm_player()
	apply_all_volumes()
	
	# Bắt đầu phát bài mặc định Tokyo 2020 ngay khi tải xong game
	play_track(current_track_idx, true)

func _setup_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func _setup_bgm_player() -> void:
	if not bgm_player:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "KaiserBGMPlayer"
		bgm_player.bus = &"Music"
		bgm_player.finished.connect(_on_track_finished)
		add_child(bgm_player)

func _get_stream(path: String) -> AudioStream:
	if stream_cache.has(path):
		return stream_cache[path]
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStreamOggVorbis:
			(res as AudioStreamOggVorbis).loop = true
		stream_cache[path] = res
		return res
	return null

func play_track(idx: int, restart: bool = false) -> void:
	if PLAYLIST.is_empty():
		return
	current_track_idx = posmod(idx, PLAYLIST.size())
	var track = PLAYLIST[current_track_idx]
	var stream = _get_stream(track["path"])
	if not stream or not bgm_player:
		return
		
	if bgm_player.stream != stream or restart:
		bgm_player.stream = stream
		if is_playing and (not is_in_match or bgm_match_enabled):
			bgm_player.play(0.0)
	elif is_playing and not bgm_player.playing and (not is_in_match or bgm_match_enabled):
		bgm_player.play()
		
	track_changed.emit(current_track_idx, track)
	playback_state_changed.emit(is_playing and bgm_player.playing)

func next_track() -> void:
	play_track(current_track_idx + 1, true)

func prev_track() -> void:
	play_track(current_track_idx - 1, true)

func toggle_play_pause() -> void:
	if not bgm_player:
		return
	is_playing = not is_playing
	if is_playing:
		if not bgm_player.playing and (not is_in_match or bgm_match_enabled):
			bgm_player.play()
	else:
		bgm_player.stop()
	playback_state_changed.emit(is_playing and bgm_player.playing)

func _on_track_finished() -> void:
	# Tự động lặp lại bài hiện tại hoặc chuyển bài nếu không loop
	if is_playing and (not is_in_match or bgm_match_enabled):
		bgm_player.play(0.0)

# ==========================================================
# WEB / AUTOPLAY GESTURE UNLOCK
# ==========================================================
func ensure_music_playing() -> void:
	_audio_unlocked = true
	if is_playing and bgm_player and not bgm_player.playing and (not is_in_match or bgm_match_enabled):
		bgm_player.play()
		playback_state_changed.emit(true)

# ==========================================================
# MATCH TRANSITIONS (Tùy chọn Tắt nhạc nền trong trận)
# ==========================================================
func on_enter_match() -> void:
	is_in_match = true
	if not bgm_match_enabled:
		if bgm_player and bgm_player.playing:
			bgm_player.stop()
	else:
		if is_playing and bgm_player and not bgm_player.playing:
			bgm_player.play()

func on_leave_match() -> void:
	is_in_match = false
	if is_playing and bgm_player and not bgm_player.playing:
		bgm_player.play()
	playback_state_changed.emit(is_playing and bgm_player.playing)

# ==========================================================
# 5-STEP VOLUME CALCULATIONS & PERSISTENCE
# ==========================================================
func step_to_linear(step: int) -> float:
	step = clampi(step, 0, 5)
	return float(step) / 5.0

func step_to_db(step: int) -> float:
	if step <= 0:
		return -80.0
	var lin = step_to_linear(step)
	return linear_to_db(lin)

func set_master_step(step: int) -> void:
	master_step = clampi(step, 0, 5)
	_apply_bus_volume("Master", master_step)
	_save_settings()
	volume_settings_changed.emit(step_to_linear(master_step), step_to_linear(music_step), step_to_linear(sfx_step))

func set_music_step(step: int) -> void:
	music_step = clampi(step, 0, 5)
	_apply_bus_volume("Music", music_step)
	_save_settings()
	volume_settings_changed.emit(step_to_linear(master_step), step_to_linear(music_step), step_to_linear(sfx_step))

func set_sfx_step(step: int) -> void:
	sfx_step = clampi(step, 0, 5)
	_apply_bus_volume("SFX", sfx_step)
	_save_settings()
	volume_settings_changed.emit(step_to_linear(master_step), step_to_linear(music_step), step_to_linear(sfx_step))

func set_bgm_match_enabled(en: bool) -> void:
	bgm_match_enabled = en
	if is_in_match:
		if not bgm_match_enabled and bgm_player and bgm_player.playing:
			bgm_player.stop()
		elif bgm_match_enabled and is_playing and bgm_player and not bgm_player.playing:
			bgm_player.play()
	_save_settings()

func set_squeak_enabled(en: bool) -> void:
	squeak_enabled = en
	_save_settings()

func _apply_bus_volume(bus_name: String, step: int) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if step <= 0:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, step_to_db(step))

func apply_all_volumes() -> void:
	_apply_bus_volume("Master", master_step)
	_apply_bus_volume("Music", music_step)
	_apply_bus_volume("SFX", sfx_step)

func _save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master_step", master_step)
	cfg.set_value("audio", "music_step", music_step)
	cfg.set_value("audio", "sfx_step", sfx_step)
	cfg.set_value("audio", "bgm_match_enabled", bgm_match_enabled)
	cfg.set_value("audio", "squeak_enabled", squeak_enabled)
	cfg.set_value("audio", "current_track_idx", current_track_idx)
	cfg.save("user://audio_settings.cfg")

func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://audio_settings.cfg") == OK:
		master_step = cfg.get_value("audio", "master_step", 5)
		music_step = cfg.get_value("audio", "music_step", 4)
		sfx_step = cfg.get_value("audio", "sfx_step", 5)
		bgm_match_enabled = cfg.get_value("audio", "bgm_match_enabled", true)
		squeak_enabled = cfg.get_value("audio", "squeak_enabled", true)
		current_track_idx = cfg.get_value("audio", "current_track_idx", 0)
