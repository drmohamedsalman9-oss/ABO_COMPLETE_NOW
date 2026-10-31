extends Node
## جلسة الشبكة الموحّدة (Autoload) — نفس المسار على الخادم والعميل
## يدعم: خادم مخصّص + عميل أونلاين
## الجزء 6 | أبو كردوم

signal status_changed(text: String)
signal connected_ok()
signal connection_failed(reason: String)
signal room_updated(code: String, players: Dictionary, host_id: int)
signal room_result(ok: bool, code: String, msg: String)
signal match_started(players: Dictionary)

const CONFIG_PATH := "res://data/network_config.json"
const USER_CONFIG := "user://network_config.json"

var server_host: String = "127.0.0.1"
var server_port: int = 7771
var max_per_room: int = 4

var is_dedicated_server: bool = false
var is_connected: bool = false
var match_running: bool = false
var local_name: String = "ضيف"
var local_id: int = 0
var room_code: String = ""
var room_players: Dictionary = {}
var room_host_id: int = 0

# server state
var rooms: Dictionary = {}
var peer_room: Dictionary = {}
var peer_names: Dictionary = {}

func _ready() -> void:
	_load_config()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _load_config() -> void:
	for path in [USER_CONFIG, CONFIG_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var data = JSON.parse_string(f.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			server_host = str(data.get("online_server_host", server_host))
			server_port = int(data.get("online_server_port", server_port))
			max_per_room = int(data.get("max_players_per_room", max_per_room))
			break

func save_user_config() -> void:
	var data := {
		"online_server_host": server_host,
		"online_server_port": server_port,
		"max_players_per_room": max_per_room,
		"protocol_version": "0.6.0"
	}
	var f := FileAccess.open(USER_CONFIG, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

# ═══════════ خادم مخصّص ═══════════
func start_dedicated_server(port: int = -1) -> bool:
	if port > 0:
		server_port = port
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(server_port, 32)
	if err != OK:
		print("[Session] Server failed port ", server_port)
		return false
	multiplayer.multiplayer_peer = peer
	is_dedicated_server = true
	print("[Session] DEDICATED SERVER on ", server_port)
	return true

# ═══════════ عميل ═══════════
func connect_to_online_server(player_name: String, host: String = "", port: int = -1) -> void:
	_load_config()
	if host != "":
		server_host = host
	if port > 0:
		server_port = port
	save_user_config()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	local_name = player_name.strip_edges()
	if local_name == "":
		local_name = "ضيف"
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(server_host, server_port)
	if err != OK:
		emit_signal("connection_failed", "تعذّر بدء الاتصال")
		return
	multiplayer.multiplayer_peer = peer
	is_dedicated_server = false
	is_connected = false
	emit_signal("status_changed", "جاري الاتصال بـ %s:%d ..." % [server_host, server_port])
	get_tree().create_timer(10.0).timeout.connect(func():
		if not is_connected and not is_dedicated_server:
			disconnect_session()
			emit_signal("connection_failed", "انتهت مهلة الاتصال بالخادم")
	)

func disconnect_session() -> void:
	match_running = false
	is_connected = false
	room_code = ""
	room_players.clear()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	emit_signal("status_changed", "غير متصل")

func create_room() -> void:
	if is_connected:
		rpc_create_room.rpc_id(1)

func join_room(code: String) -> void:
	if is_connected:
		rpc_join_room.rpc_id(1, code)

func leave_room() -> void:
	if is_connected:
		rpc_leave_room.rpc_id(1)
	room_code = ""
	room_players.clear()

func start_match() -> void:
	if is_connected:
		rpc_start_match.rpc_id(1)

func send_player_state(pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	if match_running and is_connected:
		rpc_player_state.rpc_id(1, pos, yaw, mesh_yaw)

# ═══════════ RPC ═══════════
@rpc("any_peer", "reliable")
func rpc_set_name(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	player_name = player_name.strip_edges().replace("\n", "")
	if player_name.length() < 1 or player_name.length() > 24:
		player_name = "ضيف_%d" % id
	peer_names[id] = player_name
	rpc_name_ack.rpc_id(id, player_name, id)

@rpc("authority", "reliable")
func rpc_name_ack(n: String, uid: int) -> void:
	local_name = n
	local_id = uid
	emit_signal("status_changed", "مسجّل: %s" % n)

@rpc("any_peer", "reliable")
func rpc_create_room() -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if peer_room.has(id):
		rpc_room_result.rpc_id(id, false, "", "أنت في غرفة بالفعل")
		return
	var code := _gen_code()
	rooms[code] = {"host_id": id, "players": {id: peer_names.get(id, "ضيف")}, "started": false}
	peer_room[id] = code
	rpc_room_result.rpc_id(id, true, code, "تم إنشاء الغرفة")
	_broadcast_room(code)

@rpc("any_peer", "reliable")
func rpc_join_room(code: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	code = code.strip_edges().to_upper()
	if not rooms.has(code):
		rpc_room_result.rpc_id(id, false, "", "رمز غرفة غير صحيح")
		return
	var room: Dictionary = rooms[code]
	if room.get("started", false):
		rpc_room_result.rpc_id(id, false, "", "الغرفة بدأت")
		return
	var players: Dictionary = room["players"]
	if players.size() >= max_per_room:
		rpc_room_result.rpc_id(id, false, "", "الغرفة ممتلئة")
		return
	if peer_room.has(id):
		rpc_room_result.rpc_id(id, false, "", "غادر غرفتك أولاً")
		return
	players[id] = peer_names.get(id, "ضيف")
	room["players"] = players
	peer_room[id] = code
	rpc_room_result.rpc_id(id, true, code, "تم الانضمام")
	_broadcast_room(code)

@rpc("any_peer", "reliable")
func rpc_leave_room() -> void:
	if multiplayer.is_server():
		_leave_room(multiplayer.get_remote_sender_id())

@rpc("any_peer", "reliable")
func rpc_start_match() -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not peer_room.has(id):
		return
	var code: String = peer_room[id]
	var room: Dictionary = rooms[code]
	if int(room.get("host_id", -1)) != id:
		rpc_room_result.rpc_id(id, false, code, "فقط المضيف يبدأ")
		return
	room["started"] = true
	for pid in room["players"].keys():
		rpc_match_start.rpc_id(int(pid), code, room["players"])

@rpc("authority", "reliable")
func rpc_room_result(ok: bool, code: String, msg: String) -> void:
	if ok:
		room_code = code
	emit_signal("room_result", ok, code, msg)
	emit_signal("status_changed", msg + ((" | " + code) if ok else ""))

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
func rpc_player_state(pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not peer_room.has(id):
		return
	var code: String = peer_room[id]
	var room: Dictionary = rooms.get(code, {})
	if room.is_empty() or not room.get("started", false):
		return
	for pid in room["players"].keys():
		if int(pid) != id:
			rpc_player_state_relay.rpc_id(int(pid), id, pos, yaw, mesh_yaw)

@rpc("authority", "unreliable_ordered")
func rpc_player_state_relay(from_id: int, pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	var sync := get_tree().root.find_child("NetworkPlayerSync", true, false)
	if sync and sync.has_method("apply_remote_state"):
		sync.apply_remote_state(from_id, pos, yaw, mesh_yaw)

# ═══════════ helpers ═══════════
func _on_connected_to_server() -> void:
	is_connected = true
	local_id = multiplayer.get_unique_id()
	emit_signal("connected_ok")
	emit_signal("status_changed", "متصل بالخادم ✓")
	rpc_set_name.rpc_id(1, local_name)

func _on_connection_failed() -> void:
	is_connected = false
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed", "فشل الاتصال. هل الخادم يعمل؟")

func _on_server_disconnected() -> void:
	is_connected = false
	match_running = false
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed", "انقطع الاتصال بالخادم")

func _on_peer_connected(id: int) -> void:
	if is_dedicated_server or multiplayer.is_server():
		peer_names[id] = "ضيف_%d" % id
		print("[Session] peer ", id)

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		_leave_room(id)
		peer_names.erase(id)

func _leave_room(id: int) -> void:
	if not peer_room.has(id):
		return
	var code: String = peer_room[id]
	peer_room.erase(id)
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]
	players.erase(id)
	if players.is_empty():
		rooms.erase(code)
		return
	if int(room.get("host_id", -1)) == id:
		room["host_id"] = int(players.keys()[0])
	room["players"] = players
	rooms[code] = room
	_broadcast_room(code)

func _broadcast_room(code: String) -> void:
	var room: Dictionary = rooms[code]
	for pid in room["players"].keys():
		rpc_room_update.rpc_id(int(pid), code, room["players"], int(room["host_id"]))

func _gen_code() -> String:
	const chars := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	for i in range(40):
		var c := ""
		for j in range(5):
			c += chars[randi() % chars.length()]
		if not rooms.has(c):
			return c
	return str(Time.get_ticks_msec() % 100000).pad_zeros(5)
