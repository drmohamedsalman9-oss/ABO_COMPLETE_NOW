extends Node
## نظام الشرطة الاحترافي — مطلوبية · دوريات · مطاردة · بحث · هروب
## الجزء 8 | أبو كردوم | الملك الأخير
## محمد ماهر أبو كردوم

signal wanted_changed(level: int)
signal chase_started()
signal chase_ended()
signal player_arrested()
signal chase_event(text: String)

const MAX_WANTED := 5
const MAX_UNITS := 5
const MAX_PATROLS := 3
const SIGHT_BASE := 28.0
const SIGHT_CHASE := 45.0
const SEARCH_TIME := 12.0
const ESCAPE_NEED := 100.0

var wanted_level: int = 0
var player: Node3D = null
var world: Node = null
var units: Array = []       # مطاردون
var patrols: Array = []     # دوريات
var enabled: bool = true
var _in_chase: bool = false
var _searching: bool = false
var _search_timer: float = 0.0
var last_known_pos: Vector3 = Vector3.ZERO
var escape_progress: float = 0.0
var _spawn_cd: float = 0.0
var _patrol_init: bool = false
var _sighted: bool = false

func setup(p_player: Node3D, p_world: Node) -> void:
	player = p_player
	world = p_world
	if player:
		last_known_pos = player.global_position
	set_process(true)
	call_deferred("_spawn_patrols")

func _spawn_patrols() -> void:
	if _patrol_init or world == null:
		return
	_patrol_init = true
	var spots := [
		Vector3(80, 0.5, 0),
		Vector3(-60, 0.5, 70),
		Vector3(20, 0.5, -120),
	]
	var PatrolScript: GDScript = load("res://scripts/police/PolicePatrol.gd")
	if PatrolScript == null:
		return
	for i in range(mini(MAX_PATROLS, spots.size())):
		var p: Node3D = PatrolScript.new()
		p.position = spots[i]
		world.add_child(p)
		if p.has_method("setup"):
			p.setup(self, spots[i])
		patrols.append(p)
	print("[Police] دوريات: ", patrols.size())

func _process(delta: float) -> void:
	if not enabled or player == null:
		return
	_spawn_cd = maxf(0.0, _spawn_cd - delta)
	units = units.filter(func(u): return is_instance_valid(u))
	patrols = patrols.filter(func(u): return is_instance_valid(u))

	# اكتشاف من الدوريات دائماً (حتى wanted=0 يمكنها رفع إذا جريمة — لا، فقط رؤية عند wanted>0 أو جريمة قريبة)
	_sighted = false
	var nearest_sight := 9999.0
	for p in patrols:
		if p.has_method("can_see_player") and p.can_see_player(player, _sight_range()):
			_sighted = true
			nearest_sight = minf(nearest_sight, p.global_position.distance_to(player.global_position))
			last_known_pos = player.global_position
	for u in units:
		if not is_instance_valid(u):
			continue
		var d: float = u.global_position.distance_to(player.global_position)
		if d < _sight_range():
			_sighted = true
			last_known_pos = player.global_position
			nearest_sight = minf(nearest_sight, d)

	if wanted_level <= 0:
		_in_chase = false
		_searching = false
		escape_progress = 0.0
		return

	# —— مطاردة نشطة ——
	if _sighted:
		_searching = false
		_search_timer = SEARCH_TIME
		escape_progress = maxf(0.0, escape_progress - delta * 6.0)
		if not _in_chase:
			_in_chase = true
			emit_signal("chase_started")
			emit_signal("chase_event", "⚠ تم اكتشافك — المطاردة بدأت!")
			_play_sfx("res://assets/audio/police_radio.wav")
		_ensure_chasers()
	else:
		# فقد الرؤية → بحث في آخر موقع
		if _in_chase or _searching:
			_searching = true
			_search_timer -= delta
			# توجيه الوحدات لآخر موقع معروف
			for u in units:
				if u.has_method("set_search_target"):
					u.set_search_target(last_known_pos)
			escape_progress = minf(ESCAPE_NEED, escape_progress + delta * 12.0)
			if _search_timer <= 0.0:
				escape_progress = minf(ESCAPE_NEED, escape_progress + delta * 20.0)
			if escape_progress >= ESCAPE_NEED:
				_end_chase_success()
				return

	# تراجع نجمة بعد بحث طويل بدون رؤية
	if _searching and _search_timer <= 0.0 and not _sighted:
		if escape_progress > 60.0:
			pass  # يفضل إنهاء بالهروب
		elif randf() < delta * 0.15:
			set_wanted(wanted_level - 1)

	_check_arrest()

func _sight_range() -> float:
	return SIGHT_CHASE if wanted_level >= 2 else SIGHT_BASE

func _ensure_chasers() -> void:
	var need := clampi(wanted_level, 1, MAX_UNITS)
	while units.size() < need and _spawn_cd <= 0.0:
		_spawn_chaser()
		_spawn_cd = 3.5

func _spawn_chaser() -> void:
	var UnitScript: GDScript = load("res://scripts/police/PoliceUnit.gd")
	if UnitScript == null or world == null or player == null:
		return
	var unit: CharacterBody3D = UnitScript.new()
	var angle := randf() * TAU
	var dist := randf_range(28.0, 48.0)
	# اعتراض أمام الحركة
	if player is CharacterBody3D and player.velocity.length() > 2.0:
		var ahead: Vector3 = player.global_position + player.velocity.normalized() * randf_range(20.0, 35.0)
		ahead.y = player.global_position.y
		unit.position = ahead
	else:
		unit.position = player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		unit.position.y = player.global_position.y
	world.add_child(unit)
	unit.setup(player, self, wanted_level)
	units.append(unit)

func _end_chase_success() -> void:
	emit_signal("chase_event", "نجحت في الاختباء — انتهت المطاردة")
	set_wanted(0)
	escape_progress = 0.0
	_in_chase = false
	_searching = false

func add_heat(amount: int = 1) -> void:
	var prev := wanted_level
	set_wanted(clampi(wanted_level + amount, 0, MAX_WANTED))
	escape_progress = maxf(0.0, escape_progress - 15.0)
	if wanted_level > 0 and prev == 0:
		emit_signal("chase_event", "المطلوبية ارتفعت!")
		_play_sfx("res://assets/audio/police_radio.wav")

func set_wanted(level: int) -> void:
	level = clampi(level, 0, MAX_WANTED)
	if level == wanted_level:
		return
	wanted_level = level
	if wanted_level > 0 and AchievementSystem:
		AchievementSystem.unlock("first_wanted")
	emit_signal("wanted_changed", wanted_level)
	if wanted_level == 0:
		_clear_chasers()
		_in_chase = false
		_searching = false
		escape_progress = 0.0
		emit_signal("chase_ended")

func report_crime(kind: String) -> void:
	match kind:
		"ram":
			add_heat(1)
		"assault":
			add_heat(1)
		"vehicle_theft":
			add_heat(1)
		"shoot":
			add_heat(2)
		"mission_crime":
			add_heat(1)
		_:
			add_heat(1)

func notify_patrol_saw_crime() -> void:
	if wanted_level == 0:
		add_heat(1)

func _check_arrest() -> void:
	if wanted_level < 2 or player == null:
		return
	for u in units:
		if not is_instance_valid(u):
			continue
		if u.get("stunned") == true:
			continue
		if u.global_position.distance_to(player.global_position) < 2.0:
			emit_signal("player_arrested")
			emit_signal("chase_event", "تم القبض عليك")
			set_wanted(0)
			var vitals := player.get_node_or_null("PlayerVitals")
			if vitals and vitals.has_method("take_damage"):
				vitals.take_damage(30.0, "arrest")
			if player.has_method("set_control_enabled"):
				player.set_control_enabled(false)
				get_tree().create_timer(2.0).timeout.connect(func():
					if is_instance_valid(player):
						player.global_position = Vector3(48, 1.5, -95)
						if player.has_method("set_control_enabled"):
							player.set_control_enabled(true)
				)
			return

func _clear_chasers() -> void:
	for u in units:
		if is_instance_valid(u):
			u.queue_free()
	units.clear()

func _play_sfx(path: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	# تشغيل محلي بسيط
	var p := AudioStreamPlayer.new()
	var stream: AudioStream = load(path)
	if stream == null:
		return
	p.stream = stream
	p.volume_db = -6.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func get_save_data() -> Dictionary:
	return {"wanted_level": wanted_level}

func load_save_data(data: Dictionary) -> void:
	if data.has("wanted_level"):
		wanted_level = clampi(int(data["wanted_level"]), 0, MAX_WANTED)


@rpc("authority", "call_local", "reliable")
func rpc_set_wanted(level: int) -> void:
	if "wanted_level" in self:
		wanted_level = clampi(level, 0, 5)
	if has_signal("wanted_changed"):
		emit_signal("wanted_changed", wanted_level)

func network_set_wanted(level: int) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("rpc_set_wanted", level)
	elif multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "server_set_wanted", level)
	else:
		if has_method("set_wanted"):
			set_wanted(level)
		elif "wanted_level" in self:
			wanted_level = level

@rpc("any_peer", "reliable")
func server_set_wanted(level: int) -> void:
	if not multiplayer.is_server():
		return
	network_set_wanted(level)
