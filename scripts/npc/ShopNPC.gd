extends "res://scripts/npc/NPCCharacter.gd"
## متجر بسيط — علاج مقابل فلوس

func _ready() -> void:
	npc_id = "npc_shop"
	npc_name = "التاجر كريم"
	super._ready()

func _process(_d: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node3D = players[0]
	var dist := global_position.distance_to(p.global_position)
	if _label:
		_label.modulate.a = 1.0 if dist < interact_distance * 1.5 else 0.35
		_label.text = npc_name + "\n[E] متجر"
	if dist <= interact_distance and Input.is_action_just_pressed("interact"):
		_open_shop()

func _open_shop() -> void:
	var qm := get_node_or_null("/root/QuestManager")
	var vitals := get_tree().root.find_child("PlayerVitals", true, false)
	if qm == null:
		return
	# شراء علاج بـ 80
	var eco := get_node_or_null("/root/EconomyManager")
	if eco and eco.has_method("spend"):
		if eco.spend(80, "علاج"):
			if vitals and vitals.has_method("heal"):
				vitals.heal(40.0)
			if qm and qm.has_signal("notification"):
				qm.emit_signal("notification", "اشتريت علاج −80 💰")
		else:
			if qm and qm.has_signal("notification"):
				qm.emit_signal("notification", "محتاج 80 💰 للعلاج")
	elif qm and int(qm.money) >= 80:
		qm.money -= 80
		if vitals and vitals.has_method("heal"):
			vitals.heal(40.0)
