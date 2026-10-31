extends Node
## رسوم متحركة للأطراف + صوتيات حصرية للأنيميشن
## خطوات / قفز / هبوط
## الجزء 4 محسّن

enum State { IDLE, WALK, RUN, JUMP, FALL }

var state: State = State.IDLE
var body: Node3D = null
var mesh_root: Node3D = null
var visual: Node3D = null

var _phase: float = 0.0
var _breath: float = 0.0
var _prev_state: State = State.IDLE
var _was_on_floor: bool = true
var _last_step_sign: int = 0

var _sfx: AudioStreamPlayer3D = null
var _foot_streams: Array = []
var _run_stream: AudioStream = null
var _jump_stream: AudioStream = null
var _land_stream: AudioStream = null

func setup(p_body: Node3D, p_mesh: Node3D) -> void:
	body = p_body
	mesh_root = p_mesh
	if mesh_root:
		if mesh_root.has_node("PlayerVisual"):
			visual = mesh_root.get_node("PlayerVisual")
		elif mesh_root.get_child_count() > 0:
			visual = mesh_root.get_child(0)
	_setup_sfx()

func _setup_sfx() -> void:
	_sfx = AudioStreamPlayer3D.new()
	_sfx.name = "AnimSFX"
	_sfx.max_distance = 22.0
	_sfx.volume_db = -6.0
	if body:
		body.add_child(_sfx)
	else:
		add_child(_sfx)
	for path in [
		"res://assets/audio/footstep_01.wav",
		"res://assets/audio/footstep_02.wav",
		"res://assets/audio/footstep_03.wav",
	]:
		var s: AudioStream = load(path)
		if s:
			_foot_streams.append(s)
	_run_stream = load("res://assets/audio/footstep_run.wav")
	_jump_stream = load("res://assets/audio/jump.wav")
	_land_stream = load("res://assets/audio/land.wav")

func _play(stream: AudioStream, pitch: float = 1.0, vol: float = -6.0) -> void:
	if _sfx == null or stream == null:
		return
	_sfx.stream = stream
	_sfx.pitch_scale = pitch
	_sfx.volume_db = vol
	_sfx.play()

func update_anim(delta: float, on_floor: bool, speed: float, is_sprint: bool, vertical_vel: float) -> void:
	_prev_state = state
	if not on_floor:
		state = State.JUMP if vertical_vel > 0.4 else State.FALL
	elif speed < 0.35:
		state = State.IDLE
	elif is_sprint and speed > 2.0:
		state = State.RUN
	else:
		state = State.WALK

	# —— أصوات انتقال الحالات ——
	if _prev_state != State.JUMP and state == State.JUMP:
		_play(_jump_stream, randf_range(0.95, 1.08), -5.0)
	if not _was_on_floor and on_floor and _prev_state in [State.JUMP, State.FALL]:
		_play(_land_stream, randf_range(0.9, 1.05), -4.0)
	_was_on_floor = on_floor

	_breath += delta * 2.0

	if visual == null:
		_fallback_bob(delta, speed)
		return

	var leg_l: Node3D = visual.get("leg_l")
	var leg_r: Node3D = visual.get("leg_r")
	var arm_l: Node3D = visual.get("arm_l")
	var arm_r: Node3D = visual.get("arm_r")
	var torso: Node3D = visual.get("torso")
	var head: Node3D = visual.get("head")
	var hip: Node3D = visual.get("hip")

	match state:
		State.IDLE:
			_phase = move_toward(_phase, 0.0, delta * 5.0)
			_set_limb(leg_l, 0.0, delta)
			_set_limb(leg_r, 0.0, delta)
			_set_limb(arm_l, 0.05 * sin(_breath), delta)
			_set_limb(arm_r, -0.05 * sin(_breath), delta)
			if torso:
				torso.rotation.x = lerpf(torso.rotation.x, 0.02 * sin(_breath), delta * 4.0)
				torso.position.y = lerpf(torso.position.y, 0.2 + 0.015 * sin(_breath), delta * 4.0)
			if head:
				head.rotation.x = lerpf(head.rotation.x, 0.03 * sin(_breath * 0.8), delta * 3.0)
			if hip:
				hip.position.y = lerpf(hip.position.y, 0.95, delta * 6.0)
			_last_step_sign = 0

		State.WALK:
			_phase += delta * 7.5
			var s := sin(_phase)
			_set_limb(leg_l, s * 0.55, delta * 10.0)
			_set_limb(leg_r, -s * 0.55, delta * 10.0)
			_set_limb(arm_l, -s * 0.4, delta * 10.0)
			_set_limb(arm_r, s * 0.4, delta * 10.0)
			if torso:
				torso.rotation.y = lerpf(torso.rotation.y, s * 0.06, delta * 8.0)
				torso.rotation.x = lerpf(torso.rotation.x, 0.04, delta * 6.0)
			if hip:
				hip.position.y = lerpf(hip.position.y, 0.95 + absf(cos(_phase)) * 0.03, delta * 10.0)
			_swing_shins(leg_l, leg_r, s, 0.35, delta)
			_try_footstep(s, false)

		State.RUN:
			_phase += delta * 11.5
			var s := sin(_phase)
			_set_limb(leg_l, s * 0.85, delta * 12.0)
			_set_limb(leg_r, -s * 0.85, delta * 12.0)
			_set_limb(arm_l, -s * 0.7, delta * 12.0)
			_set_limb(arm_r, s * 0.7, delta * 12.0)
			if torso:
				torso.rotation.y = lerpf(torso.rotation.y, s * 0.1, delta * 10.0)
				torso.rotation.x = lerpf(torso.rotation.x, 0.12, delta * 8.0)
			if head:
				head.rotation.x = lerpf(head.rotation.x, -0.08, delta * 6.0)
			if hip:
				hip.position.y = lerpf(hip.position.y, 0.95 + absf(cos(_phase)) * 0.06, delta * 12.0)
			_swing_shins(leg_l, leg_r, s, 0.5, delta)
			_try_footstep(s, true)

		State.JUMP:
			_set_limb(leg_l, -0.35, delta * 8.0)
			_set_limb(leg_r, -0.35, delta * 8.0)
			_set_limb(arm_l, -0.6, delta * 8.0)
			_set_limb(arm_r, -0.6, delta * 8.0)
			if torso:
				torso.rotation.x = lerpf(torso.rotation.x, -0.1, delta * 8.0)
			if hip:
				hip.position.y = lerpf(hip.position.y, 1.0, delta * 8.0)

		State.FALL:
			_set_limb(leg_l, 0.25, delta * 6.0)
			_set_limb(leg_r, 0.15, delta * 6.0)
			_set_limb(arm_l, 0.5, delta * 6.0)
			_set_limb(arm_r, 0.4, delta * 6.0)
			if torso:
				torso.rotation.x = lerpf(torso.rotation.x, 0.08, delta * 6.0)

func _try_footstep(s: float, is_run: bool) -> void:
	# عند عبور الصفر لموجة الخطوة = قدم تلمس الأرض
	var sign_now := 1 if s >= 0.0 else -1
	if sign_now != _last_step_sign and _last_step_sign != 0:
		if is_run and _run_stream:
			_play(_run_stream, randf_range(0.95, 1.12), -7.0)
		elif _foot_streams.size() > 0:
			var stream: AudioStream = _foot_streams[randi() % _foot_streams.size()]
			_play(stream, randf_range(0.92, 1.1), -8.0)
	_last_step_sign = sign_now

func _set_limb(limb: Node3D, angle_x: float, delta: float) -> void:
	if limb == null:
		return
	limb.rotation.x = lerpf(limb.rotation.x, angle_x, minf(delta, 1.0))

func _swing_shins(leg_l: Node3D, leg_r: Node3D, s: float, amount: float, delta: float) -> void:
	if leg_l and leg_l.has_node("ShinL"):
		var shin: Node3D = leg_l.get_node("ShinL")
		shin.rotation.x = lerpf(shin.rotation.x, maxf(0.0, s) * amount, delta * 10.0)
	if leg_r and leg_r.has_node("ShinR"):
		var shin: Node3D = leg_r.get_node("ShinR")
		shin.rotation.x = lerpf(shin.rotation.x, maxf(0.0, -s) * amount, delta * 10.0)

func _fallback_bob(delta: float, speed: float) -> void:
	if mesh_root == null:
		return
	if speed > 0.5:
		_phase += delta * 8.0
		mesh_root.position.y = absf(sin(_phase)) * 0.05
		_try_footstep(sin(_phase), speed > 6.0)
	else:
		mesh_root.position.y = lerpf(mesh_root.position.y, 0.0, delta * 5.0)

func get_state_name() -> String:
	match state:
		State.IDLE: return "Idle"
		State.WALK: return "Walk"
		State.RUN: return "Run"
		State.JUMP: return "Jump"
		State.FALL: return "Fall"
	return "?"
