extends Node3D
## تفاصيل شارع: أعمدة · حواجز · إشارات بسيطة

func _ready() -> void:
	_ring_of_poles(Vector3(0, 0, 0), 35, 10)
	_ring_of_poles(Vector3(40, 0, 0), 25, 8)
	_ring_of_poles(Vector3(-40, 0, 20), 20, 6)
	_barriers()
	_benches()
	_trash_bins()

func _ring_of_poles(center: Vector3, radius: float, count: int) -> void:
	for i in range(count):
		var a := TAU * float(i) / float(count)
		var pos := center + Vector3(cos(a) * radius, 0, sin(a) * radius)
		_pole(pos)
		_sign(pos + Vector3(1.2, 0, 0))

func _pole(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.07
	c.bottom_radius = 0.09
	c.height = 4.5
	mi.mesh = c
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.2)
	mi.material_override = mat
	mi.position = pos + Vector3(0, 2.25, 0)
	add_child(mi)
	var light := OmniLight3D.new()
	light.light_energy = 0.45
	light.omni_range = 10.0
	light.position = pos + Vector3(0, 4.4, 0)
	add_child(light)

func _sign(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.8, 0.5, 0.05)
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.15, 0.12)
	mi.material_override = mat
	mi.position = pos + Vector3(0, 2.8, 0)
	add_child(mi)

func _barriers() -> void:
	for x in [-15, 15]:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.3, 0.8, 4.0)
		mi.mesh = b
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.45, 0.05)
		mi.material_override = mat
		mi.position = Vector3(x, 0.4, 20)
		add_child(mi)


func _benches() -> void:
	for i in range(6):
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.4, 0.35, 0.45)
		mi.mesh = b
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.18, 0.12)
		mi.material_override = mat
		mi.position = Vector3(-20 + i * 8, 0.25, 18)
		add_child(mi)

func _trash_bins() -> void:
	for i in range(5):
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.25
		c.bottom_radius = 0.28
		c.height = 0.7
		mi.mesh = c
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.35, 0.18)
		mi.material_override = mat
		mi.position = Vector3(10 + i * 6, 0.35, -15)
		add_child(mi)


func set_lights_enabled(on: bool) -> void:
	for c in get_children():
		if c is OmniLight3D:
			(c as OmniLight3D).visible = on
			(c as OmniLight3D).light_energy = 0.45 if on else 0.0
