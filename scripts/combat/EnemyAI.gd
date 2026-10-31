extends CharacterBody3D
## عدو أساسي — تجول · انتباه · مطاردة · قتال · تراجع
## الجزء 9

enum State { IDLE, WANDER, ALERT, CHASE, ATTACK, RETREAT, DEAD }

@export var max_health: float = 80.0
@export var damage: float = 10.0
@export var detect_range: float = 18.0
@export var attack_range: float = 2.4
@export var move_speed: float = 5.5
@export var difficulty: float = 1.0  # 0.7 سهل · 1 عادي · 1.3 صعب

var health: float = 80.0
var state: State = State.WANDER
var player: Node3D = null
var home: Vector3 = Vector3.ZERO
var _wander_target: Vector3 = Vector3.ZERO
var _attack_cd: float = 0.0
var _invuln: float = 0.0
var _state_timer: float = 0.0
var _alive: bool = true

func _ready() -> void:
	add_to_group("enemies")
	health = max_health * difficulty
	max_health = health
	home = global_position
	_pick_wander()
	_build()
	collision_layer = 1
	collision_mask = 1
	set_physics_process(true)

func setup(p_player: Node3D, diff: float = 1.0) -> void:
	player = p_player
	difficulty = diff
	health = max_health * difficulty
	max_health = health

func _build() -> void:
	var model: Node3D = null
	var AL = load("res://scripts/core/AssetLibrary.gd")
	if AL:
		model = AL.make_character("male_b")
	if model:
		add_child(model)
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.12, 0.12)
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.55, 1.5, 0.35)
		body.mesh = box
		body.material_override = mat
		body.position.y = 0.85
		body.name = "Body"
		add_child(body)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.45
	col.shape = cap
	col.position.y = 0.85
	add_child(col)
	var lab := Label3D.new()
	lab.name = "HPLabel"
	lab.font_size = 28
	lab.modulate = Color(1, 0.4, 0.35)
	lab.position = Vector3(0, 2.1, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.text = "عدو"
	add_child(lab)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_state_timer += delta
	if player == null or not is_instance_valid(player):
		var plist := get_tree().get_nodes_in_group("player")
		if plist.size() > 0:
			player = plist[0]
	_update_state(delta)
	_move(delta)
	_update_label()

func _update_state(_delta: float) -> void:
	if player == null:
		state = State.WANDER
		return
	var dist := global_position.distance_to(player.global_position)
	match state:
		State.WANDER, State.IDLE:
			if dist < detect_range * difficulty:
				state = State.ALERT
				_state_timer = 0.0
		State.ALERT:
			if dist < detect_range:
				state = State.CHASE
			elif _state_timer > 2.0:
				state = State.WANDER
		State.CHASE:
			if dist <= attack_range:
				state = State.ATTACK
			elif dist > detect_range * 1.8:
				state = State.WANDER
			if health < max_health * 0.25:
				state = State.RETREAT
		State.ATTACK:
			if dist > attack_range * 1.3:
				state = State.CHASE
			elif _attack_cd <= 0.0:
				_do_attack()
		State.RETREAT:
			if health > max_health * 0.4 or _state_timer > 4.0:
				state = State.CHASE
				_state_timer = 0.0

func _move(delta: float) -> void:
	var goal := global_position
	match state:
		State.WANDER:
			goal = _wander_target
			if global_position.distance_to(_wander_target) < 2.0:
				_pick_wander()
		State.CHASE, State.ALERT:
			if player:
				goal = player.global_position
		State.ATTACK:
			goal = global_position  # قف للضرب
		State.RETREAT:
			if player:
				goal = global_position + (global_position - player.global_position).normalized() * 8.0
	var to := goal - global_position
	to.y = 0.0
	if to.length() > 0.4 and state != State.ATTACK:
		var dir := to.normalized()
		var spd := move_speed * (1.1 if state == State.CHASE else 0.85)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	velocity.y -= 18.0 * delta
	move_and_slide()

func _do_attack() -> void:
	_attack_cd = 0.9 / difficulty
	if player == null:
		return
	if global_position.distance_to(player.global_position) > attack_range * 1.15:
		return
	var vitals = player.get_node_or_null("PlayerVitals")
	if vitals and vitals.has_method("take_damage"):
		vitals.take_damage(damage * difficulty, "enemy")

func take_damage(amount: float, _from: Node = null) -> void:
	if not _alive or _invuln > 0.0:
		return
	health -= amount
	_invuln = 0.25
	if state == State.WANDER or state == State.IDLE:
		state = State.CHASE
	if _from and _from is Node3D:
		player = _from
	if health <= 0.0:
		_die()

func _die() -> void:
	_alive = false
	state = State.DEAD
	# مكافأة بسيطة
	var amt := int(25 * difficulty)
	var eco := get_node_or_null("/root/EconomyManager")
	if eco and eco.has_method("add_money"):
		eco.add_money(amt, "هزيمة عدو")
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_signal("notification"):
		qm.emit_signal("notification", "+%d 💰" % amt)
	queue_free()

func _pick_wander() -> void:
	var a := randf() * TAU
	var d := randf_range(4.0, 12.0)
	_wander_target = home + Vector3(cos(a) * d, 0, sin(a) * d)

func _update_label() -> void:
	var lab := get_node_or_null("HPLabel")
	if lab:
		lab.text = "%d" % int(health)
