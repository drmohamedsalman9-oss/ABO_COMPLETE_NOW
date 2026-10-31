extends Node3D
## مقصورة 3D: مقاعد + طارة + لوحة + كاميرا داخلية

var steering_wheel: Node3D
var interior_cam: Camera3D
var _vehicle: Node = null
var cabin_active := false

func setup(vehicle: Node) -> void:
	_vehicle = vehicle
	for c in get_children():
		c.queue_free()
	_box(Vector3(0, 0.55, 0.1), Vector3(1.2, 0.05, 1.6), Color(0.08, 0.08, 0.1))
	_box(Vector3(-0.35, 0.75, 0.15), Vector3(0.45, 0.35, 0.5), Color(0.12, 0.1, 0.1))
	_box(Vector3(-0.35, 1.05, 0.35), Vector3(0.45, 0.45, 0.12), Color(0.12, 0.1, 0.1))
	_box(Vector3(0.35, 0.75, 0.15), Vector3(0.45, 0.35, 0.5), Color(0.12, 0.1, 0.1))
	_box(Vector3(0, 1.05, -0.55), Vector3(1.1, 0.25, 0.35), Color(0.15, 0.15, 0.18))
	_box(Vector3(0, 1.12, -0.72), Vector3(0.35, 0.12, 0.04), Color(0.85, 0.7, 0.2))
	steering_wheel = Node3D.new()
	steering_wheel.name = "SteeringWheel"
	steering_wheel.position = Vector3(-0.35, 1.05, -0.35)
	add_child(steering_wheel)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.18
	rim.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.05)
	rim.material_override = mat
	rim.rotation_degrees.x = 70.0
	steering_wheel.add_child(rim)
	interior_cam = Camera3D.new()
	interior_cam.name = "InteriorCam"
	interior_cam.position = Vector3(-0.35, 1.25, 0.55)
	interior_cam.fov = 70.0
	interior_cam.current = false
	interior_cam.rotation_degrees.x = -8.0
	add_child(interior_cam)

func _box(pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.55
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

func _process(delta: float) -> void:
	if steering_wheel == null or _vehicle == null:
		return
	var steer := 0.0
	if "steering" in _vehicle:
		steer = float(_vehicle.steering)
	steering_wheel.rotation.z = lerpf(steering_wheel.rotation.z, -steer * 0.8, delta * 8.0)

func set_interior_view(on: bool) -> void:
	cabin_active = on
	if interior_cam:
		interior_cam.current = on
