extends Node
## صحة اللاعب — ضرر / علاج / موت / إعادة ظهور
## أبو كردوم

signal health_changed(hp: float, max_hp: float)
signal died()
signal respawned()

@export var max_health: float = 100.0
var health: float = 100.0
var is_dead: bool = false
var player: CharacterBody3D = null

func setup(p: CharacterBody3D) -> void:
	player = p
	health = max_health
	is_dead = false
	emit_signal("health_changed", health, max_health)

func take_damage(amount: float, source: String = "") -> void:
	if is_dead:
		return
	health = maxf(0.0, health - amount)
	emit_signal("health_changed", health, max_health)
	if health <= 0.0:
		_die(source)

func heal(amount: float) -> void:
	if is_dead:
		return
	health = minf(max_health, health + amount)
	emit_signal("health_changed", health, max_health)

func _die(_source: String) -> void:
	is_dead = true
	emit_signal("died")
	if player and player.has_method("set_control_enabled"):
		player.set_control_enabled(false)
	# خصم فلوس
	var qm := get_node_or_null("/root/QuestManager")
	if qm:
		qm.money = maxi(0, int(qm.money * 0.85))
	# إعادة بعد ثانيتين
	get_tree().create_timer(2.5).timeout.connect(_respawn)

func _respawn() -> void:
	is_dead = false
	health = max_health * 0.6
	if player:
		player.global_position = Vector3(48, 1.5, -95)
		if player.has_method("set_control_enabled"):
			player.set_control_enabled(true)
		if player is CharacterBody3D:
			player.velocity = Vector3.ZERO
	# صفّر المطلوب
	var pm := get_tree().root.find_child("PoliceManager", true, false)
	if pm and pm.has_method("set_wanted"):
		pm.set_wanted(0)
	emit_signal("health_changed", health, max_health)
	emit_signal("respawned")
