extends StaticBody3D
## مبنى قابل للدخول — منزل اللاعب والعالم

signal player_entered(building_id: String)
signal player_exited(building_id: String)

@export var building_id: String = "building_1"
@export var building_label: String = "مبنى"
@export var interior_scene_path: String = ""
@export var interaction_distance: float = 3.5

var player_in_range: bool = false
var is_inside: bool = false
var _player: Node3D = null
var _prompt_label: Label3D = null
var _outside_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	collision_layer = 1
	var area := Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = interaction_distance
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_prompt_label = Label3D.new()
	_prompt_label.text = "اضغط E للدخول — " + building_label
	_prompt_label.font_size = 28
	_prompt_label.modulate = Color(0.92, 0.75, 0.2)
	_prompt_label.outline_size = 6
	_prompt_label.position = Vector3(0, 2.5, 0)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.visible = false
	add_child(_prompt_label)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		_player = body
		if not is_inside:
			_prompt_label.text = "اضغط E للدخول — " + building_label
			_prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body == _player and not is_inside:
		player_in_range = false
		_player = null
		_prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_inside and _player:
			_exit_building()
		elif player_in_range and not is_inside:
			_enter_building()

func _enter_building() -> void:
	if _player == null:
		return
	_outside_pos = _player.global_position
	is_inside = true
	ensure_interior()
	# موضع آمن داخل المبنى (فوق الأرضية)
	_player.global_position = global_position + Vector3(0, 0.2, 0)
	if _player.global_position.y < 0.8:
		_player.global_position.y = 1.2
	_prompt_label.text = "اضغط E للخروج — " + building_label
	_prompt_label.visible = true
	emit_signal("player_entered", building_id)
	if SaveSystem:
		SaveSystem.request_quick_save()
	print("[Enterable] دخول: ", building_label)

func _exit_building() -> void:
	if _player == null:
		return
	is_inside = false
	# خارج الباب
	var door_side := global_transform.basis.z.normalized() * 4.0
	_player.global_position = global_position + door_side + Vector3(0, 0.3, 0)
	if _player.global_position.y < 0.8:
		_player.global_position.y = 1.2
	_prompt_label.text = "اضغط E للدخول — " + building_label
	emit_signal("player_exited", building_id)
	if SaveSystem:
		SaveSystem.request_quick_save()
	print("[Enterable] خروج: ", building_label)

func ensure_interior() -> void:
	if has_node("Interior"):
		return
	var S = load("res://scripts/world/BuildingInterior.gd")
	if S == null:
		return
	var interior = S.new()
	interior.name = "Interior"
	add_child(interior)
	var theme := "house" if "home" in building_id or "house" in building_id else "shop"
	if interior.has_method("build"):
		interior.build(Vector3(6, 3, 6), theme)
