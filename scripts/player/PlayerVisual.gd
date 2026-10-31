extends Node3D
## شخصية مفصّلة بأطراف قابلة للتحريك (هيكل منطقي)
## تاج أبو كردوم — أسود وذهبي
## الجزء 4 محسّن

## عقد الأطراف — يحرّكها PlayerAnimation
var hip: Node3D
var torso: Node3D
var head: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var crown: Node3D

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()

	var mat_black := _mat(Color(0.07, 0.07, 0.09), 0.35, 0.45)
	var mat_gold := _mat(Color(0.88, 0.68, 0.12), 0.28, 0.8)
	var mat_skin := _mat(Color(0.78, 0.58, 0.45), 0.8, 0.0)
	var mat_dark := _mat(Color(0.04, 0.04, 0.05), 0.45, 0.25)
	var mat_cloth := _mat(Color(0.1, 0.1, 0.12), 0.5, 0.2)
	var mat_boot := _mat(Color(0.05, 0.05, 0.05), 0.6, 0.1)

	# —— جذر الورك ——
	hip = Node3D.new()
	hip.name = "Hip"
	hip.position = Vector3(0, 0.95, 0)
	add_child(hip)

	# حوض
	_box(hip, Vector3(0, 0, 0), Vector3(0.42, 0.22, 0.28), mat_cloth)

	# —— رجل يسار ——
	leg_l = Node3D.new()
	leg_l.name = "LegL"
	leg_l.position = Vector3(-0.14, -0.05, 0)
	hip.add_child(leg_l)
	_box(leg_l, Vector3(0, -0.28, 0), Vector3(0.16, 0.5, 0.18), mat_dark)  # فخذ
	var shin_l := Node3D.new()
	shin_l.name = "ShinL"
	shin_l.position = Vector3(0, -0.55, 0)
	leg_l.add_child(shin_l)
	_box(shin_l, Vector3(0, -0.2, 0), Vector3(0.14, 0.42, 0.16), mat_dark)
	_box(shin_l, Vector3(0, -0.42, 0.06), Vector3(0.16, 0.1, 0.28), mat_boot)

	# —— رجل يمين ——
	leg_r = Node3D.new()
	leg_r.name = "LegR"
	leg_r.position = Vector3(0.14, -0.05, 0)
	hip.add_child(leg_r)
	_box(leg_r, Vector3(0, -0.28, 0), Vector3(0.16, 0.5, 0.18), mat_dark)
	var shin_r := Node3D.new()
	shin_r.name = "ShinR"
	shin_r.position = Vector3(0, -0.55, 0)
	leg_r.add_child(shin_r)
	_box(shin_r, Vector3(0, -0.2, 0), Vector3(0.14, 0.42, 0.16), mat_dark)
	_box(shin_r, Vector3(0, -0.42, 0.06), Vector3(0.16, 0.1, 0.28), mat_boot)

	# —— جذع ——
	torso = Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 0.2, 0)
	hip.add_child(torso)
	# جاكيت
	_box(torso, Vector3(0, 0.35, 0), Vector3(0.5, 0.65, 0.3), mat_black)
	# ياقة ذهبية
	_box(torso, Vector3(0, 0.65, 0.12), Vector3(0.48, 0.08, 0.08), mat_gold)
	# خطوط ذهبية
	_box(torso, Vector3(0, 0.4, 0.16), Vector3(0.42, 0.05, 0.03), mat_gold)
	_box(torso, Vector3(0, 0.25, 0.16), Vector3(0.38, 0.035, 0.03), mat_gold)
	# شعار تاج على الصدر
	_box(torso, Vector3(0, 0.5, 0.17), Vector3(0.1, 0.09, 0.03), mat_gold)
	# أكتاف
	_box(torso, Vector3(-0.32, 0.55, 0), Vector3(0.18, 0.14, 0.22), mat_black)
	_box(torso, Vector3(0.32, 0.55, 0), Vector3(0.18, 0.14, 0.22), mat_black)

	# —— ذراع يسار ——
	arm_l = Node3D.new()
	arm_l.name = "ArmL"
	arm_l.position = Vector3(-0.4, 0.5, 0)
	torso.add_child(arm_l)
	_box(arm_l, Vector3(0, -0.22, 0), Vector3(0.13, 0.4, 0.13), mat_black)
	var forearm_l := Node3D.new()
	forearm_l.name = "ForearmL"
	forearm_l.position = Vector3(0, -0.45, 0)
	arm_l.add_child(forearm_l)
	_box(forearm_l, Vector3(0, -0.15, 0), Vector3(0.11, 0.32, 0.11), mat_black)
	_box(forearm_l, Vector3(0, -0.32, 0), Vector3(0.1, 0.1, 0.1), mat_skin)

	# —— ذراع يمين ——
	arm_r = Node3D.new()
	arm_r.name = "ArmR"
	arm_r.position = Vector3(0.4, 0.5, 0)
	torso.add_child(arm_r)
	_box(arm_r, Vector3(0, -0.22, 0), Vector3(0.13, 0.4, 0.13), mat_black)
	var forearm_r := Node3D.new()
	forearm_r.name = "ForearmR"
	forearm_r.position = Vector3(0, -0.45, 0)
	arm_r.add_child(forearm_r)
	_box(forearm_r, Vector3(0, -0.15, 0), Vector3(0.11, 0.32, 0.11), mat_black)
	_box(forearm_r, Vector3(0, -0.32, 0), Vector3(0.1, 0.1, 0.1), mat_skin)

	# —— رأس ——
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.78, 0)
	torso.add_child(head)
	var head_mesh := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.18
	hs.height = 0.36
	head_mesh.mesh = hs
	head_mesh.material_override = mat_skin
	head.add_child(head_mesh)
	# شعر
	_box(head, Vector3(0, 0.14, 0), Vector3(0.34, 0.12, 0.34), mat_dark)
	# عينان بسيطة
	_box(head, Vector3(-0.07, 0.02, 0.15), Vector3(0.05, 0.03, 0.02), mat_dark)
	_box(head, Vector3(0.07, 0.02, 0.15), Vector3(0.05, 0.03, 0.02), mat_dark)

	# —— تاج أبو كردوم ——
	crown = Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0, 0.28, 0)
	head.add_child(crown)
	_box(crown, Vector3(0, 0, 0), Vector3(0.32, 0.09, 0.32), mat_gold)
	for i in range(5):
		var a := (float(i) / 5.0) * TAU - PI * 0.5
		var x := cos(a) * 0.12
		var z := sin(a) * 0.12
		var h := 0.13 if i % 2 == 0 else 0.09
		_box(crown, Vector3(x, 0.1, z), Vector3(0.05, h, 0.05), mat_gold)
	var gem := MeshInstance3D.new()
	var gs := SphereMesh.new()
	gs.radius = 0.045
	gs.height = 0.09
	gem.mesh = gs
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.75, 0.08, 0.12)
	gm.emission_enabled = true
	gm.emission = Color(0.55, 0.05, 0.08)
	gm.emission_energy_multiplier = 1.0
	gem.material_override = gm
	gem.position = Vector3(0, 0.16, 0)
	crown.add_child(gem)

func _mat(c: Color, r: float, m: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = r
	mat.metallic = m
	return mat

# نموذج Kenney اختياري فوق الهيكل المنطقي (هوية اللاعب تبقى التاج الذهبي)
func attach_kenney_body() -> void:
	var AL = load("res://scripts/core/AssetLibrary.gd")
	if AL == null:
		return
	var model: Node3D = AL.make_character("male_a")
	if model == null:
		return
	model.name = "KenneyBody"
	model.position = Vector3(0, 0, 0)
	# إخفاء الصناديق الأساسية اختيارياً — نبقي التاج
	add_child(model)

func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
