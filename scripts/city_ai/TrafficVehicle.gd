extends CharacterBody3D
## مركبة مرور — تتبع مسار طريق · توقف عند عائق

var route: Array = []
var route_i: int = 0
var speed: float = 8.0
var _wait: float = 0.0
var _slow: float = 1.0

func setup(p_route: Array) -> void:
	route = p_route
	route_i = 0
	speed = randf_range(6.5, 11.0)
	add_to_group("traffic")
	_build()
	collision_layer = 1
	collision_mask = 1

func _build() -> void:
	var kinds := ["sedan", "suv", "taxi", "van", "sports"]
	var model: Node3D = null
	var AL = load("res://scripts/core/AssetLibrary.gd")
	if AL:
		model = AL.make_car(kinds[randi() % kinds.size()])
	if model:
		add_child(model)
	else:
		var colors := [Color(0.6, 0.6, 0.65), Color(0.2, 0.25, 0.4), Color(0.5, 0.15, 0.12), Color(0.15, 0.4, 0.2)]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[randi() % colors.size()]
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.7, 0.85, 3.6)
		body.mesh = box
		body.material_override = mat
		body.position.y = 0.5
		add_child(body)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.7, 0.85, 3.6)
	col.shape = sh
	col.position.y = 0.5
	add_child(col)

func _physics_process(delta: float) -> void:
	if route.is_empty():
		return
	if _wait > 0.0:
		_wait -= delta
		velocity = velocity.move_toward(Vector3.ZERO, 15.0 * delta)
		move_and_slide()
		return
	var target: Vector3 = route[route_i]
	var to := target - global_position
	to.y = 0.0
	if to.length() < 3.0:
		route_i = (route_i + 1) % route.size()
		if randf() < 0.15:
			_wait = randf_range(0.5, 1.5)  # إشارة / توقف
		return
	# تجنب بسيط: لو في عائق أمامي أبطئ
	_slow = 1.0
	var dir := to.normalized()
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 0.5, 0)
	var ahead := from + dir * 6.0
	var q := PhysicsRayQueryParameters3D.create(from, ahead)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit:
		_slow = 0.2
		if hit.position.distance_to(global_position) < 3.5:
			_wait = 0.4
	velocity.x = dir.x * speed * _slow
	velocity.z = dir.z * speed * _slow
	velocity.y -= 15.0 * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 3.0)
	move_and_slide()
