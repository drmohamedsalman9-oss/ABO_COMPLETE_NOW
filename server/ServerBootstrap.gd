extends Node
## تشغيل الخادم المخصّص عبر MultiplayerSession autoload

func _ready() -> void:
	await get_tree().process_frame
	var session := get_node_or_null("/root/MultiplayerSession")
	if session and session.has_method("start_dedicated_server"):
		if session.start_dedicated_server():
			print("[Bootstrap] Server running")
		else:
			print("[Bootstrap] FAILED to start server")
	else:
		push_error("MultiplayerSession autoload missing")
