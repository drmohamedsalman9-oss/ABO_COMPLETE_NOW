extends Control
## القائمة الرئيسية - Main Menu
## أبو كردوم | الملك الأخير
## الجزء 1: واجهة فاخرة بالأسود والذهبي

@onready var title_label: Label = $Background/CenterContainer/VBox/TitleSection/TitleLabel
@onready var subtitle_label: Label = $Background/CenterContainer/VBox/TitleSection/SubtitleLabel
@onready var btn_new_game: Button = $Background/CenterContainer/VBox/Buttons/BtnNewGame
@onready var btn_continue: Button = $Background/CenterContainer/VBox/Buttons/BtnContinue
@onready var btn_multiplayer: Button = $Background/CenterContainer/VBox/Buttons/BtnMultiplayer
@onready var btn_settings: Button = $Background/CenterContainer/VBox/Buttons/BtnSettings
@onready var btn_quit: Button = $Background/CenterContainer/VBox/Buttons/BtnQuit
@onready var signature: Label = $Signature
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

	title_label.text = "أبو كردوم"
	subtitle_label.text = "ABO KARDOOM: THE LAST KING"
	signature.text = "تطوير: محمد ماهر | Mohammed Maher"
	version_label.text = "الإصدار 1.0.0 — الجزء النسخة النهائية "
	
	btn_new_game.text = "لعبة جديدة"
	btn_continue.text = "متابعة"
	btn_multiplayer.text = "لعب جماعي"
	btn_settings.text = "الإعدادات"
	btn_quit.text = "خروج"
	
	# تفعيل/تعطيل زر المتابعة حسب وجود حفظ
	btn_continue.disabled = not SaveSystem.has_save()
	
	# ربط الإشارات
	btn_new_game.pressed.connect(_on_new_game)
	btn_continue.pressed.connect(_on_continue)
	btn_multiplayer.pressed.connect(_on_multiplayer)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)
	# زر عن اللعبة
	var about := Button.new()
	about.text = "عن اللعبة"
	var buttons := get_node_or_null("Background/CenterContainer/VBox/Buttons")
	if buttons:
		buttons.add_child(about)
		buttons.move_child(about, maxi(0, buttons.get_child_count() - 2))
		about.pressed.connect(_on_about)
	
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	if AudioManager:
		AudioManager.play_music("res://assets/audio/music_menu.wav")
		AudioManager.play_ui_confirm()

func _on_new_game() -> void:
	print("[MainMenu] لعبة جديدة — البداية من المنزل")
	if AudioManager:
		AudioManager.play_ui_click()
	GameManager.start_new_game()

func _on_continue() -> void:
	print("[MainMenu] متابعة اللعب")
	GameManager.continue_game()

func _on_multiplayer() -> void:
	# اختيار: محلي أو إنترنت
	_show_mp_choice()

func _show_mp_choice() -> void:
	var d := AcceptDialog.new()
	d.title = "لعب جماعي"
	d.dialog_text = "اختر نوع اللعب الجماعي:

• محلي = Wi-Fi / هوتسبوت
• إنترنت = خادم Online"
	d.ok_button_text = "محلي"
	add_child(d)
	d.confirmed.connect(func():
		d.queue_free()
		_open_local_mp()
	)
	# زر إضافي للإنترنت
	d.add_button("إنترنت", true, "online")
	d.custom_action.connect(func(action):
		if action == "online":
			d.queue_free()
			_open_online_mp()
	)
	d.popup_centered()

func _open_local_mp() -> void:
	var ui := get_node_or_null("LocalMultiplayerUI")
	if ui == null:
		var scene: PackedScene = load("res://scenes/ui/LocalMultiplayerUI.tscn")
		if scene:
			ui = scene.instantiate()
			ui.name = "LocalMultiplayerUI"
			add_child(ui)
	if ui and ui.has_method("open_ui"):
		ui.open_ui()

func _open_online_mp() -> void:
	var ui := get_node_or_null("OnlineMultiplayerUI")
	if ui == null:
		var scene: PackedScene = load("res://scenes/ui/OnlineMultiplayerUI.tscn")
		if scene:
			ui = scene.instantiate()
			ui.name = "OnlineMultiplayerUI"
			add_child(ui)
	if ui and ui.has_method("open_ui"):
		ui.open_ui()


func _on_settings() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	_show_settings_panel()


func _on_about() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	_show_message("أبو كردوم | الملك الأخير\nABO KARDOOM: THE LAST KING\n\nتطوير: محمد ماهر أبو كردوم\nعالم مفتوح · مهمات · شرطة · قتال · اقتصاد")

func _on_quit() -> void:
	GameManager.quit_game()

func _show_message(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "أبو كردوم"
	dialog.dialog_text = text
	dialog.ok_button_text = "حسناً"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _show_settings_panel() -> void:
	var existing := get_node_or_null("SettingsOverlay")
	if existing:
		existing.visible = true
		return
	var layer := CanvasLayer.new()
	layer.name = "SettingsOverlay"
	layer.layer = 50
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -160
	panel.offset_top = -180
	panel.offset_right = 160
	panel.offset_bottom = 180
	layer.add_child(panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_top = 12
	v.offset_right = -12
	v.offset_bottom = -12
	panel.add_child(v)
	var title := Label.new()
	title.text = "الإعدادات"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_add_vol_slider(v, "عام", "master")
	_add_vol_slider(v, "موسيقى", "music")
	_add_vol_slider(v, "مؤثرات", "sfx")
	var mute_btn := CheckButton.new()
	mute_btn.text = "كتم الصوت"
	mute_btn.button_pressed = AudioManager.muted if AudioManager else false
	# جودة
	var qrow := HBoxContainer.new()
	v.add_child(qrow)
	var ql := Label.new()
	ql.text = "جودة الرسومات:"
	qrow.add_child(ql)
	var qbtn := Button.new()
	var qnames := ["منخفض", "متوسط", "عالي"]
	var qcur := 1
	if SettingsManager:
		qcur = int(SettingsManager.get_setting("graphics", "quality", 1))
	qbtn.text = qnames[clampi(qcur, 0, 2)]
	qbtn.pressed.connect(func():
		if SettingsManager:
			var nq := (int(SettingsManager.get_setting("graphics", "quality", 1)) + 1) % 3
			SettingsManager.set_quality(nq)
			qbtn.text = qnames[nq]
			if AudioManager:
				AudioManager.play_ui_click()
	)
	qrow.add_child(qbtn)
	var fps_btn := CheckButton.new()
	fps_btn.text = "عرض FPS"
	fps_btn.button_pressed = bool(SettingsManager.settings.get("show_fps", false)) if SettingsManager else false
	fps_btn.toggled.connect(func(on):
		if SettingsManager:
			SettingsManager.settings["show_fps"] = on
			SettingsManager.save_settings()
			SettingsManager.apply_settings()
	)
	v.add_child(fps_btn)
	mute_btn.toggled.connect(func(on):
		if AudioManager:
			AudioManager.set_muted(on)
	)
	v.add_child(mute_btn)
	var close := Button.new()
	close.text = "إغلاق"
	close.pressed.connect(func():
		if AudioManager:
			AudioManager.play_ui_click()
		layer.queue_free()
	)
	v.add_child(close)
	add_child(layer)

func _add_vol_slider(parent: VBoxContainer, label: String, kind: String) -> void:
	var l := Label.new()
	l.text = label
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	if AudioManager:
		match kind:
			"master":
				s.value = AudioManager.master_volume
			"music":
				s.value = AudioManager.music_volume
			"sfx":
				s.value = AudioManager.sfx_volume
	s.value_changed.connect(func(val):
		if AudioManager == null:
			return
		match kind:
			"master":
				AudioManager.set_master_volume(val)
			"music":
				AudioManager.set_music_volume(val)
			"sfx":
				AudioManager.set_sfx_volume(val)
	)
	parent.add_child(s)
