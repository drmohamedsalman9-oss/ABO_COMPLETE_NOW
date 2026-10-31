extends CharacterBody3D
## دورية شرطة — تتجول وتكشف اللاعب عند المطلوبية/الجرائم القريبة

var mgr: Node = null
var home: Vector3 = Vector3.ZERO
var _waypoints: Array[Vector3] = []
var _wi: int = 0
var speed: float = 5.5
var _wait: float = 0.0

func setup(p_mgr: Node, origin: Vector3) -> void:
	mgr = p_mgr
	home = origin
	_waypoints = [
		origin,
		origin + Vector3(40, 0, 0),
		origin + Vector3(40, 0, 40),
		origin + Vector3(0, 0, 40),
	]
	_build()

func _build() -> void:
	# سيارة شرطة مبسطة
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.12, 0.35)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.8, 0.9, 3.8)
	body.mesh = box
	body.material_override = mat
	body.position.y = 0.55
	add_child(body)
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.4, 1.0)
	light.light_energy = 0.8
	light.omni_range = 5.0
	light.position = Vector3(0, 1.2, 0)
	light.name = "PatrolLight"
	add_child(light)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.8, 0.9, 3.8)
	col.shape = sh
	col.position.y = 0.55
	add_child(col)
	var lab := Label3D.new()
	lab.text = "دورية"
	lab.font_size = 24
	lab.modulate = Color(0.5, 0.6, 1.0)
	lab.position = Vector3(0, 1.8, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lab)

func _physics_process(delta: float) -> void:
	if _waypoints.is_empty():
		return
	if _wait > 0.0:
		_wait -= delta
		velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
		move_and_slide()
		return
	var target: Vector3 = _waypoints[_wi]
	var to := target - global_position
	to.y = 0.0
	if to.length() < 3.0:
		_wi = (_wi + 1) % _waypoints.size()
		_wait = randf_range(1.0, 2.5)
		return
	var dir := to.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y -= 15.0 * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 4.0)
	move_and_slide()
	var pl := get_node_or_null("PatrolLight")
	if pl:
		pl.light_energy = 0.5 + absf(sin(Time.get_ticks_msec() * 0.005)) * 0.6

func can_see_player(player: Node3D, range_m: float) -> bool:
	if player == null:
		return false
	var d := global_position.distance_to(player.global_position)
	if d > range_m:
		return false
	# مجال رؤية أمامي تقريباً
	var forward := -transform.basis.z
	var to_p := (player.global_position - global_position).normalized()
	if forward.dot(to_p) < 0.15:
		return false
	return true
