extends Node
## عميل اللعب عبر الإنترنت — يتصل بخادم OnlineGameServer
## منفصل عن اللعب المحلي (الجزء 5)
## الجزء 6

signal status_changed(text: String)
signal connected_to_server()
signal connection_failed(reason: String)
signal room_updated(code: String, players: Dictionary, host_id: int)
signal room_result(ok: bool, code: String, msg: String)
signal match_started(players: Dictionary)

const CONFIG_PATH := "res://data/network_config.json"

var server_host: String = "127.0.0.1"
var server_port: int = 7771
var local_name: String = "ضيف"
var local_id: int = 0
var room_code: String = ""
var room_players: Dictionary = {}
var room_host_id: int = 0
var is_connected: bool = false
var match_running: bool = false

func _ready() -> void:
	name = "OnlineMultiplayerManager"
	_load_config()
	# اربط RPCs من الخادم — نفس أسماء الدوال على العميل
	# Godot يطابق rpc بالاسم على العقدة التي لها نفس المسار النسبي صعب مع peer منفصل
	# نستخدم multiplayer API على نفس الـ node name عبر root
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_disc)

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		server_host = str(data.get("online_server_host", server_host))
		server_port = int(data.get("online_server_port", server_port))

func set_server(host: String, port: int) -> void:
	server_host = host.strip_edges()
	server_port = port
	# احفظ محلياً
	_save_config()

func _save_config() -> void:
	var data := {
		"online_server_host": server_host,
		"online_server_port": server_port,
		"max_players_per_room": 4,
		"connection_timeout_sec": 10,
		"protocol_version": "0.6.0"
	}
	# user:// للتعديل على الجهاز دون تغيير res
	var f := FileAccess.open("user://network_config.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
	# حاول قراءة user أولاً في المرات القادمة
	if FileAccess.file_exists("user://network_config.json"):
		pass

func connect_to_server(player_name: String) -> void:
	# لا تخلط مع المحلي
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	local_name = player_name.strip_edges()
	if local_name == "":
		local_name = "ضيف"
	# تحميل من user إن وُجد
	if FileAccess.file_exists("user://network_config.json"):
		var uf := FileAccess.open("user://network_config.json", FileAccess.READ)
		if uf:
			var d = JSON.parse_string(uf.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				server_host = str(d.get("online_server_host", server_host))
				server_port = int(d.get("online_server_port", server_port))
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(server_host, server_port)
	if err != OK:
		emit_signal("connection_failed", "تعذّر بدء الاتصال")
		return
	multiplayer.multiplayer_peer = peer
	emit_signal("status_changed", "جاري الاتصال بـ %s:%d ..." % [server_host, server_port])
	get_tree().create_timer(10.0).timeout.connect(_timeout)

func _timeout() -> void:
	if not is_connected:
		disconnect_from_server()
		emit_signal("connection_failed", "انتهت مهلة الاتصال بالخادم")

func disconnect_from_server() -> void:
	match_running = false
	is_connected = false
	room_code = ""
	room_players.clear()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	emit_signal("status_changed", "غير متصل")

func create_room() -> void:
	if not is_connected:
		emit_signal("connection_failed", "اتصل بالخادم أولاً")
		return
	_call_server("rpc_create_room")

func join_room(code: String) -> void:
	if not is_connected:
		emit_signal("connection_failed", "اتصل بالخادم أولاً")
		return
	_call_server("rpc_join_room", [code])

func leave_room() -> void:
	if is_connected:
		_call_server("rpc_leave_room")
	room_code = ""
	room_players.clear()

func start_match() -> void:
	_call_server("rpc_start_match")

func _call_server(method: String, args: Array = []) -> void:
	# استدعاء RPC على الخادم (peer 1)
	if multiplayer.multiplayer_peer == null:
		return
	match method:
		"rpc_create_room":
			rpc_create_room.rpc_id(1)
		"rpc_join_room":
			rpc_join_room.rpc_id(1, args[0] if args.size() else "")
		"rpc_leave_room":
			rpc_leave_room.rpc_id(1)
		"rpc_start_match":
			rpc_start_match.rpc_id(1)
		"rpc_set_name":
			rpc_set_name.rpc_id(1, local_name)

# —— تعريفات RPC يجب أن تطابق أسماء الخادم ——
@rpc("any_peer", "reliable")
func rpc_set_name(_n: String) -> void:
	pass

@rpc("any_peer", "reliable")
func rpc_create_room() -> void:
	pass

@rpc("any_peer", "reliable")
func rpc_join_room(_code: String) -> void:
	pass

@rpc("any_peer", "reliable")
func rpc_leave_room() -> void:
	pass

@rpc("any_peer", "reliable")
func rpc_start_match() -> void:
	pass

@rpc("authority", "reliable")
func rpc_name_ack(n: String, uid: int) -> void:
	local_name = n
	local_id = uid
	emit_signal("status_changed", "مسجّل: %s (ID %d)" % [n, uid])

@rpc("authority", "reliable")
func rpc_room_result(ok: bool, code: String, msg: String) -> void:
	if ok:
		room_code = code
	emit_signal("room_result", ok, code, msg)
	emit_signal("status_changed", msg + ((" | رمز: " + code) if ok else ""))

@rpc("authority", "reliable")
func rpc_room_update(code: String, players: Dictionary, host_id: int) -> void:
	room_code = code
	room_players = players
	room_host_id = host_id
	emit_signal("room_updated", code, players, host_id)

@rpc("authority", "reliable")
func rpc_match_start(code: String, players: Dictionary) -> void:
	room_code = code
	room_players = players
	match_running = true
	emit_signal("match_started", players)

@rpc("any_peer", "unreliable_ordered")
func rpc_player_state(_pos: Vector3, _yaw: float, _mesh_yaw: float) -> void:
	pass

@rpc("authority", "unreliable_ordered")
func rpc_player_state_relay(from_id: int, pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	# يعالجها NetworkPlayerSync عبر الإشارة أو البحث عن المدير
	var sync := get_tree().root.find_child("NetworkPlayerSync", true, false)
	if sync and sync.has_method("apply_remote_state"):
		sync.apply_remote_state(from_id, pos, yaw, mesh_yaw)

func send_player_state(pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	if not match_running or multiplayer.multiplayer_peer == null:
		return
	rpc_player_state.rpc_id(1, pos, yaw, mesh_yaw)

func _on_connected() -> void:
	is_connected = true
	local_id = multiplayer.get_unique_id()
	emit_signal("connected_to_server")
	emit_signal("status_changed", "متصل بالخادم ✓")
	rpc_set_name.rpc_id(1, local_name)

func _on_failed() -> void:
	is_connected = false
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed", "فشل الاتصال بالخادم. تأكد أنه يعمل وأن العنوان صحيح.")

func _on_server_disc() -> void:
	is_connected = false
	match_running = false
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed", "انقطع الاتصال بالخادم")
