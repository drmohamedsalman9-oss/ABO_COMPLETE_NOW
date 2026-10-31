extends Control
## شاشة بداية سينمائية
## الجزء 12 | أبو كردوم | الملك الأخير

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBox/SubtitleLabel
@onready var en_label: Label = $CenterContainer/VBox/EnglishLabel
@onready var signature_label: Label = $CenterContainer/VBox/SignatureLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBox/ProgressBar
@onready var version_label: Label = $VersionLabel
@onready var skip_btn: Button = $SkipBtn
@onready var crown: Label = $CenterContainer/VBox/Crown

var load_progress: float = 0.0
var is_loading: bool = true
var _skipped: bool = false

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

	if crown:
		crown.text = "👑"
		crown.modulate.a = 0.0
	title_label.text = "أبو كردوم"
	title_label.modulate.a = 0.0
	subtitle_label.text = "الملك الأخير"
	subtitle_label.modulate.a = 0.0
	if en_label:
		en_label.text = "ABO KARDOOM: THE LAST KING"
		en_label.modulate.a = 0.0
	signature_label.text = "محمد ماهر أبو كردوم"
	signature_label.modulate.a = 0.0
	version_label.text = "v1.0.0"
	progress_bar.value = 0
	if skip_btn:
		skip_btn.pressed.connect(_skip)
	# موسيقى قائمة
	if AudioManager:
		AudioManager.play_music("res://assets/audio/music_menu.wav")
	_animate_in()

func _animate_in() -> void:
	var t := create_tween()
	t.set_parallel(true)
	if crown:
		t.tween_property(crown, "modulate:a", 1.0, 0.35)
	t.tween_property(title_label, "modulate:a", 1.0, 0.4).set_delay(0.1)
	t.tween_property(subtitle_label, "modulate:a", 1.0, 0.4).set_delay(0.15)
	if en_label:
		t.tween_property(en_label, "modulate:a", 0.85, 1.0).set_delay(0.25)
	t.tween_property(signature_label, "modulate:a", 0.9, 1.0).set_delay(0.9)
	t.chain().tween_callback(_start_loading)

func _start_loading() -> void:
	if _skipped:
		return
	var tween := create_tween()
	tween.tween_property(self, "load_progress", 100.0, 0.55).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_loading_finished)

func _process(_delta: float) -> void:
	if is_loading:
		progress_bar.value = load_progress

func _skip() -> void:
	_skipped = true
	is_loading = false
	if AudioManager:
		AudioManager.play_ui_click()
	_go_menu()

func _on_loading_finished() -> void:
	if _skipped:
		return
	is_loading = false
	await get_tree().create_timer(0.12).timeout
	_go_menu()

func _go_menu() -> void:
	# شاشة ترحيب بالصورتين قبل القائمة
	get_tree().change_scene_to_file("res://scenes/ui/WelcomeSequence.tscn")
