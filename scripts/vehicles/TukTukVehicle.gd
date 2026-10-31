extends "res://scripts/vehicles/VehicleBase.gd"
## توك توك — مجسم أوضح بطابع محلي

func _ready() -> void:
	vehicle_name = "توك توك"
	vehicle_type = "tuktuk"
	max_speed = 20.0
	acceleration = 13.0
	brake_force = 28.0
	reverse_speed = 7.0
	turn_speed = 2.7
	drag = 0.5
	interact_distance = 3.2
	super._ready()
	_build_tuktuk_mesh()

func _build_tuktuk_mesh() -> void:
	if has_node("BodyRoot"):
		return
	var root := Node3D.new()
	root.name = "BodyRoot"
	add_child(root)

	var mat_yellow := StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.92, 0.72, 0.12)
	mat_yellow.metallic = 0.35
	mat_yellow.roughness = 0.4

	var mat_black := StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.08, 0.08, 0.08)

	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.7, 0.7, 0.72)
	mat_chrome.metallic = 0.85
	mat_chrome.roughness = 0.2

	var mat_green := StandardMaterial3D.new()
	mat_green.albedo_color = Color(0.15, 0.45, 0.2)

	# مقصورة الركاب
	_box(root, Vector3(0, 0.95, -0.2), Vector3(1.55, 1.3, 1.8), mat_yellow)
	# سقف
	_box(root, Vector3(0, 1.7, -0.15), Vector3(1.6, 0.1, 1.9), mat_black)
	# مقدمة السائق
	_box(root, Vector3(0, 0.85, 1.2), Vector3(1.1, 1.0, 0.9), mat_yellow)
	# غطاء محرك صغير
	_box(root, Vector3(0, 0.55, 1.7), Vector3(0.9, 0.35, 0.5), mat_green)
	# أعمدة السقف
	_box(root, Vector3(-0.7, 1.4, 0.5), Vector3(0.08, 0.6, 0.08), mat_chrome)
	_box(root, Vector3(0.7, 1.4, 0.5), Vector3(0.08, 0.6, 0.08), mat_chrome)
	_box(root, Vector3(-0.7, 1.4, -0.9), Vector3(0.08, 0.6, 0.08), mat_chrome)
	_box(root, Vector3(0.7, 1.4, -0.9), Vector3(0.08, 0.6, 0.08), mat_chrome)
	# زينة ذهبية
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.85, 0.65, 0.13)
	mat_gold.metallic = 0.7
	_box(root, Vector3(0, 1.05, 1.65), Vector3(1.0, 0.08, 0.08), mat_gold)

	# 3 عجلات
	for pos in [Vector3(-0.75, 0.28, -0.7), Vector3(0.75, 0.28, -0.7), Vector3(0, 0.28, 1.45)]:
		var wheel := _make_wheel(pos, mat_black, mat_chrome)
		root.add_child(wheel)
		register_wheel(wheel)

	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.55, 1.55, 2.75)
		col.shape = shape
		col.position.y = 0.85
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
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.28
	cyl.height = 0.18
	tire_m.mesh = cyl
	tire_m.rotation.z = PI * 0.5
	tire_m.material_override = tire
	pivot.add_child(tire_m)
	var rim_m := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.12
	rc.bottom_radius = 0.12
	rc.height = 0.2
	rim_m.mesh = rc
	rim_m.rotation.z = PI * 0.5
	rim_m.material_override = rim
	pivot.add_child(rim_m)
	return pivot
