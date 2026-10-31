extends Control
## شاشة ترحيب: صورة اللعبة ثم بعد 10 ثوانٍ صورة المطوّر

signal finished

const IMG1 := "res://assets/ui/welcome/welcome_01_game.jpg"
const IMG2 := "res://assets/ui/welcome/welcome_02_developer.jpg"
const HOLD_SEC := 10.0

var _tex: TextureRect
var _hint: Label
var _phase: int = 0
var _timer: float = 0.0
var _done: bool = false

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_tex = TextureRect.new()
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_tex)
	_hint = Label.new()
	_hint.text = "اضغط للمتابعة"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -40
	_hint.add_theme_color_override("font_color", Color(0.92, 0.78, 0.25, 0.85))
	add_child(_hint)
	_show_phase(0)
	set_process(true)

func _show_phase(p: int) -> void:
	_phase = p
	_timer = 0.0
	var path := IMG1 if p == 0 else IMG2
	if ResourceLoader.exists(path):
		_tex.texture = load(path)
	_tex.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_tex, "modulate:a", 1.0, 0.45)
	if p == 0:
		_hint.text = "أبو كردوم | الملك الأخير — اضغط أو انتظر"
	else:
		_hint.text = "تطوير: محمد ماهر أبو كردوم — اضغط للمتابعة"

func _process(delta: float) -> void:
	if _done:
		return
	_timer += delta
	if _phase == 0 and _timer >= HOLD_SEC:
		_go_phase2()
	elif _phase == 1 and _timer >= HOLD_SEC:
		_finish()

func _go_phase2() -> void:
	if _phase != 0:
		return
	var tw := create_tween()
	tw.tween_property(_tex, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		_show_phase(1)
	)

func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	var tw := create_tween()
	tw.tween_property(_tex, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		emit_signal("finished")
		if GameManager:
			GameManager.go_to_main_menu()
		else:
			get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	)

func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed:
		_on_skip()
	elif event is InputEventScreenTouch and event.pressed:
		_on_skip()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_skip()

func _on_skip() -> void:
	if _phase == 0:
		_go_phase2()
	else:
		_finish()
