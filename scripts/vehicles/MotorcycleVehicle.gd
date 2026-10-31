extends "res://scripts/vehicles/VehicleBase.gd"
## موتوسيكل — مجسم أوضح

func _ready() -> void:
	vehicle_name = "موتوسيكل"
	vehicle_type = "motorcycle"
	max_speed = 38.0
	acceleration = 24.0
	brake_force = 32.0
	reverse_speed = 6.0
	turn_speed = 3.2
	drag = 0.25
	interact_distance = 2.8
	super._ready()
	_build_bike_mesh()

func _build_bike_mesh() -> void:
	if has_node("BodyRoot"):
		return
	var root := Node3D.new()
	root.name = "BodyRoot"
	add_child(root)

	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.65, 0.12, 0.1)
	mat_red.metallic = 0.5
	mat_red.roughness = 0.35

	var mat_black := StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.06, 0.06, 0.06)
	mat_black.roughness = 0.6

	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.8, 0.8, 0.82)
	mat_chrome.metallic = 0.95
	mat_chrome.roughness = 0.12

	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.85, 0.65, 0.13)
	mat_gold.metallic = 0.7

	# خزان
	_box(root, Vector3(0, 0.7, 0.15), Vector3(0.4, 0.35, 0.9), mat_red)
	# مقعد
	_box(root, Vector3(0, 0.75, -0.45), Vector3(0.35, 0.18, 0.55), mat_black)
	# هيكل سفلي
	_box(root, Vector3(0, 0.45, 0), Vector3(0.3, 0.2, 1.5), mat_chrome)
	# محرك
	_box(root, Vector3(0, 0.4, 0.2), Vector3(0.35, 0.3, 0.4), mat_chrome)
	# مقود
	_box(root, Vector3(0, 1.0, 0.55), Vector3(0.7, 0.08, 0.08), mat_chrome)
	_box(root, Vector3(0, 0.9, 0.55), Vector3(0.08, 0.25, 0.08), mat_chrome)
	# خط ذهبي
	_box(root, Vector3(0, 0.72, 0.3), Vector3(0.42, 0.05, 0.15), mat_gold)

	for wz in [-0.65, 0.7]:
		var wheel := _make_wheel(Vector3(0, 0.3, wz), mat_black, mat_chrome)
		root.add_child(wheel)
		register_wheel(wheel)

	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.55, 1.05, 1.85)
		col.shape = shape
		col.position.y = 0.52
		add_child(col)

func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _make_wheel(pos: Vector3, tire: Material, rim: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	var tire_m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.14
	tire_m.mesh = cyl
	tire_m.rotation.z = PI * 0.5
	tire_m.material_override = tire
	pivot.add_child(tire_m)
	var rim_m := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.14
	rc.bottom_radius = 0.14
	rc.height = 0.16
	rim_m.mesh = rc
	rim_m.rotation.z = PI * 0.5
	rim_m.material_override = rim
	pivot.add_child(rim_m)
	return pivot
