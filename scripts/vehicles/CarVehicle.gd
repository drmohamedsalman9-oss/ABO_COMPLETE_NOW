extends "res://scripts/vehicles/VehicleBase.gd"
## سيارة — مجسم أوضح + فيزياء من القاعدة

func _ready() -> void:
	vehicle_name = "سيارة"
	vehicle_type = "car"
	max_speed = 34.0
	acceleration = 17.0
	brake_force = 42.0
	reverse_speed = 11.0
	turn_speed = 2.1
	drag = 0.4
	super._ready()
	_build_car_mesh()

func _build_car_mesh() -> void:
	# محاولة تحميل نموذج Kenney CC0
	var kind := "sedan"
	if vehicle_name.to_lower().contains("police") or str(get("is_police")) == "true":
		kind = "police"
	var model: Node3D = null
	if ResourceLoader.exists("res://scripts/core/AssetLibrary.gd"):
		var AL = load("res://scripts/core/AssetLibrary.gd")
		if AL:
			model = AL.make_car(kind)
	if model:
		var root := Node3D.new()
		root.name = "VisualRoot"
		add_child(root)
		model.position = Vector3(0, 0, 0)
		root.add_child(model)
		# عجلات منطقية للدوران حتى مع نموذج جاهز
		for wz in [-1.2, 1.2]:
			for wx in [-0.75, 0.75]:
				var w := Node3D.new()
				w.position = Vector3(wx, 0.35, wz)
				root.add_child(w)
				register_wheel(w)
		return
	# —— نموذج تركيبي احتياطي ——
	if has_node("BodyRoot"):
		return
	var root := Node3D.new()
	root.name = "BodyRoot"
	add_child(root)

	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.12, 0.14, 0.18)
	mat_body.metallic = 0.55
	mat_body.roughness = 0.3

	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.25, 0.4, 0.55, 0.55)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.05
	mat_glass.metallic = 0.2

	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.85, 0.65, 0.13)
	mat_gold.metallic = 0.8
	mat_gold.roughness = 0.25

	var mat_black := StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.05, 0.05, 0.05)
	mat_black.roughness = 0.7

	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.75, 0.75, 0.78)
	mat_chrome.metallic = 0.9
	mat_chrome.roughness = 0.15

	# هيكل سفلي
	_box(root, Vector3(0, 0.45, 0), Vector3(2.05, 0.55, 4.4), mat_body)
	# غطاء محرك
	_box(root, Vector3(0, 0.75, 1.35), Vector3(1.95, 0.25, 1.3), mat_body)
	# صندوق خلفي
	_box(root, Vector3(0, 0.7, -1.5), Vector3(1.95, 0.3, 1.0), mat_body)
	# مقصورة
	_box(root, Vector3(0, 1.15, -0.15), Vector3(1.75, 0.75, 2.1), mat_body)
	# زجاج أمامي
	_box(root, Vector3(0, 1.2, 0.95), Vector3(1.6, 0.55, 0.12), mat_glass)
	# زجاج خلفي
	_box(root, Vector3(0, 1.2, -1.15), Vector3(1.6, 0.5, 0.1), mat_glass)
	# خط ذهبي
	_box(root, Vector3(0, 0.72, 1.55), Vector3(2.08, 0.06, 0.25), mat_gold)
	# مصابيح أمامية
	_box(root, Vector3(-0.7, 0.55, 2.15), Vector3(0.35, 0.2, 0.12), mat_chrome)
	_box(root, Vector3(0.7, 0.55, 2.15), Vector3(0.35, 0.2, 0.12), mat_chrome)
	# مصابيح خلفية
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.7, 0.1, 0.08)
	mat_red.emission_enabled = true
	mat_red.emission = Color(0.5, 0.05, 0.02)
	mat_red.emission_energy_multiplier = 0.6
	_box(root, Vector3(-0.7, 0.55, -2.15), Vector3(0.35, 0.18, 0.1), mat_red)
	_box(root, Vector3(0.7, 0.55, -2.15), Vector3(0.35, 0.18, 0.1), mat_red)
	# مرايا
	_box(root, Vector3(-1.1, 1.0, 0.6), Vector3(0.15, 0.12, 0.25), mat_chrome)
	_box(root, Vector3(1.1, 1.0, 0.6), Vector3(0.15, 0.12, 0.25), mat_chrome)

	# عجلات
	for wx in [-0.95, 0.95]:
		for wz in [-1.35, 1.35]:
			var wheel := _make_wheel(Vector3(wx, 0.32, wz), mat_black, mat_chrome)
			root.add_child(wheel)
			register_wheel(wheel)

	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.05, 1.15, 4.3)
		col.shape = shape
		col.position.y = 0.6
		add_child(col)

func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _make_wheel(pos: Vector3, tire: Material, rim: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	var tire_m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.36
	cyl.bottom_radius = 0.36
	cyl.height = 0.28
	tire_m.mesh = cyl
	tire_m.rotation.z = PI * 0.5
	tire_m.material_override = tire
	pivot.add_child(tire_m)
	var rim_m := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.18
	rc.bottom_radius = 0.18
	rc.height = 0.3
	rim_m.mesh = rc
	rim_m.rotation.z = PI * 0.5
	rim_m.material_override = rim
	pivot.add_child(rim_m)
	return pivot
