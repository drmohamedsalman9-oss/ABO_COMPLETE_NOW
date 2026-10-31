extends Node3D
## طقس بسيط: صحو · مطر · ضباب (جسيمات + Environment)
## مناسب لأندرويد — كثافة قابلة للضبط

enum Weather { CLEAR, RAIN, FOG }
var current: Weather = Weather.CLEAR
var _particles: GPUParticles3D
var _timer := 0.0
var auto_cycle := true
var cycle_seconds := 180.0

func _ready() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "Rain"
	_particles.amount = 400
	_particles.visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 30, 80))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.1, -1, 0.05)
	mat.spread = 8.0
	mat.initial_velocity_min = 6.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.05
	_particles.process_material = mat
	var dm := BoxMesh.new()
	dm.size = Vector3(0.02, 0.12, 0.02)
	_particles.draw_pass_1 = dm
	_particles.emitting = false
	add_child(_particles)
	set_weather(Weather.CLEAR)

func _process(delta: float) -> void:
	if player_follow():
		pass
	if not auto_cycle:
		return
	_timer += delta
	if _timer >= cycle_seconds:
		_timer = 0.0
		set_weather((int(current) + 1) % 3)

func player_follow() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p and p is Node3D and _particles:
		_particles.global_position = (p as Node3D).global_position + Vector3(0, 12, 0)

func set_weather(w: Weather) -> void:
	current = w
	if _particles:
		_particles.emitting = (w == Weather.RAIN)
		_particles.amount = 500 if w == Weather.RAIN else 50
	var env_node := get_tree().root.find_child("WorldEnvironment", true, false)
	# ضبط خفيف للضباب عبر environment إن وُجد
	var sun := get_tree().root.find_child("DirectionalLight3D", true, false)
	if sun and sun is DirectionalLight3D:
		match w:
			Weather.CLEAR:
				(sun as DirectionalLight3D).light_energy = 1.1
			Weather.RAIN:
				(sun as DirectionalLight3D).light_energy = 0.55
			Weather.FOG:
				(sun as DirectionalLight3D).light_energy = 0.4
	print("[Weather] ", ["صحو", "مطر", "ضباب"][int(w)])

func toggle_rain() -> void:
	if current == Weather.RAIN:
		set_weather(Weather.CLEAR)
	else:
		set_weather(Weather.RAIN)
