extends Node
## إدارة حيوية المدينة — مشاة · مرور · كثافة أداء
## الجزء 11 | أبو كردوم

enum Density { LOW, MEDIUM, HIGH }

signal density_changed(level: int)

var player: Node3D = null
var world: Node = null
var density: int = Density.MEDIUM
var pedestrians: Array = []
var traffic: Array = []
var max_peds: int = 12
var max_traffic: int = 8
var spawn_radius: float = 80.0
var despawn_radius: float = 120.0
var _spawn_cd: float = 0.0
var _logic_t: float = 0.0
var enabled: bool = true

# مسارات مبسطة حول المركز (أرصفة / طرق)
var walk_paths: Array = []  # Array of Array[Vector3]
var road_routes: Array = []  # Array of Array[Vector3]

func setup(p_player: Node3D, p_world: Node) -> void:
	player = p_player
	world = p_world
	_build_paths()
	if SettingsManager:
		var q := int(SettingsManager.get_setting("graphics", "quality", 1))
		density = clampi(q, 0, 2)
		if SettingsManager.has_signal("quality_changed"):
			SettingsManager.quality_changed.connect(set_density)
	_apply_density(density)
	set_process(true)
	print("[CityAI] كثافة=", density, " مشاة<=", max_peds, " مرور<=", max_traffic)

func set_density(level: int) -> void:
	density = clampi(level, 0, 2)
	_apply_density(density)
	emit_signal("density_changed", density)

func _apply_density(level: int) -> void:
	match level:
		Density.LOW:
			max_peds = 4
			max_traffic = 2
		Density.MEDIUM:
			max_peds = 8
			max_traffic = 5
		Density.HIGH:
			max_peds = 14
			max_traffic = 8

func _build_paths() -> void:
	# حلقات مشي حول الميدان والجراج
	walk_paths = [
		_rect_path(Vector3(0, 0.1, 0), 30, 30),
		_rect_path(Vector3(50, 0.1, -90), 25, 20),
		_rect_path(Vector3(-40, 0.1, 40), 35, 25),
		_rect_path(Vector3(100, 0.1, 20), 20, 40),
	]
	road_routes = [
		_line_route(Vector3(-80, 0.3, 0), Vector3(80, 0.3, 0)),
		_line_route(Vector3(0, 0.3, -100), Vector3(0, 0.3, 100)),
		_line_route(Vector3(-60, 0.3, -60), Vector3(60, 0.3, 60)),
		_line_route(Vector3(40, 0.3, -80), Vector3(40, 0.3, 80)),
		_rect_path(Vector3(20, 0.3, -20), 50, 50),
	]

func _rect_path(center: Vector3, half_w: float, half_d: float) -> Array:
	return [
		center + Vector3(-half_w, 0, -half_d),
		center + Vector3(half_w, 0, -half_d),
		center + Vector3(half_w, 0, half_d),
		center + Vector3(-half_w, 0, half_d),
	]

func _line_route(a: Vector3, b: Vector3) -> Array:
	return [a, b, a]  # ذهاب وعودة

func _process(delta: float) -> void:
	if not enabled or player == null or world == null:
		return
	# تشغيل منطق الذكاء كل 0.25ث بدل كل إطار
	_logic_t += delta
	_spawn_cd -= delta
	if _logic_t < 0.25:
		return
	_logic_t = 0.0
	pedestrians = pedestrians.filter(func(p): return is_instance_valid(p))
	traffic = traffic.filter(func(t): return is_instance_valid(t))
	_cull_far(pedestrians, despawn_radius)
	_cull_far(traffic, despawn_radius)
	if _spawn_cd <= 0.0:
		_spawn_cd = 1.8 if density == 0 else (1.2 if density == 1 else 0.9)
		if pedestrians.size() < max_peds:
			_spawn_ped()
		if traffic.size() < max_traffic:
			_spawn_traffic()

func _cull_far(arr: Array, radius: float) -> void:
	var keep: Array = []
	for n in arr:
		if not is_instance_valid(n):
			continue
		if n.global_position.distance_to(player.global_position) > radius:
			n.queue_free()
		else:
			keep.append(n)
	arr.clear()
	arr.append_array(keep)

func _spawn_ped() -> void:
	if walk_paths.is_empty():
		return
	var PedScript: GDScript = load("res://scripts/city_ai/PedestrianAI.gd")
	if PedScript == null:
		return
	var path: Array = walk_paths[randi() % walk_paths.size()]
	var start: Vector3 = path[randi() % path.size()]
	# فقط قرب اللاعب تقريباً
	if player.global_position.distance_to(start) > spawn_radius * 1.2:
		start = player.global_position + Vector3(randf_range(-40, 40), 0.1, randf_range(-40, 40))
	var ped: CharacterBody3D = PedScript.new()
	ped.position = start
	world.add_child(ped)
	ped.setup(path, player)
	pedestrians.append(ped)

func _spawn_traffic() -> void:
	if road_routes.is_empty():
		return
	var TrafScript: GDScript = load("res://scripts/city_ai/TrafficVehicle.gd")
	if TrafScript == null:
		return
	var route: Array = road_routes[randi() % road_routes.size()]
	var start: Vector3 = route[0]
	if player.global_position.distance_to(start) > spawn_radius * 1.5:
		# أقرب نقطة على المسار للاعب
		start = route[0]
	var car: CharacterBody3D = TrafScript.new()
	car.position = start
	world.add_child(car)
	car.setup(route)
	traffic.append(car)
