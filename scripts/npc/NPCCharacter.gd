extends StaticBody3D
## شخصية غير قابلة للعب — تفاعل E
## الجزء 7

@export var npc_id: String = "npc_rashid"
@export var npc_name: String = "راشد"
@export var interact_distance: float = 3.5

var _label: Label3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	set_process(true)

func _build_visual() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.22)
	mat.metallic = 0.3
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 1.6, 0.35)
	body.mesh = box
	body.material_override = mat
	body.position.y = 0.9
	add_child(body)
	var head := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.2
	s.height = 0.4
	head.mesh = s
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.75, 0.55, 0.42)
	head.material_override = sm
	head.position.y = 1.85
	add_child(head)
	# تاج صغير ذهبي للهوية
	var crown := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.28, 0.08, 0.28)
	crown.mesh = cb
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.85, 0.65, 0.13)
	gm.metallic = 0.7
	crown.material_override = gm
	crown.position.y = 2.1
	add_child(crown)
	var col := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.3
	sh.height = 1.6
	col.shape = sh
	col.position.y = 0.9
	add_child(col)
	_label = Label3D.new()
	_label.text = npc_name + "\n[E]"
	_label.font_size = 36
	_label.modulate = Color(0.92, 0.75, 0.2)
	_label.outline_size = 5
	_label.position = Vector3(0, 2.4, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

func _process(_d: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node3D = players[0]
	var dist := global_position.distance_to(p.global_position)
	_label.modulate.a = 1.0 if dist < interact_distance * 1.5 else 0.35
	if dist <= interact_distance and Input.is_action_just_pressed("interact"):
		var qm := get_node_or_null("/root/QuestManager")
		if qm and qm.has_method("try_talk_npc"):
			qm.try_talk_npc(npc_id)
