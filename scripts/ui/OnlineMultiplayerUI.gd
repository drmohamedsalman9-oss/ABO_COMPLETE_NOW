extends Control
## واجهة اللعب عبر الإنترنت
## الجزء 6

@onready var edit_name: LineEdit = $Panel/VBox/EditName
@onready var edit_host: LineEdit = $Panel/VBox/EditHost
@onready var edit_port: LineEdit = $Panel/VBox/EditPort
@onready var edit_code: LineEdit = $Panel/VBox/EditCode
@onready var lbl_status: Label = $Panel/VBox/LblStatus
@onready var lbl_room: Label = $Panel/VBox/LblRoom
@onready var btn_connect: Button = $Panel/VBox/BtnConnect
@onready var btn_create: Button = $Panel/VBox/BtnCreate
@onready var btn_join: Button = $Panel/VBox/BtnJoin
@onready var btn_start: Button = $Panel/VBox/BtnStart
@onready var btn_leave: Button = $Panel/VBox/BtnLeave
@onready var btn_back: Button = $Panel/VBox/BtnBack

var session: Node = null

func _ready() -> void:
	visible = false
	session = get_node_or_null("/root/MultiplayerSession")
	btn_connect.pressed.connect(_on_connect)
	btn_create.pressed.connect(_on_create)
	btn_join.pressed.connect(_on_join)
	btn_start.pressed.connect(_on_start)
	btn_leave.pressed.connect(_on_leave)
	btn_back.pressed.connect(_on_back)
	btn_create.disabled = true
	btn_join.disabled = true
	btn_start.disabled = true
	if session:
		session.status_changed.connect(func(t): lbl_status.text = t)
		session.connected_ok.connect(_on_ok)
		session.connection_failed.connect(_on_fail)
		session.room_updated.connect(_on_room)
		session.room_result.connect(_on_room_res)
		session.match_started.connect(_on_match)
		edit_host.text = str(session.server_host)
		edit_port.text = str(session.server_port)

func open_ui() -> void:
	visible = true
	lbl_status.text = "أدخل عنوان الخادم ثم اتصل"

func _on_connect() -> void:
	if session == null:
		return
	var port := int(edit_port.text) if edit_port.text.is_valid_int() else 7771
	session.connect_to_online_server(edit_name.text, edit_host.text, port)

func _on_ok() -> void:
	lbl_status.modulate = Color(0.4, 0.9, 0.4)
	btn_create.disabled = false
	btn_join.disabled = false

func _on_fail(r: String) -> void:
	lbl_status.text = r
	lbl_status.modulate = Color(1, 0.4, 0.3)
	btn_create.disabled = true
	btn_join.disabled = true

func _on_create() -> void:
	session.create_room()
	btn_start.disabled = false

func _on_join() -> void:
	session.join_room(edit_code.text)

func _on_start() -> void:
	session.start_match()

func _on_leave() -> void:
	session.leave_room()
	lbl_room.text = "—"

func _on_back() -> void:
	if session and session.is_connected:
		session.disconnect_session()
	visible = false

func _on_room(code: String, players: Dictionary, host_id: int) -> void:
	var lines := "غرفة %s | مضيف %d\n" % [code, host_id]
	for k in players.keys():
		lines += "• %s\n" % str(players[k])
	lbl_room.text = lines
	edit_code.text = code

func _on_room_res(ok: bool, code: String, msg: String) -> void:
	lbl_status.text = msg
	if ok:
		edit_code.text = code
		btn_leave.disabled = false

func _on_match(_players: Dictionary) -> void:
	visible = false
	if SaveSystem:
		SaveSystem.current_save = SaveSystem.create_default_save()
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().change_scene_to_file("res://scenes/world/MainWorld.tscn")
