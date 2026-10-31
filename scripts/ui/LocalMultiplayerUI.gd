extends Control
## واجهة اللعب الجماعي المحلي — أسود وذهبي
## الجزء 5

@onready var panel_main: Control = $Panel
@onready var edit_name: LineEdit = $Panel/VBox/EditName
@onready var edit_ip: LineEdit = $Panel/VBox/EditIP
@onready var edit_port: LineEdit = $Panel/VBox/EditPort
@onready var lbl_status: Label = $Panel/VBox/LblStatus
@onready var lbl_players: Label = $Panel/VBox/LblPlayers
@onready var lbl_ip_info: Label = $Panel/VBox/LblIPInfo
@onready var btn_host: Button = $Panel/VBox/HBoxHost/BtnHost
@onready var btn_join: Button = $Panel/VBox/HBoxJoin/BtnJoin
@onready var btn_start: Button = $Panel/VBox/BtnStart
@onready var btn_leave: Button = $Panel/VBox/BtnLeave
@onready var btn_back: Button = $Panel/VBox/BtnBack

var lmp: Node = null

func _ready() -> void:
	visible = false
	btn_host.pressed.connect(_on_host)
	btn_join.pressed.connect(_on_join)
	btn_start.pressed.connect(_on_start)
	btn_leave.pressed.connect(_on_leave)
	btn_back.pressed.connect(_on_back)
	btn_start.disabled = true
	btn_leave.disabled = true
	# مدير الشبكة
	lmp = get_node_or_null("/root/LocalMultiplayerManager")
	if lmp == null:
		var script: GDScript = load("res://scripts/networking/local/LocalMultiplayerManager.gd")
		lmp = script.new()
		lmp.name = "LocalMultiplayerManager"
		get_tree().root.add_child(lmp)
	_connect_signals()
	edit_port.text = "7770"
	edit_name.text = "أبو كردوم"
	lbl_ip_info.text = "IP جهازك: " + lmp.get_local_ip()

func _connect_signals() -> void:
	if lmp == null:
		return
	if not lmp.connection_succeeded.is_connected(_on_ok):
		lmp.connection_succeeded.connect(_on_ok)
	if not lmp.connection_failed.is_connected(_on_fail):
		lmp.connection_failed.connect(_on_fail)
	if not lmp.player_list_changed.is_connected(_on_players):
		lmp.player_list_changed.connect(_on_players)
	if not lmp.lobby_message.is_connected(_on_msg):
		lmp.lobby_message.connect(_on_msg)
	if not lmp.match_started.is_connected(_on_match):
		lmp.match_started.connect(_on_match)

func open_ui() -> void:
	visible = true
	lbl_ip_info.text = "IP جهازك: " + (lmp.get_local_ip() if lmp else "?")
	lbl_status.text = "اختر إنشاء غرفة أو الانضمام"

func _on_host() -> void:
	var port := int(edit_port.text) if edit_port.text.is_valid_int() else 7770
	lmp.host_game(edit_name.text, port)
	btn_start.disabled = false
	btn_leave.disabled = false
	btn_host.disabled = true
	btn_join.disabled = true

func _on_join() -> void:
	var port := int(edit_port.text) if edit_port.text.is_valid_int() else 7770
	lmp.join_game(edit_ip.text, edit_name.text, port)
	btn_leave.disabled = false
	btn_host.disabled = true
	btn_join.disabled = true

func _on_start() -> void:
	if lmp and lmp.is_host:
		lmp.start_match()

func _on_leave() -> void:
	if lmp:
		lmp.leave_game()
	btn_host.disabled = false
	btn_join.disabled = false
	btn_start.disabled = true
	btn_leave.disabled = true
	lbl_players.text = "اللاعبون: —"

func _on_back() -> void:
	if lmp and lmp.is_connected:
		lmp.leave_game()
	visible = false
	btn_host.disabled = false
	btn_join.disabled = false

func _on_ok() -> void:
	lbl_status.text = "متصل ✓"
	lbl_status.modulate = Color(0.4, 0.9, 0.4)

func _on_fail(reason: String) -> void:
	lbl_status.text = reason
	lbl_status.modulate = Color(1.0, 0.4, 0.3)
	btn_host.disabled = false
	btn_join.disabled = false

func _on_msg(text: String) -> void:
	lbl_status.text = text
	lbl_status.modulate = Color(0.92, 0.85, 0.55)

func _on_players(players: Dictionary) -> void:
	var lines := "اللاعبون (%d):\n" % players.size()
	for id in players.keys():
		var n: String = str(players[id].get("name", "?"))
		var tag := " (مضيف)" if int(id) == 1 else ""
		lines += "• %s%s\n" % [n, tag]
	lbl_players.text = lines

func _on_match() -> void:
	visible = false
	# ابدأ العالم بوضع جماعي
	if SaveSystem:
		SaveSystem.current_save = SaveSystem.create_default_save()
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().change_scene_to_file("res://scenes/world/MainWorld.tscn")
