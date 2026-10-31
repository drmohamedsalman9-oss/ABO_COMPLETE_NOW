extends CharacterBody3D
## ضابط مطاردة — تتبع · بحث · صعق

var target: Node3D = null
var mgr: Node = null
var speed: float = 7.0
var sprint_speed: float = 10.0
var stunned: bool = false
var _stun_left: float = 0.0
var _wanted: int = 1
var _search_pos: Vector3 = Vector3.ZERO
var agent: NavigationAgent3D = null
var _has_search: bool = false
var _flash_t: float = 0.0
var _siren: AudioStreamPlayer3D = null

func setup(p_target: Node3D, p_mgr: Node, wanted: int = 1) -> void:
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 1.0
	agent.target_desired_distance = 1.8
	add_child(agent)

	target = p_target
	mgr = p_mgr
	_wanted = wanted
	speed = 6.5 + wanted * 0.55
	sprint_speed = speed + 2.8
	collision_layer = 1
	collision_mask = 1
	add_to_group("police_unit")
	_build()
	_siren = AudioStreamPlayer3D.new()
	var stream: AudioStream = load("res://assets/audio/police_siren.wav")
	if stream:
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_siren.stream = stream
		_siren.max_distance = 35.0
		_siren.volume_db = -10.0
		add_child(_siren)
		_siren.play()

func set_search_target(pos: Vector3) -> void:
	_search_pos = pos
	_has_search = true

func take_damage(amount: float, _from: Node = null) -> void:
	# الضرب يرفع التوتر ويصعق قليلاً
	stun(0.4)
	if mgr and mgr.has_method("report_crime"):
		mgr.report_crime("assault")

func stun(duration: float = 1.2) -> void:
	stunned = true
	_stun_left = duration
	velocity = Vector3.ZERO
	if _siren:
		_siren.stop()

func _build() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.14, 0.4)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 1.55, 0.35)
	body.mesh = box
	body.material_override = mat
	body.position.y = 0.85
	body.name = "Body"
	add_child(body)
	var badge := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.3, 0.1, 0.3)
	badge.mesh = b
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.9, 0.75, 0.12)
	badge.material_override = gm
	badge.position.y = 1.75
	add_child(badge)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.5
	col.shape = cap
	col.position.y = 0.85
	add_child(col)
	var light := OmniLight3D.new()
	light.name = "Flash"
	light.light_color = Color(0.3, 0.4, 1.0)
	light.omni_range = 7.0
	light.position.y = 2.0
	add_child(light)
	var lab := Label3D.new()
	lab.text = "شرطة"
	lab.font_size = 26
	lab.modulate = Color(0.45, 0.55, 1.0)
	lab.position = Vector3(0, 2.15, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lab)

func _physics_process(delta: float) -> void:
	if stunned:
		_stun_left -= delta
		var body := get_node_or_null("Body")
		if body and body.material_override:
			body.material_override.albedo_color = Color(0.55, 0.1, 0.1)
		if _stun_left <= 0.0:
			stunned = false
			if body and body.material_override:
				body.material_override.albedo_color = Color(0.1, 0.14, 0.4)
			if _siren and not _siren.playing:
				_siren.play()
		velocity.y -= 18.0 * delta
		move_and_slide()
		return

	var goal: Vector3
	if target and is_instance_valid(target):
		var d := global_position.distance_to(target.global_position)
		if d < 40.0:
			goal = target.global_position
			_has_search = false
		elif _has_search:
			goal = _search_pos
		else:
			goal = target.global_position
	elif _has_search:
		goal = _search_pos
	else:
		return

	var to := goal - global_position
	to.y = 0.0
	var dist := to.length()
	var dir := to.normalized() if dist > 0.15 else Vector3.ZERO
	var use_spd := sprint_speed if dist > 12.0 else speed
	if dist > 1.0:
		if agent:
			agent.set_target_position(goal)
			if not agent.is_navigation_finished():
				var np := agent.get_next_path_position()
				dir = np - global_position
				dir.y = 0.0
				if dir.length() > 0.05:
					dir = dir.normalized()
		var OA = load("res://scripts/ai/ObstacleAvoidance.gd")
		if OA:
			dir = OA.steer_dir(self, dir, use_spd, delta)
		velocity.x = dir.x * use_spd
		velocity.z = dir.z * use_spd
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		if _has_search and dist < 2.0:
			_has_search = false
	velocity.y -= 18.0 * delta
	move_and_slide()

	if target and is_instance_valid(target) and dist < 2.5 and not stunned:
		var vitals := target.get_node_or_null("PlayerVitals")
		if vitals == null:
			vitals = get_tree().root.find_child("PlayerVitals", true, false)
		if vitals and vitals.has_method("take_damage"):
			vitals.take_damage(10.0 * delta, "police")

	_flash_t += delta * 7.0
	var flash := get_node_or_null("Flash")
	if flash:
		flash.light_energy = 0.4 + absf(sin(_flash_t)) * 1.6
