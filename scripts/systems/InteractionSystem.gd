extends Node
## نظام تفاعل موحّد: أبواب · مركبات · شخصيات · نقاط متجر
## يُضاف كابن على اللاعب أو يُدار من WorldManager

signal interaction_available(text: String)
signal interaction_cleared
signal interacted(target: Node)

var _target: Node = null
var _prompt := ""
var range_distance := 3.0
var player: Node3D = null

func setup(p: Node3D) -> void:
	player = p

func _physics_process(_d: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var best: Node = null
	var best_d := range_distance
	var best_txt := ""
	for g in ["interactable", "vehicle", "npc", "shop", "enterable"]:
		for n in player.get_tree().get_nodes_in_group(g):
			if n == player or not n is Node3D:
				continue
			var d: float = player.global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
				best_txt = _label_for(n)
	if best != _target:
		_target = best
		_prompt = best_txt
		if _target:
			emit_signal("interaction_available", _prompt)
		else:
			emit_signal("interaction_cleared")

func try_interact() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	emit_signal("interacted", _target)
	if _target.has_method("on_interact"):
		_target.on_interact(player)
		return true
	if _target.is_in_group("vehicle") and player.has_method("try_enter_nearest_vehicle"):
		player.try_enter_nearest_vehicle()
		return true
	return false

func _label_for(n: Node) -> String:
	if n.is_in_group("vehicle"):
		return "E  اركب"
	if n.is_in_group("shop"):
		return "E  متجر"
	if n.is_in_group("enterable"):
		return "E  ادخل"
	if n.is_in_group("npc"):
		return "E  تحدث"
	return "E  تفاعل"
