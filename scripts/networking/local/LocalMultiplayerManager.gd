extends Node
## لعب جماعي محلي حقيقي — ENet / UDP على الشبكة المحلية
## الجزء 5 | أبو كردوم
## لا يحتاج إنترنت — Wi-Fi أو هوتسبوت

signal connection_succeeded()
signal connection_failed(reason: String)
signal player_list_changed(players: Dictionary)
signal lobby_message(text: String)
signal match_started()
signal peer_disconnected(peer_id: int)

const DEFAULT_PORT := 7770
const MAX_PLAYERS := 4
const VERSION := "0.5.0"

## peer_id -> {name, ready}
var players: Dictionary = {}
var local_player_name: String = "لاعب"
var is_host: bool = false
var is_connected: bool = false
var current_port: int = DEFAULT_PORT
var host_address: String = ""
var match_running: bool = false

func _ready() -> void:
	name = "LocalMultiplayerManager"
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func get_local_ip() -> String:
	var addrs := IP.get_local_addresses()
	var preferred := ""
	for a in addrs:
		# تجاهل loopback و IPv6 غالباً
		if a.begins_with("127."):
			continue
		if ":" in a:
			continue
		# فضّل شبكات خاصة شائعة
		if a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172."):
			return a
		if preferred == "":
			preferred = a
	return preferred if preferred != "" else "0.0.0.0"

func host_game(player_name: String, port: int = DEFAULT_PORT) -> void:
	local_player_name = player_name.strip_edges()
	if local_player_name == "":
		local_player_name = "المضيف"
	current_port = port
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		emit_signal("connection_failed", "فشل فتح المنفذ %d (قد يكون مستخدماً). جرّب منفذاً آخر." % port)
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	is_connected = true
	players.clear()
	players[1] = {"name": local_player_name, "ready": true}
	host_address = get_local_ip()
	emit_signal("lobby_message", "الغرفة جاهزة\nIP: %s\nالمنفذ: %d" % [host_address, port])
	emit_signal("player_list_changed", players)
	emit_signal("connection_succeeded")
	print("[LocalMP] Host on ", host_address, ":", port)

func join_game(address: String, player_name: String, port: int = DEFAULT_PORT) -> void:
	local_player_name = player_name.strip_edges()
	if local_player_name == "":
		local_player_name = "لاعب"
	address = address.strip_edges()
	if address == "":
		emit_signal("connection_failed", "أدخل عنوان IP الخاص بالمضيف")
		return
	current_port = port
	host_address = address
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		emit_signal("connection_failed", "تعذّر بدء الاتصال")
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	is_connected = false  # حتى يتأكد connected_to_server
	emit_signal("lobby_message", "جاري الاتصال بـ %s:%d ..." % [address, port])
	# مهلة
	get_tree().create_timer(8.0).timeout.connect(_join_timeout)

func _join_timeout() -> void:
	if not is_connected and not is_host:
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = null
		emit_signal("connection_failed", "انتهت مهلة الاتصال. تأكد من IP والشبكة/الهوتسبوت.")

func leave_game() -> void:
	match_running = false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()
	is_host = false
	is_connected = false
	emit_signal("lobby_message", "غادرت الغرفة")
	emit_signal("player_list_changed", players)

func start_match() -> void:
	if not is_host:
		return
	if players.size() < 1:
		emit_signal("lobby_message", "لا يوجد لاعبون")
		return
	match_running = true
	_rpc_start_match.rpc(players)
	# المضيف أيضاً
	emit_signal("match_started")

@rpc("authority", "call_local", "reliable")
func _rpc_start_match(player_data: Dictionary) -> void:
	players = player_data
	match_running = true
	emit_signal("match_started")

func _on_peer_connected(id: int) -> void:
	print("[LocalMP] peer connected: ", id)
	if is_host:
		# اطلب الاسم من العميل
		_rpc_request_info.rpc_id(id)

func _on_peer_disconnected(id: int) -> void:
	print("[LocalMP] peer disconnected: ", id)
	if players.has(id):
		players.erase(id)
	emit_signal("player_list_changed", players)
	emit_signal("peer_disconnected", id)
	emit_signal("lobby_message", "لاعب غادر (ID %d)" % id)

func _on_connected_to_server() -> void:
	is_connected = true
	emit_signal("connection_succeeded")
	emit_signal("lobby_message", "تم الاتصال بالمضيف")
	# أرسل الاسم
	_rpc_register_player.rpc_id(1, local_player_name)

func _on_connection_failed() -> void:
	is_connected = false
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed", "فشل الاتصال بالمضيف")

func _on_server_disconnected() -> void:
	is_connected = false
	match_running = false
	players.clear()
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed", "انقطع الاتصال بالمضيف")
	emit_signal("player_list_changed", players)

@rpc("authority", "reliable")
func _rpc_request_info() -> void:
	_rpc_register_player.rpc_id(1, local_player_name)

@rpc("any_peer", "reliable")
func _rpc_register_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sid := multiplayer.get_remote_sender_id()
	if sid == 0:
		sid = multiplayer.get_unique_id()
	player_name = player_name.strip_edges()
	if player_name == "":
		player_name = "لاعب %d" % sid
	players[sid] = {"name": player_name, "ready": true}
	_rpc_update_player_list.rpc(players)
	emit_signal("player_list_changed", players)
	emit_signal("lobby_message", "انضم: %s" % player_name)

@rpc("authority", "call_local", "reliable")
func _rpc_update_player_list(list: Dictionary) -> void:
	players = list
	emit_signal("player_list_changed", players)

func get_player_name(peer_id: int) -> String:
	if players.has(peer_id):
		return str(players[peer_id].get("name", "لاعب"))
	return "لاعب %d" % peer_id
