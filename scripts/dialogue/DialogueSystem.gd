extends CanvasLayer
## نظام حوار + ترجمة نصية
## مزامنة شفاه حقيقية غير متوفرة بدون morph targets
## البديل: نبض فك بسيط مع الصوت

signal dialogue_started(id: String)
signal dialogue_ended(id: String)
signal line_spoken(speaker: String, text: String)

var lines: Array = []
var index := 0
var current_id := ""
var _panel: Panel
var _speaker_l: Label
var _body_l: Label
var _hint_l: Label
var _voice: AudioStreamPlayer
var _jaw_target: Node3D = null
var _jaw_t := 0.0
var _active := false

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	_voice = AudioStreamPlayer.new()
	add_child(_voice)

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -140.0
	_panel.offset_bottom = -12.0
	_panel.offset_left = 40.0
	_panel.offset_right = -40.0
	add_child(_panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16.0
	v.offset_top = 10.0
	v.offset_right = -16.0
	v.offset_bottom = -10.0
	_panel.add_child(v)
	_speaker_l = Label.new()
	_speaker_l.add_theme_color_override("font_color", Color(0.92, 0.78, 0.25))
	_speaker_l.add_theme_font_size_override("font_size", 18)
	v.add_child(_speaker_l)
	_body_l = Label.new()
	_body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_l.add_theme_font_size_override("font_size", 15)
	_body_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_body_l)
	_hint_l = Label.new()
	_hint_l.text = "اضغط E للمتابعة"
	_hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	v.add_child(_hint_l)

func start_dialogue(id: String, dialogue_lines: Array, jaw: Node3D = null) -> void:
	current_id = id
	lines = dialogue_lines
	index = 0
	_jaw_target = jaw
	_active = true
	visible = true
	emit_signal("dialogue_started", id)
	_show_line()

func _show_line() -> void:
	if index >= lines.size():
		end_dialogue()
		return
	var line = lines[index]
	var speaker := str(line.get("speaker", ""))
	var text := str(line.get("text", ""))
	_speaker_l.text = speaker
	_body_l.text = text
	emit_signal("line_spoken", speaker, text)
	var audio_path := str(line.get("audio", ""))
	if audio_path != "" and ResourceLoader.exists(audio_path):
		var stream = load(audio_path)
		if stream:
			_voice.stream = stream
			_voice.play()
	_jaw_t = 0.35

func advance() -> void:
	if not _active:
		return
	if _voice.playing:
		_voice.stop()
	index += 1
	_show_line()

func end_dialogue() -> void:
	_active = false
	visible = false
	_jaw_target = null
	emit_signal("dialogue_ended", current_id)

func is_active() -> bool:
	return _active

func _process(delta: float) -> void:
	if not _active:
		return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		advance()
	if _jaw_target and is_instance_valid(_jaw_target):
		if _voice.playing:
			_jaw_t = 0.2 + absf(sin(Time.get_ticks_msec() * 0.03)) * 0.25
		else:
			_jaw_t = lerpf(_jaw_t, 0.0, delta * 8.0)
		_jaw_target.rotation.x = _jaw_t

static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if typeof(data) == TYPE_DICTIONARY else {}
