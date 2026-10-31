extends Node
## مراقبة أداء اختيارية + تطبيق حدود
## الجزء 13 — للتطوير فقط عند تفعيل show_fps / debug

var show_overlay: bool = false
var _label: Label = null
var _frame_t: float = 0.0
var _frames: int = 0
var _fps: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# تطبيق الجودة مبكراً
	if SettingsManager and SettingsManager.has_method("apply_settings"):
		SettingsManager.apply_settings()
	if SettingsManager:

		show_overlay = bool(SettingsManager.settings.get("show_fps", false))
		SettingsManager.settings_changed.connect(_on_settings)
	set_process(true)

func _on_settings() -> void:
	if SettingsManager:
		show_overlay = bool(SettingsManager.settings.get("show_fps", false))
		if _label:
			_label.visible = show_overlay

func _process(delta: float) -> void:
	_frames += 1
	_frame_t += delta
	if _frame_t >= 0.5:
		_fps = _frames / _frame_t
		_frames = 0
		_frame_t = 0.0
		if show_overlay:
			_ensure_label()
			if _label:
				_label.text = "FPS %.0f | ذاكرة تقريبية" % _fps
	elif not show_overlay and _label:
		_label.visible = false

func _ensure_label() -> void:
	if _label:
		_label.visible = true
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(8, 8)
	_label.modulate = Color(0.5, 1, 0.5)
	layer.add_child(_label)
