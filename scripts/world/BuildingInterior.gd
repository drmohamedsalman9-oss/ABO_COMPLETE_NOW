extends Node3D
## داخل أغنى: غرف · نوافذ وهمية · أثاث

func build(size: Vector3 = Vector3(8, 3, 8), theme: String = "shop") -> void:
	for c in get_children():
		c.queue_free()
	var floor_c := Color(0.28, 0.24, 0.2) if theme == "shop" else Color(0.22, 0.22, 0.25)
	_box(Vector3(0, 0.05, 0), Vector3(size.x, 0.1, size.z), floor_c)
	var wall := Color(0.38, 0.34, 0.3)
	var h := size.y
	var t := 0.12
	_box(Vector3(0, h/2, -size.z/2), Vector3(size.x, h, t), wall)
	_box(Vector3(0, h/2, size.z/2), Vector3(size.x, h, t), wall)
	_box(Vector3(-size.x/2, h/2, 0), Vector3(t, h, size.z), wall)
	_box(Vector3(size.x/2, h/2, 0), Vector3(t, h, size.z), wall)
	# نوافذ وهمية
	for x in [-size.x*0.25, size.x*0.25]:
		_box(Vector3(x, h*0.55, -size.z/2 + 0.08), Vector3(1.2, 1.0, 0.05), Color(0.45, 0.7, 0.85, 0.5))
	# طاولة + كراسي
	_box(Vector3(0, 0.55, 0), Vector3(2.2, 0.15, 1.0), Color(0.4, 0.28, 0.15))
	_box(Vector3(0, 0.3, 0), Vector3(0.15, 0.5, 0.15), Color(0.3, 0.2, 0.12))
	for sx in [-1.0, 1.0]:
		_box(Vector3(sx * 1.3, 0.4, 0.8), Vector3(0.45, 0.5, 0.45), Color(0.2, 0.15, 0.12))
	# رف
	_box(Vector3(0, 1.4, -size.z/2 + 0.5), Vector3(size.x * 0.7, 0.08, 0.4), Color(0.35, 0.25, 0.15))
	_box(Vector3(0, 1.0, -size.z/2 + 0.5), Vector3(size.x * 0.7, 0.08, 0.4), Color(0.35, 0.25, 0.15))
	# سجادة
	_box(Vector3(0, 0.12, 0.5), Vector3(2.5, 0.04, 2.0), Color(0.55, 0.12, 0.12))
	var light := OmniLight3D.new()
	light.light_energy = 1.35
	light.omni_range = maxf(size.x, size.z) * 1.2
	light.position = Vector3(0, h - 0.25, 0)
	add_child(light)
	_box(Vector3(0, h, 0), Vector3(size.x, 0.1, size.z), Color(0.14, 0.14, 0.15))

func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.7
	if col.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
