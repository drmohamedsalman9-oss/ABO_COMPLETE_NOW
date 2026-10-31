extends CharacterBody3D
## مشاة — مشي على مسار · توقف · تفاعل بسيط

enum State { WALK, IDLE, FLEE }

var path: Array = []
var path_i: int = 0
var player: Node3D = null
var state: State = State.WALK
var speed: float = 2.2
var _idle_t: float = 0.0
var _update_t: float = 0.0
var agent: NavigationAgent3D = null
var use_nav := true

func setup(p_path: Array, p_player: Node3D) -> void:
	path = p_path
	player = p_player
	path_i = randi() % maxi(1, path.size())
	speed = randf_range(1.8, 2.8)
	add_to_group("pedestrians")
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 1.2
	agent.target_desired_distance = 1.5
	agent.avoidance_enabled = false
	add_child(agent)
	_build()
	collision_layer = 2
	collision_mask = 1

func _build() -> void:
	var model: Node3D = null
	var AL = load("res://scripts/core/AssetLibrary.gd")
	if AL:
		model = AL.random_civilian()
	if model:
		model.position = Vector3(0, 0, 0)
		add_child(model)
		var anim_helper := Node3D.new()
		anim_helper.set_script(load("res://scripts/city_ai/AnimatedHumanoid.gd"))
		model.add_child(anim_helper)
		if anim_helper.has_method("setup_from_child"):
			anim_helper.setup_from_child()
		# احفظ مرجع
		set_meta("anim_helper", anim_helper)
	else:
		var colors := [Color(0.3, 0.3, 0.35), Color(0.25, 0.28, 0.4), Color(0.4, 0.25, 0.2), Color(0.2, 0.35, 0.3)]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[randi() % colors.size()]
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.45, 1.4, 0.3)
		body.mesh = box
		body.material_override = mat
		body.position.y = 0.8
		add_child(body)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.22
	cap.height = 1.3
	col.shape = cap
	col.position.y = 0.8
	add_child(col)

func _physics_process(delta: float) -> void:
	_update_t += delta
	# تحديث أبطأ للبعيدين
	if player:
		var dist := global_position.distance_to(player.global_position)
		if dist > 80.0:
			velocity = Vector3.ZERO
			return
		if dist > 40.0:
			if _update_t < 0.35:
				return
			_update_t = 0.0
	match state:
		State.WALK:
			_walk(delta)
			if player and global_position.distance_to(player.global_position) < 2.5:
				# توقف عند اقتراب اللاعب
				if randf() < 0.3:
					state = State.IDLE
					_idle_t = randf_range(1.0, 2.5)
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 8 * delta)
			velocity.z = move_toward(velocity.z, 0, 8 * delta)
			_idle_t -= delta
			if _idle_t <= 0.0:
				state = State.WALK
		State.FLEE:
			if player:
				var away := (global_position - player.global_position).normalized()
				velocity.x = away.x * speed * 1.8
				velocity.z = away.z * speed * 1.8
	velocity.y -= 15.0 * delta
	move_and_slide()

func _walk(delta: float) -> void:
	# NavMesh إن توفّر
	if use_nav and agent and path.size() > 0:
		var dest: Vector3 = path[path_i]
		agent.set_target_position(dest)
		if agent.is_navigation_finished():
			path_i = (path_i + 1) % path.size()
			agent.set_target_position(path[path_i])
			if randf() < 0.2:
				state = State.IDLE
				_idle_t = randf_range(0.8, 2.0)
			return
		var next_pos := agent.get_next_path_position()
		var dir_n := next_pos - global_position
		dir_n.y = 0.0
		if dir_n.length() > 0.05:
			dir_n = dir_n.normalized()
			var OA2 = load("res://scripts/ai/ObstacleAvoidance.gd")
			if OA2:
				dir_n = OA2.steer_dir(self, dir_n, speed, delta)
			velocity.x = dir_n.x * speed
			velocity.z = dir_n.z * speed
			look_at(global_position + dir_n, Vector3.UP)
			if has_meta("anim_helper"):
				var h = get_meta("anim_helper")
				if h and h.has_method("play_walk"):
					h.play_walk()
			return
	# —— مسار يدوي احتياطي ——
	if path.is_empty():
		return
	var target: Vector3 = path[path_i]
	var to := target - global_position
	to.y = 0.0
	if to.length() < 1.5:
		path_i = (path_i + 1) % path.size()
		# وقفة عشوائية عند نقطة المسار
		if randf() < 0.2:
			state = State.IDLE
			_idle_t = randf_range(0.8, 2.0)
			if has_meta("anim_helper"):
				var h2 = get_meta("anim_helper")
				if h2 and h2.has_method("play_idle"):
					h2.play_idle()
		return
	var dir := to.normalized()
	var OA = load("res://scripts/ai/ObstacleAvoidance.gd")
	if OA:
		dir = OA.steer_dir(self, dir, speed, delta)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if has_meta("anim_helper"):
		var h = get_meta("anim_helper")
		if h and h.has_method("play_walk"):
			h.play_walk()
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)

func scare() -> void:
	state = State.FLEE
