extends StaticBody3D
## علامة عقار قابل للشراء / مملوك

@export var property_id: String = "house_garage"
var _label: Label3D

func _ready() -> void:
	_build()
	set_process(true)

func _build() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.08)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4, 3, 4)
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position.y = 1.5
	add_child(mesh)
	var roof := MeshInstance3D.new()
	var r := BoxMesh.new()
	r.size = Vector3(4.5, 0.3, 4.5)
	roof.mesh = r
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.75, 0.6, 0.15)
	gm.metallic = 0.5
	roof.material_override = gm
	roof.position.y = 3.2
	add_child(roof)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(4, 3, 4)
	col.shape = sh
	col.position.y = 1.5
	add_child(col)
	_label = Label3D.new()
	_label.font_size = 32
	_label.modulate = Color(0.92, 0.75, 0.2)
	_label.position = Vector3(0, 4.0, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_update_label()

func _process(_d: float) -> void:
	_update_label()
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node3D = players[0]
	if global_position.distance_to(p.global_position) < 4.0 and Input.is_action_just_pressed("interact"):
		var eco := get_node_or_null("/root/EconomyManager")
		if eco == null:
			return
		if eco.owns_property(property_id):
			if eco.has_signal("purchase_failed"):
				pass
			# إشعار
			var qm := get_node_or_null("/root/QuestManager")
			if qm and qm.has_signal("notification"):
				qm.emit_signal("notification", "هذا عقارك ✓")
		else:
			eco.buy_property(property_id)

func _update_label() -> void:
	var eco := get_node_or_null("/root/EconomyManager")
	if eco and eco.owns_property(property_id):
		_label.text = "🏠 مملوك\n[E]"
	else:
		_label.text = "🏠 للبيع\n[E]"
