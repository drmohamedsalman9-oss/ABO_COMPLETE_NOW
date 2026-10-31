extends Node
## تحكم القتال — هجوم قريب/بعيد + تأثيرات + ربط شرطة
## الجزء 9

signal attack_performed(weapon_id: String)
signal hit_landed(target: Node, damage: float)

var player: CharacterBody3D = null
var weapons: Node = null  # WeaponManager
var _cooldown: float = 0.0
var _invuln: float = 0.0
var combat_enabled: bool = true
var _sfx: AudioStreamPlayer3D = null

func setup(p_player: CharacterBody3D, weapon_mgr: Node) -> void:
	player = p_player
	weapons = weapon_mgr
	_sfx = AudioStreamPlayer3D.new()
	_sfx.max_distance = 30.0
	if player:
		player.add_child(_sfx)
	else:
		add_child(_sfx)
	set_process(true)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_invuln = maxf(0.0, _invuln - delta)
	if not combat_enabled or player == null:
		return
	if player.get("control_enabled") == false:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_CTRL):
		# هجوم مستمر بمعدل الـ cooldown
		try_attack()

func try_attack() -> bool:
	if not combat_enabled or player == null:
		return false
	if player.get("control_enabled") == false:
		return false
	if _cooldown > 0.0:
		return false
	if weapons == null or not weapons.can_fire():
		return false
	var def: Dictionary = weapons.get_current_def()
	if def.is_empty():
		return false
	if not weapons.consume_ammo():
		return false

	_cooldown = float(def.get("cooldown", 0.4))
	var wid := str(def.get("id", ""))
	emit_signal("attack_performed", wid)
	_play_sfx(str(def.get("sfx", "")))
	_attack_vfx(def)

	var dmg := float(def.get("damage", 10))
	var rng := float(def.get("range", 2.5))
	var wtype := str(def.get("type", "melee"))

	if wtype == "melee":
		_melee_hit(dmg, rng)
	else:
		_ranged_hit(dmg, rng)

	# جريمة: إطلاق نار يرفع المطلوب
	if wtype == "ranged":
		_report_crime_once("shoot")
	return true

func try_reload() -> void:
	if weapons:
		weapons.start_reload()

func cycle_weapon() -> void:
	if weapons:
		weapons.next_weapon()

func _melee_hit(damage: float, range_m: float) -> void:
	var origin := player.global_position + Vector3(0, 1.0, 0)
	var forward := -player.global_transform.basis.z
	# إن كان MeshRoot باتجاه مختلف
	var mesh := player.get_node_or_null("MeshRoot")
	if mesh:
		forward = -mesh.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = range_m * 0.55
	query.shape = sphere
	query.transform = Transform3D(Basis(), origin + forward * (range_m * 0.5))
	query.collision_mask = 1 | 4
	query.exclude = [player.get_rid()]
	var hits := space.intersect_shape(query, 8)
	var hit_someone := false
	for h in hits:
		var col = h.get("collider")
		if col == null or col == player:
			continue
		if _apply_damage_to(col, damage):
			hit_someone = true
	if hit_someone:
		_report_crime_once("assault")

func _ranged_hit(damage: float, range_m: float) -> void:
	var origin := player.global_position + Vector3(0, 1.4, 0)
	var mesh := player.get_node_or_null("MeshRoot")
	var forward := -player.global_transform.basis.z
	if mesh:
		forward = -mesh.global_transform.basis.z
	# أيضاً اتجاه الكاميرا إن وُجد
	var cam := player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if cam:
		forward = -cam.global_transform.basis.z
	forward = forward.normalized()
	var to := origin + forward * range_m
	var space := player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, to)
	q.exclude = [player.get_rid()]
	q.collision_mask = 1 | 4
	var hit := space.intersect_ray(q)
	if hit:
		_spawn_impact_spark(hit.position)
		var col = hit.get("collider")
		if col and _apply_damage_to(col, damage):
			pass
	_report_crime_once("shoot")

func _apply_damage_to(col: Object, damage: float) -> bool:
	# عدو
	if col.has_method("take_damage"):
		col.take_damage(damage, player)
		emit_signal("hit_landed", col, damage)
		_play_sfx("res://assets/audio/sfx_hit.wav")
		return true
	# شرطي
	if str(col.get_class()) != "" and col is Node:
		var n: Node = col
		if n.is_in_group("enemies") or n.is_in_group("police_unit"):
			if n.has_method("take_damage"):
				n.take_damage(damage, player)
				emit_signal("hit_landed", n, damage)
				return true
			# fallback stun police
			if n.has_method("stun"):
				n.stun(0.8)
				_report_crime_once("assault")
				return true
	return false

var _crime_lock: float = 0.0
func _report_crime_once(kind: String) -> void:
	# منع تكرار من ضربة واحدة كل 0.8 ث
	var now := Time.get_ticks_msec() / 1000.0
	if now - _crime_lock < 0.8:
		return
	_crime_lock = now
	var pm := get_tree().root.find_child("PoliceManager", true, false)
	if pm and pm.has_method("report_crime"):
		pm.report_crime(kind)

func _play_sfx(path: String) -> void:
	if path == "" or _sfx == null:
		return
	var s: AudioStream = load(path)
	if s:
		_sfx.stream = s
		_sfx.play()

func _attack_vfx(def: Dictionary) -> void:
	# ومضة قصيرة أمام اللاعب
	if player == null:
		return
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15 if str(def.get("type")) == "melee" else 0.08
	sphere.height = sphere.radius * 2.0
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.9, 0.4, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.8, 0.2)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat
	var forward := -player.global_transform.basis.z
	var mesh := player.get_node_or_null("MeshRoot")
	if mesh:
		forward = -mesh.global_transform.basis.z
	flash.global_position = player.global_position + Vector3(0, 1.2, 0) + forward.normalized() * 1.2
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(flash)
	get_tree().create_timer(0.12).timeout.connect(flash.queue_free)

func _spawn_impact_spark(pos: Vector3) -> void:
	var parts := CPUParticles3D.new()
	parts.emitting = true
	parts.one_shot = true
	parts.explosiveness = 1.0
	parts.amount = 10
	parts.lifetime = 0.25
	parts.initial_velocity_min = 2.0
	parts.initial_velocity_max = 6.0
	parts.global_position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.85, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.7, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	parts.material_override = mat
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(parts)
	get_tree().create_timer(0.4).timeout.connect(parts.queue_free)
