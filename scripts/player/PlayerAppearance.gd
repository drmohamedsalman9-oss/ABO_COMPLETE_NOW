extends Node
## تخصيص ألوان بسيط للملابس (على النموذج التركيبي)

var jacket := Color(0.07, 0.07, 0.09)
var pants := Color(0.05, 0.05, 0.06)
var accent := Color(0.88, 0.68, 0.12)

var presets := {
	"ملكي": {"jacket": Color(0.07, 0.07, 0.09), "pants": Color(0.05, 0.05, 0.06), "accent": Color(0.88, 0.68, 0.12)},
	"أحمر": {"jacket": Color(0.45, 0.08, 0.08), "pants": Color(0.1, 0.1, 0.12), "accent": Color(0.9, 0.7, 0.2)},
	"أبيض": {"jacket": Color(0.85, 0.85, 0.88), "pants": Color(0.15, 0.15, 0.18), "accent": Color(0.88, 0.68, 0.12)},
	"أزرق": {"jacket": Color(0.1, 0.15, 0.35), "pants": Color(0.05, 0.05, 0.08), "accent": Color(0.7, 0.7, 0.75)},
}

func apply_preset(name: String, visual: Node) -> void:
	if not presets.has(name) or visual == null:
		return
	var p: Dictionary = presets[name]
	jacket = p["jacket"]
	pants = p["pants"]
	accent = p["accent"]
	_recolor(visual)

func _recolor(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat := StandardMaterial3D.new()
		var nm := str(mi.name).to_lower()
		if "gold" in nm or "crown" in nm or "accent" in nm:
			mat.albedo_color = accent
			mat.metallic = 0.8
		elif "leg" in nm or "pant" in nm or "boot" in nm:
			mat.albedo_color = pants
		else:
			mat.albedo_color = jacket
		mat.roughness = 0.45
		mi.material_override = mat
	for c in n.get_children():
		_recolor(c)


func add_simple_accessory(visual: Node, kind: String = "crown") -> void:
	if visual == null:
		return
	var existing = visual.get_node_or_null("Accessory_%s" % kind)
	if existing:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Accessory_%s" % kind
	if kind == "crown":
		var b := BoxMesh.new()
		b.size = Vector3(0.35, 0.12, 0.35)
		mi.mesh = b
		mi.position = Vector3(0, 1.85, 0)
	elif kind == "glasses":
		var b := BoxMesh.new()
		b.size = Vector3(0.28, 0.06, 0.08)
		mi.mesh = b
		mi.position = Vector3(0, 1.55, 0.18)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent
	mat.metallic = 0.85
	mi.material_override = mat
	visual.add_child(mi)
