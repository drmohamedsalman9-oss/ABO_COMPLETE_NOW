extends Node
## خادم اللعب عبر الإنترنت — يُشغَّل منفصلاً (جهاز/VPS)
## أبو كردوم | الجزء 6
## ليس خادماً عاماً مستضافاً تلقائياً — تحتاج تشغيله بنفسك

const CONFIG_PATH := "res://data/network_config.json"
const DEFAULT_PORT := 7771
const MAX_PER_ROOM := 4

## room_code -> {host_id, players: {id: name}, started: bool}
var rooms: Dictionary = {}
## peer_id -> room_code
var peer_room: Dictionary = {}
## peer_id -> display name
var peer_names: Dictionary = {}

var port: int = DEFAULT_PORT

func _ready() -> void:
	_load_config()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 32)
	if err != OK:
		push_error("[OnlineServer] فشل فتح المنفذ %d" % port)
		print("[OnlineServer] FAILED port ", port, " err=", err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[OnlineServer] Listening on port ", port)
	print("[OnlineServer] Rooms ready. Protocol 0.6.0")

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		port = int(data.get("online_server_port", DEFAULT_PORT))

func _on_peer_connected(id: int) -> void:
	print("[OnlineServer] peer connected ", id)
	peer_names[id] = "ضيف_%d" % id

func _on_peer_disconnected(id: int) -> void:
	print("[OnlineServer] peer disconnected ", id)
	_leave_room(id)
	peer_names.erase(id)

@rpc("any_peer", "reliable")
func rpc_set_name(player_name: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	player_name = player_name.strip_edges()
	if player_name.length() < 1 or player_name.length() > 24:
		player_name = "ضيف_%d" % id
	# تنظيف بسيط
	player_name = player_name.replace("\n", "").replace("\t", "")
	peer_names[id] = player_name
	rpc_name_ack.rpc_id(id, player_name, id)

@rpc("authority", "reliable")
func rpc_name_ack(_name: String, _uid: int) -> void:
	pass  # client implements

@rpc("any_peer", "reliable")
func rpc_create_room() -> void:
	var id := multiplayer.get_remote_sender_id()
	if peer_room.has(id):
		rpc_room_result.rpc_id(id, false, "", "أنت بالفعل في غرفة")
		return
	var code := _gen_code()
	rooms[code] = {
		"host_id": id,
		"players": {id: peer_names.get(id, "ضيف")},
		"started": false,
	}
	peer_room[id] = code
	rpc_room_result.rpc_id(id, true, code, "تم إنشاء الغرفة")
	_broadcast_room(code)
	print("[OnlineServer] room ", code, " by ", id)

@rpc("any_peer", "reliable")
func rpc_join_room(code: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	code = code.strip_edges().to_upper()
	if peer_room.has(id):
		rpc_room_result.rpc_id(id, false, "", "غادر غرفتك الحالية أولاً")
		return
	if not rooms.has(code):
		rpc_room_result.rpc_id(id, false, "", "رمز غرفة غير صحيح")
		return
	var room: Dictionary = rooms[code]
	if room.get("started", false):
		rpc_room_result.rpc_id(id, false, "", "الغرفة بدأت بالفعل")
		return
	var players: Dictionary = room["players"]
	if players.size() >= MAX_PER_ROOM:
		rpc_room_result.rpc_id(id, false, "", "الغرفة ممتلئة")
		return
	players[id] = peer_names.get(id, "ضيف")
	room["players"] = players
	peer_room[id] = code
	rpc_room_result.rpc_id(id, true, code, "تم الانضمام")
	_broadcast_room(code)

@rpc("any_peer", "reliable")
func rpc_leave_room() -> void:
	var id := multiplayer.get_remote_sender_id()
	_leave_room(id)

@rpc("any_peer", "reliable")
func rpc_start_match() -> void:
	var id := multiplayer.get_remote_sender_id()
	if not peer_room.has(id):
		return
	var code: String = peer_room[id]
	var room: Dictionary = rooms.get(code, {})
	if room.is_empty():
		return
	if int(room.get("host_id", -1)) != id:
		rpc_room_result.rpc_id(id, false, code, "فقط المضيف يبدأ المباراة")
		return
	room["started"] = true
	rooms[code] = room
	for pid in room["players"].keys():
		rpc_match_start.rpc_id(int(pid), code, room["players"])

@rpc("authority", "reliable")
func rpc_room_result(_ok: bool, _code: String, _msg: String) -> void:
	pass

@rpc("authority", "reliable")
func rpc_room_update(_code: String, _players: Dictionary, _host_id: int) -> void:
	pass

@rpc("authority", "reliable")
func rpc_match_start(_code: String, _players: Dictionary) -> void:
	pass

## مزامنة موقع داخل الغرفة فقط
@rpc("any_peer", "unreliable_ordered")
func rpc_player_state(pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not peer_room.has(id):
		return
	var code: String = peer_room[id]
	var room: Dictionary = rooms.get(code, {})
	if room.is_empty() or not room.get("started", false):
		return
	for pid in room["players"].keys():
		var pid_i := int(pid)
		if pid_i != id:
			rpc_player_state_relay.rpc_id(pid_i, id, pos, yaw, mesh_yaw)

@rpc("authority", "unreliable_ordered")
func rpc_player_state_relay(_from_id: int, _pos: Vector3, _yaw: float, _mesh_yaw: float) -> void:
	pass

func _leave_room(id: int) -> void:
	if not peer_room.has(id):
		return
	var code: String = peer_room[id]
	peer_room.erase(id)
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var players: Dictionary = room.get("players", {})
	players.erase(id)
	if players.is_empty():
		rooms.erase(code)
		print("[OnlineServer] room closed ", code)
		return
	# نقل الاستضافة إن لزم
	if int(room.get("host_id", -1)) == id:
		room["host_id"] = int(players.keys()[0])
	room["players"] = players
	rooms[code] = room
	_broadcast_room(code)

func _broadcast_room(code: String) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	for pid in room["players"].keys():
		rpc_room_update.rpc_id(int(pid), code, room["players"], int(room["host_id"]))

func _gen_code() -> String:
	const chars := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	for _attempt in range(50):
		var c := ""
		for i in range(5):
			c += chars[randi() % chars.length()]
		if not rooms.has(c):
			return c
	return str(Time.get_ticks_msec() % 100000).pad_zeros(5)
