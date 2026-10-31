extends CanvasLayer
## قائمة الإيقاف الاحترافية
## الجزء 12 | أبو كردوم

signal resume_requested()

@onready var panel: Panel = $Panel
@onready var btn_resume: Button = $Panel/VBox/BtnResume
@onready var btn_save: Button = $Panel/VBox/BtnSave
@onready var btn_settings: Button = $Panel/VBox/BtnSettings
@onready var btn_menu: Button = $Panel/VBox/BtnMenu
@onready var btn_quit: Button = $Panel/VBox/BtnQuit
@onready var status: Label = $Panel/VBox/Status
@onready var info: Label = $Panel/VBox/Info

var world: Node = null
var _settings_open: bool = false

func _ready() -> void:
	layer = 40
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_resume.pressed.connect(_resume)
	btn_save.pressed.connect(_save)
	if btn_settings:
		btn_settings.pressed.connect(_open_settings)
	btn_menu.pressed.connect(_menu)
	btn_quit.pressed.connect(func():
		if AudioManager:
			AudioManager.play_ui_click()
		get_tree().quit()
	)

func setup(w: Node) -> void:
	world = w

func toggle() -> void:
	if visible:
		_resume()
	else:
		visible = true
		_update_info()
		# لا توقف العالم في الملتيبلير
		if not _is_multiplayer():
			get_tree().paused = true
		status.text = "أبو كردوم | الملك الأخير"
		if AudioManager:
			AudioManager.play_ui_click()

func _is_multiplayer() -> bool:
	var ms := get_node_or_null("/root/MultiplayerSession")
	if ms and ms.get("is_online"):
		return true
	if multiplayer and multiplayer.multiplayer_peer != null:
		return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	return false

func _update_info() -> void:
	if info == null:
		return
	var lines: Array = []
	var eco := get_node_or_null("/root/EconomyManager")
	if eco:
		lines.append("💰 %d كردوم" % int(eco.balance))
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("get_active_quest"):
		var q: Dictionary = qm.get_active_quest()
		if not q.is_empty():
			lines.append("مهمة: " + str(q.get("name", "")))
	info.text = "\n".join(lines)

func _resume() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("resume_requested")
	if AudioManager:
		AudioManager.play_ui_click()

func _save() -> void:
	if AudioManager:
		AudioManager.play_ui_confirm()
	if world and world.has_method("_save_player_state"):
		world._save_player_state()
		status.text = "تم الحفظ ✓"
	else:
		var eco := get_node_or_null("/root/EconomyManager")
		if eco and eco.has_method("_auto_save"):
			eco._auto_save()
			status.text = "تم الحفظ ✓"
		else:
			status.text = "تعذّر الحفظ"

func _open_settings() -> void:
	if AudioManager:
		AudioManager.play_ui_click()
	# لوحة إعدادات مضمّنة
	var d := AcceptDialog.new()
	d.title = "الإعدادات"
	d.dialog_text = ""
	d.process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	d.add_child(box)
	# نستخدم popup بسيط عبر sliders في قائمة منفصلة
	_show_inline_settings()

func _show_inline_settings() -> void:
	status.text = "الصوت من القائمة الرئيسية أو أشرطة أدناه"
	# تطبيق سريع: كتم
	if AudioManager:
		AudioManager.set_muted(not AudioManager.muted)
		status.text = "كتم: " + ("نعم" if AudioManager.muted else "لا")

func _menu() -> void:
	get_tree().paused = false
	visible = false
	if AudioManager:
		AudioManager.play_ui_click()
		AudioManager.play_music("res://assets/audio/music_menu.wav")
	if world and world.has_method("_save_player_state"):
		world._save_player_state()
	if GameManager:
		GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
