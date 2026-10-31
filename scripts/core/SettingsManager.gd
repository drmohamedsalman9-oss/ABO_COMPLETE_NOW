extends Node
## إعدادات الرسومات والصوت والتحكم — تأثير فعلي على الأداء
## الجزء 13 | أبو كردوم

signal settings_changed
signal quality_changed(level: int)

const SETTINGS_PATH := "user://settings.json"

var settings: Dictionary = {}

func _ready() -> void:
	load_settings()
	apply_settings()
	print("[SettingsManager] جاهز — جودة=", get_setting("graphics", "quality", 1))

func get_default_settings() -> Dictionary:
	return {
		"graphics": {
			"quality": 1,  # 0 منخفض · 1 متوسط · 2 عالي
			"shadows": true,
			"anti_aliasing": true,
			"vsync": true,
			"max_fps": 60,
			"render_scale": 1.0
		},
		"audio": {
			"master_volume": 0.8,
			"music_volume": 0.7,
			"sfx_volume": 0.9,
			"muted": false
		},
		"controls": {
			"sensitivity": 1.0,
			"invert_y": false,
			"show_touch_controls": true
		},
		"language": "ar",
		"show_fps": false,
		"debug": false
	}

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		settings = get_default_settings()
		save_settings()
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		settings = get_default_settings()
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
		settings = json.data
		_merge_defaults(settings, get_default_settings())
	else:
		settings = get_default_settings()
	file.close()

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

func apply_settings() -> void:
	var g: Dictionary = settings.get("graphics", {})
	# VSync
	if g.get("vsync", true):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# FPS
	var max_fps: int = int(g.get("max_fps", 60))
	Engine.max_fps = maxi(30, max_fps)
	# جودة
	var quality: int = clampi(int(g.get("quality", 1)), 0, 2)
	_apply_quality(quality)
	# صوت
	if AudioManager:
		var a: Dictionary = settings.get("audio", {})
		AudioManager.master_volume = float(a.get("master_volume", 0.8))
		AudioManager.music_volume = float(a.get("music_volume", 0.7))
		AudioManager.sfx_volume = float(a.get("sfx_volume", 0.9))
		AudioManager.muted = bool(a.get("muted", false))
		if AudioManager.has_method("_apply_volumes"):
			AudioManager._apply_volumes()
	emit_signal("settings_changed")
	emit_signal("quality_changed", quality)

func _apply_quality(level: int) -> void:
	var tree := get_tree()
	var shadows: bool = level >= 1 and bool(settings.get("graphics", {}).get("shadows", true))
	# كثافة AI
	if tree:
		var ai := tree.root.find_child("CityAIManager", true, false)
		if ai and ai.has_method("set_density"):
			ai.set_density(level)
		# طقس/جسيمات
		var weather := tree.root.find_child("WeatherSystem", true, false)
		if weather and "enabled" in weather:
			weather.enabled = level >= 1
		# إضاءة شارع
		var decor := tree.root.find_child("StreetDecor", true, false)
		if decor and decor.has_method("set_lights_enabled"):
			decor.set_lights_enabled(level >= 1)
	var scale: float = 1.0
	match level:
		0:
			scale = 0.7
			Engine.max_fps = mini(int(settings.get("graphics", {}).get("max_fps", 60)), 30)
			# ظلال منخفضة
			RenderingServer.directional_shadow_atlas_set_size(512, true)
		1:
			scale = 0.85
			Engine.max_fps = int(settings.get("graphics", {}).get("max_fps", 60))
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		2:
			scale = 1.0
			Engine.max_fps = int(settings.get("graphics", {}).get("max_fps", 60))
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
	if not shadows:
		RenderingServer.directional_shadow_atlas_set_size(256, true)
	settings["graphics"]["render_scale"] = scale
	if tree and tree.root:
		var vp := tree.root.get_viewport()
		if vp:
			vp.scaling_3d_scale = scale
			# MSAA
			if level == 0:
				vp.msaa_3d = Viewport.MSAA_DISABLED
			elif level == 1:
				vp.msaa_3d = Viewport.MSAA_2X
			else:
				vp.msaa_3d = Viewport.MSAA_2X

func set_quality(level: int) -> void:
	set_setting("graphics", "quality", clampi(level, 0, 2))

func set_setting(category: String, key: String, value) -> void:
	if not settings.has(category):
		settings[category] = {}
	settings[category][key] = value
	save_settings()
	apply_settings()

func get_setting(category: String, key: String, default = null):
	if category == "" or category == null:
		return settings.get(key, default)
	if settings.has(category) and typeof(settings[category]) == TYPE_DICTIONARY and settings[category].has(key):
		return settings[category][key]
	return default

func _merge_defaults(target: Dictionary, defaults: Dictionary) -> void:
	for k in defaults:
		if not target.has(k):
			target[k] = defaults[k]
		elif typeof(defaults[k]) == TYPE_DICTIONARY and typeof(target.get(k)) == TYPE_DICTIONARY:
			_merge_defaults(target[k], defaults[k])
