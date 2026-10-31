extends Node
## مزامنة اللاعبين — محلي (جزء 5) + أونلاين (جزء 6)

const SYNC_RATE := 0.05

var player_body: CharacterBody3D = null
var _timer: float = 0.0
var _remote_players: Dictionary = {}
var _world: Node = null

func setup(p_player: CharacterBody3D, world: Node) -> void:
	player_body = p_player
	_world = world
	set_process(true)
	var lmp := get_tree().root.find_child("LocalMultiplayerManager", true, false)
	if lmp and lmp.has_signal("peer_disconnected"):
		if not lmp.peer_disconnected.is_connected(_on_peer_left):
			lmp.peer_disconnected.connect(_on_peer_left)

func _process(delta: float) -> void:
	if player_body == null or multiplayer.multiplayer_peer == null:
		return
	if not multiplayer.has_multiplayer_peer():
		return
	_timer += delta
	if _timer < SYNC_RATE:
		return
	_timer = 0.0
	if not player_body.visible:
		return
	if player_body.get("control_enabled") == false:
		return
	var pos := player_body.global_position
	var yaw := player_body.rotation.y
	var mesh_yaw := 0.0
	var mesh := player_body.get_node_or_null("MeshRoot")
	if mesh:
		mesh_yaw = mesh.rotation.y
	# أونلاين عبر الخادم؟
	var omp := get_node_or_null("/root/MultiplayerSession")
	if omp and omp.get("match_running") == true and omp.has_method("send_player_state"):
		omp.send_player_state(pos, yaw, mesh_yaw)
		return
	# محلي: بث مباشر
	_rpc_sync_state.rpc(pos, yaw, mesh_yaw)

@rpc("any_peer", "unreliable_ordered")
func _rpc_sync_state(pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	var sid := multiplayer.get_remote_sender_id()
	if sid == multiplayer.get_unique_id():
		return
	apply_remote_state(sid, pos, yaw, mesh_yaw)

func apply_remote_state(peer_id: int, pos: Vector3, yaw: float, mesh_yaw: float) -> void:
	_ensure_remote_player(peer_id)
	var remote: Node3D = _remote_players.get(peer_id)
	if remote == null:
		return
	remote.global_position = remote.global_position.lerp(pos, 0.45)
	remote.rotation.y = lerp_angle(remote.rotation.y, yaw, 0.4)
	var mesh: Node3D = remote.get_node_or_null("MeshRoot")
	if mesh:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, mesh_yaw, 0.4)

func _ensure_remote_player(peer_id: int) -> void:
	if _remote_players.has(peer_id) or _world == null:
		return
	var root := Node3D.new()
	root.name = "RemotePlayer_%d" % peer_id
	var mesh_root := Node3D.new()
	mesh_root.name = "MeshRoot"
	root.add_child(mesh_root)
	var VisualScript: GDScript = load("res://scripts/player/PlayerVisual.gd")
	if VisualScript:
		var visual: Node3D = VisualScript.new()
		mesh_root.add_child(visual)
	var label := Label3D.new()
	label.text = _resolve_name(peer_id)
	label.font_size = 48
	label.modulate = Color(0.92, 0.75, 0.2)
	label.outline_size = 6
	label.position = Vector3(0, 2.4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	_world.add_child(root)
	_remote_players[peer_id] = root

func _resolve_name(peer_id: int) -> String:
	var omp := get_node_or_null("/root/MultiplayerSession")
	if omp and omp.get("room_players") is Dictionary:
		var rp: Dictionary = omp.room_players
		if rp.has(peer_id):
			return str(rp[peer_id])
		if rp.has(str(peer_id)):
			return str(rp[str(peer_id)])
	var lmp := get_tree().root.find_child("LocalMultiplayerManager", true, false)
	if lmp and lmp.has_method("get_player_name"):
		return lmp.get_player_name(peer_id)
	return "لاعب %d" % peer_id

func _on_peer_left(peer_id: int) -> void:
	if _remote_players.has(peer_id):
		var n: Node = _remote_players[peer_id]
		if is_instance_valid(n):
			n.queue_free()
		_remote_players.erase(peer_id)

func clear_all_remotes() -> void:
	for id in _remote_players.keys():
		var n: Node = _remote_players[id]
		if is_instance_valid(n):
			n.queue_free()
	_remote_players.clear()
