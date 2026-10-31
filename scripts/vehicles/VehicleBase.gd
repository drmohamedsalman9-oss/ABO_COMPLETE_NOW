extends CharacterBody3D
## قاعدة المركبات — فيزياء قيادة + اصطدام محسّن
## مملكة الصحاب — الجزء 3
## محمد ماهر | Mohammed Maher

class_name VehicleBase

signal entered(driver: Node3D)
signal exited(driver: Node3D)
signal collided(impact_speed: float, normal: Vector3)

@export var vehicle_name: String = "مركبة"
@export var vehicle_type: String = "car"
@export var max_speed: float = 32.0
@export var acceleration: float = 22.0
@export var brake_force: float = 42.0
@export var reverse_speed: float = 10.0
@export var turn_speed: float = 2.55
@export var lateral_grip: float = 11.0
@export var friction: float = 6.0
@export var drag: float = 0.35
@export var interact_distance: float = 3.0

## اصطدام
@export var impact_damping: float = 0.55
@export var min_impact_speed: float = 3.0
@export var wall_slide_friction: float = 0.85
@export var bounce_factor: float = 0.15
@export var collision_safe_margin: float = 0.08

var driver: Node3D = null
var is_occupied: bool = false
var steer_input: float = 0.0
var handbrake_input: float = 0.0
var boost_cooldown: float = 0.0
var drift_factor: float = 0.0
var throttle_input: float = 0.0
var current_speed: float = 0.0

var _engine_player: AudioStreamPlayer3D = null
var _wheel_meshes: Array[Node3D] = []
var _body_tilt: float = 0.0
var _last_collision_time: float = 0.0
	var _impact_player: AudioStreamPlayer3D = null
	var _sfx_player: AudioStreamPlayer3D = null

const ENGINE_IDLE := "res://assets/audio/engine_idle.wav"
const ENGINE_LOOP := "res://assets/audio/engine_loop.wav"
const ENGINE_HIGH := "res://assets/audio/engine_high.wav"

func _ready() -> void:
	add_to_group("vehicles")
	collision_layer = 4
	collision_mask = 1 | 4  # عالم + مركبات أخرى
	floor_snap_length = 0.2
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = collision_safe_margin
	motion_mode = MOTION_MODE_GROUNDED
	wall_min_slide_angle = deg_to_rad(15.0)
	_setup_engine_audio()
	_setup_impact_audio()
	_build_visual_if_needed()

func _build_visual_if_needed() -> void:
	ensure_cabin()
	pass

func _setup_engine_audio() -> void:
	_engine_player = AudioStreamPlayer3D.new()
	_engine_player.name = "EngineAudio"
	_engine_player.bus = "Master"
	_engine_player.max_distance = 40.0
	_engine_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_engine_player.volume_db = -8.0
	add_child(_engine_player)
	var stream: AudioStream = load(ENGINE_IDLE)
	if stream:
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_engine_player.stream = stream


func _setup_impact_audio() -> void:
	_impact_player = AudioStreamPlayer3D.new()
	_impact_player.name = "ImpactAudio"
	_impact_player.max_distance = 50.0
	_impact_player.volume_db = -2.0
	add_child(_impact_player)
	_sfx_player = AudioStreamPlayer3D.new()
	_sfx_player.name = "VehicleSFX"
	_sfx_player.max_distance = 30.0
	_sfx_player.volume_db = -4.0
	add_child(_sfx_player)

func _start_engine() -> void:
	if _engine_player and _engine_player.stream:
		_engine_player.play()
		_engine_player.pitch_scale = 0.85

func _stop_engine() -> void:
	if _engine_player:
		_engine_player.stop()

func _update_engine_sound() -> void:
	if _engine_player == null or not is_occupied:
		return
	if not _engine_player.playing:
		_engine_player.play()
	var ratio := clampf(absf(current_speed) / maxf(max_speed, 1.0), 0.0, 1.0)
	_engine_player.pitch_scale = lerpf(0.85, 1.55, ratio)
	_engine_player.volume_db = lerpf(-12.0, -2.0, ratio)
	if ratio > 0.65:
		_maybe_swap_stream(ENGINE_HIGH)
	elif ratio > 0.15:
		_maybe_swap_stream(ENGINE_LOOP)
	else:
		_maybe_swap_stream(ENGINE_IDLE)

func _maybe_swap_stream(path: String) -> void:
	if _engine_player == null:
		return
	var cur := _engine_player.stream
	var want: AudioStream = load(path)
	if want == null or cur == want:
		return
	var pos := _engine_player.get_playback_position()
	if want is AudioStreamWAV:
		want.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_engine_player.stream = want
	_engine_player.play(pos)

func can_enter(player: Node3D) -> bool:
	if is_occupied or driver != null:
		return false
	if player == null or not is_instance_valid(player):
		return false
	if global_position.distance_to(player.global_position) > interact_distance:
		return false
	var space := get_world_3d().direct_space_state
	if space:
		var query := PhysicsRayQueryParameters3D.create(
			player.global_position + Vector3(0, 1.0, 0),
			global_position + Vector3(0, 0.5, 0)
		)
		query.exclude = [player.get_rid(), get_rid()]
		var hit := space.intersect_ray(query)
		if hit and hit.collider != self and hit.collider is StaticBody3D:
			return false
	return true

func enter_vehicle(player: Node3D) -> bool:
	if not can_enter(player):
		return false
	driver = player
	is_occupied = true
	open_doors()
	player.set_physics_process(false)
	player.set_process_input(false)
	if player is CharacterBody3D:
		player.velocity = Vector3.ZERO
	if player.get_parent():
		player.get_parent().remove_child(player)
	add_child(player)
	# وضعية جلوس السائق (مرئي داخل المقصورة)
	player.visible = true
	player.position = Vector3(-0.35, 0.55, 0.15)
	player.rotation = Vector3(0, 0, 0)
	ensure_cabin()
	# إغلاق الأبواب بعد لحظة
	get_tree().create_timer(0.45).timeout.connect(close_doors)
	_start_engine()
	_play_sfx("res://assets/audio/vehicle_enter.wav")
	emit_signal("entered", player)
	return true

func exit_vehicle() -> Node3D:
	if not is_occupied or driver == null:
		return null
	var p := driver
	driver = null
	is_occupied = false
	open_doors()
	_stop_engine()
	var exit_pos := global_position + transform.basis.x * 2.3 + Vector3(0, 0.6, 0)
	if p.get_parent() == self:
		remove_child(p)
	var world := get_tree().current_scene
	if world:
		world.add_child(p)
	p.global_position = exit_pos
	p.visible = true
	p.set_physics_process(true)
	p.set_process_input(true)
	if p is CharacterBody3D:
		p.velocity = Vector3.ZERO
	emit_signal("exited", p)
	return p

func set_drive_input(steer: float, throttle: float, handbrake: float = 0.0) -> void:
	steer_input = clampf(steer, -1.0, 1.0)
	throttle_input = clampf(throttle, -1.0, 1.0)
	handbrake_input = clampf(handbrake, 0.0, 1.0)
	# Shift = دفع قصير
	if Input.is_key_pressed(KEY_SHIFT) and boost_cooldown <= 0.0 and is_occupied:
		current_speed = minf(current_speed + 8.0, max_speed * 1.15)
		boost_cooldown = 2.5


func _physics_process(delta: float) -> void:
	if boost_cooldown > 0.0:
		boost_cooldown -= delta
	var gravity := 24.0

	if not is_occupied:
		current_speed = move_toward(current_speed, 0.0, friction * 1.8 * delta)
		_integrate_motion(delta, gravity)
		return

	# تسارع / فرامل
	if throttle_input > 0.05:
		var accel_factor := 1.0 - clampf(absf(current_speed) / max_speed, 0.0, 0.85)
		current_speed += acceleration * accel_factor * throttle_input * delta
		current_speed = minf(current_speed, max_speed)
	elif throttle_input < -0.05:
		if current_speed > 0.4:
			current_speed -= brake_force * absf(throttle_input) * delta
		else:
			current_speed -= acceleration * 0.55 * absf(throttle_input) * delta
			current_speed = maxf(current_speed, -reverse_speed)
	else:
		var traction := 1.0 if is_on_floor() else 0.15
		var resist := (friction + drag * absf(current_speed)) * (1.0 + (1.0 - traction))
		current_speed = move_toward(current_speed, 0.0, resist * delta)
	# فرامل يد / انزلاق خفيف
	if handbrake_input > 0.2 and absf(current_speed) > 2.0:
		current_speed = move_toward(current_speed, 0.0, brake_force * 1.4 * handbrake_input * delta)
		drift_factor = move_toward(drift_factor, handbrake_input * absf(steer_input), delta * 3.0)
		if absf(steer_input) > 0.1:
			rotate_y(steer_input * turn_speed * 1.35 * delta * signf(current_speed) if absf(current_speed) > 0.01 else 0.0)
	else:
		drift_factor = move_toward(drift_factor, 0.0, delta * 2.5)

	# توجيه
	if absf(current_speed) > 0.35:
		var speed_factor := clampf(absf(current_speed) / 10.0, 0.25, 1.0)
		var turn := steer_input * turn_speed * speed_factor * delta
		if current_speed < 0.0:
			turn = -turn
		rotate_y(turn)
		_body_tilt = move_toward(_body_tilt, -steer_input * 0.09 * speed_factor, delta * 3.0)
	else:
		_body_tilt = move_toward(_body_tilt, 0.0, delta * 4.0)

	_integrate_motion(delta, gravity)
	_spin_wheels(delta)
	_apply_body_tilt()
	_update_engine_sound()

func _integrate_motion(delta: float, gravity: float) -> void:
	var forward := -transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3(0, 0, -1)
	else:
		forward = forward.normalized()

	# سرعة أفقية مرغوبة
	var desired := forward * current_speed
	# تماسك جانبي: يقلل الانزلاق العرضي
	var lateral := velocity - forward * velocity.dot(forward)
	lateral.y = 0.0
	velocity.x = desired.x - lateral.x * clampf(lateral_grip * delta, 0.0, 1.0)
	velocity.z = desired.z - lateral.z * clampf(lateral_grip * delta, 0.0, 1.0)
	if not is_on_floor():
		# تحكم أقل في الهواء
		velocity.x = move_toward(velocity.x, desired.x, delta * 2.0)
		velocity.z = move_toward(velocity.z, desired.z, delta * 2.0)

	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	else:
		velocity.y -= gravity * delta

	var pre_vel := velocity
	move_and_slide()

	# —— معالجة الاصطدام ——
	_handle_collisions(pre_vel, delta)

func _handle_collisions(pre_vel: Vector3, delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var hit_wall := false
	var strongest_impact := 0.0
	# damage hook below after loop
	var impact_normal := Vector3.ZERO

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n: Vector3 = col.get_normal()
		# تجاهل الأرض تقريباً
		if n.y > 0.55:
			continue

		hit_wall = true
		var rel := pre_vel.dot(-n)  # سرعة الاقتراب من السطح
		if rel > strongest_impact:
			strongest_impact = rel
			impact_normal = n

		# انزلاق على الجدار: إزالة مركبة السرعة داخل الجدار
		var vn := velocity.dot(n)
		if vn < 0.0:
			velocity -= n * vn  # إسقاط المركبة العمودية
			# احتكاك جانبي خفيف
			velocity.x *= wall_slide_friction
			velocity.z *= wall_slide_friction

	if hit_wall and strongest_impact > min_impact_speed:
		# تخميد السرعة الاتجاهية بعد الاصطدام
		var loss := impact_damping * clampf(strongest_impact / max_speed, 0.2, 1.0)
		current_speed *= (1.0 - loss)
		# ارتداد بسيط
		if bounce_factor > 0.0 and impact_normal.length_squared() > 0.01:
			var bounce := impact_normal * strongest_impact * bounce_factor
			velocity.x += bounce.x
			velocity.z += bounce.z
			# عكس جزء من السرعة الاتجاهية إذا كان الاصطدام شبه مباشر
			var fwd := -transform.basis.z
			fwd.y = 0.0
			fwd = fwd.normalized()
			var head_on := absf(fwd.dot(-impact_normal))
			if head_on > 0.7:
				current_speed *= -0.25  # ارتداد خفيف للخلف

		if now - _last_collision_time > 0.15:
			_last_collision_time = now
			apply_crash_damage(strongest_impact)
			emit_signal("collided", strongest_impact, impact_normal)
			if strongest_impact > 8.0:
				var pm := get_node_or_null("/root/PoliceManager")
				if pm == null:
					pm = get_tree().root.find_child("PoliceManager", true, false)
				if pm and pm.has_method("report_crime"):
					pm.report_crime("ram")
			_on_impact_feedback(strongest_impact, impact_normal)

	# مزامنة current_speed مع السرعة الأفقية الفعلية بعد الانزلاق
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var fwd2 := -transform.basis.z
	fwd2.y = 0.0
	fwd2 = fwd2.normalized()
	var signed := flat.dot(fwd2)
	# لا تفرض السرعة إلا إذا كان الفرق كبيراً (بعد اصطدام)
	if hit_wall:
		current_speed = lerpf(current_speed, signed, 0.65)

	# منع الاهتزاز داخل الجدار
	if get_slide_collision_count() > 0 and absf(current_speed) < 0.8:
		current_speed = move_toward(current_speed, 0.0, 15.0 * delta)

func _on_impact_feedback(impact_speed: float, normal: Vector3 = Vector3.UP) -> void:
	_body_tilt += clampf(impact_speed * 0.012, 0.0, 0.14) * (1.0 if randf() > 0.5 else -1.0)
	if _engine_player and is_occupied:
		_engine_player.pitch_scale = maxf(0.7, _engine_player.pitch_scale - 0.15)
	var strength := clampf(impact_speed / maxf(max_speed, 1.0), 0.12, 1.0)
	_spawn_advanced_impact_vfx(impact_speed, normal, strength)
	_play_impact_sound(strength)
	if strength > 0.55 and absf(steer_input) > 0.3:
		_play_sfx("res://assets/audio/tire_screech.wav", -6.0)

func _play_impact_sound(strength: float) -> void:
	if _impact_player == null:
		return
	var path := "res://assets/audio/impact_light.wav"
	if strength > 0.7:
		path = "res://assets/audio/impact_heavy.wav"
	elif strength > 0.35:
		path = "res://assets/audio/impact_medium.wav"
	var stream: AudioStream = load(path)
	if stream:
		_impact_player.stream = stream
		_impact_player.pitch_scale = randf_range(0.9, 1.1)
		_impact_player.volume_db = lerpf(-8.0, 0.0, strength)
		_impact_player.play()

func _play_sfx(path: String, vol_db: float = -4.0) -> void:
	if _sfx_player == null:
		return
	var stream: AudioStream = load(path)
	if stream:
		_sfx_player.stream = stream
		_sfx_player.volume_db = vol_db
		_sfx_player.play()

func _spawn_advanced_impact_vfx(impact_speed: float, normal: Vector3, strength: float) -> void:
	var hit_pos := global_position + Vector3(0, 0.55, 0) - normal * 0.9
	_vfx_sparks(hit_pos, normal, strength)
	_vfx_debris(hit_pos, normal, strength)
	_vfx_smoke(hit_pos, normal, strength)
	if strength > 0.4:
		_vfx_flash(hit_pos, strength)
	if strength > 0.65:
		_vfx_shockwave(hit_pos, strength)

func _vfx_sparks(pos: Vector3, normal: Vector3, strength: float) -> void:
	var p := CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = int(lerpf(12, 40, strength))
	p.lifetime = 0.4
	p.direction = normal
	p.spread = 60.0
	p.initial_velocity_min = lerpf(4.0, 12.0, strength)
	p.initial_velocity_max = lerpf(8.0, 20.0, strength)
	p.gravity = Vector3(0, -15, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.1)
	mat.emission_energy_multiplier = 3.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = mat
	p.global_position = pos
	_add_temp(p, 0.7)

func _vfx_debris(pos: Vector3, normal: Vector3, strength: float) -> void:
	var p := CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.88
	p.amount = int(lerpf(5, 16, strength))
	p.lifetime = 0.6
	p.direction = normal + Vector3(0, 0.5, 0)
	p.spread = 50.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = lerpf(4.0, 9.0, strength)
	p.gravity = Vector3(0, -18, 0)
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.22
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.32, 0.28)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = mat
	p.global_position = pos
	_add_temp(p, 0.9)

func _vfx_smoke(pos: Vector3, normal: Vector3, strength: float) -> void:
	var p := CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.7
	p.amount = int(lerpf(8, 24, strength))
	p.lifetime = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = lerpf(2.0, 5.0, strength)
	p.gravity = Vector3(0, 0.5, 0)
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.55
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.48, 0.45, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = mat
	p.global_position = pos + Vector3(0, 0.15, 0)
	_add_temp(p, 1.2)

func _vfx_flash(pos: Vector3, strength: float) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = lerpf(0.3, 0.9, strength)
	sphere.height = sphere.radius * 2.0
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.92, 0.55, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.3)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat
	flash.global_position = pos
	get_tree().current_scene.add_child(flash)
	var tw := get_tree().create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tw.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, 0.2)
	tw.tween_callback(flash.queue_free)

func _vfx_shockwave(pos: Vector3, strength: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.15
	torus.outer_radius = 0.35
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.7, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.4)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	ring.global_position = pos + Vector3(0, 0.2, 0)
	ring.rotation.x = PI * 0.5
	get_tree().current_scene.add_child(ring)
	var tw := get_tree().create_tween()
	tw.tween_property(ring, "scale", Vector3(lerpf(3.0, 7.0, strength), 1.0, lerpf(3.0, 7.0, strength)), 0.3)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(ring.queue_free)

func _add_temp(node: Node, lifetime: float) -> void:
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(node)
	else:
		add_child(node)
	get_tree().create_timer(lifetime).timeout.connect(node.queue_free)

func _spin_wheels(delta: float) -> void:
	var spin := current_speed * 1.8 * delta
	for w in _wheel_meshes:
		if is_instance_valid(w):
			w.rotate_x(spin)

func _apply_body_tilt() -> void:
	var body := get_node_or_null("BodyRoot")
	if body:
		body.rotation.z = _body_tilt

func get_display_name() -> String:
	return vehicle_name

func register_wheel(node: Node3D) -> void:
	_wheel_meshes.append(node)


func apply_damage_visual_ratio(ratio: float) -> void:
	var t := clampf(ratio, 0.0, 1.0)
	var dirty := Color(0.2, 0.15, 0.12)
	for mi in find_children("*", "MeshInstance3D", true, false):
		if mi is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = dirty.lerp(Color(0.6, 0.6, 0.65), t)
			mat.metallic = 0.3
			mi.material_override = mat


var cabin: Node3D = null

func ensure_cabin() -> void:
	if cabin and is_instance_valid(cabin):
		return
	var S = load("res://scripts/vehicles/VehicleCabin.gd")
	if S == null:
		return
	cabin = S.new()
	cabin.name = "Cabin"
	add_child(cabin)
	cabin.setup(self)

func toggle_interior_camera() -> void:
	ensure_cabin()
	if cabin and cabin.has_method("set_interior_view"):
		cabin.set_interior_view(not cabin.cabin_active)


# —— أبواب + جلوس + تلف مرئي ——
var door_l: Node3D = null
var door_r: Node3D = null
var _doors_open := false
var _damage_level := 0.0

func ensure_doors() -> void:
	if door_l and is_instance_valid(door_l):
		return
	door_l = _make_door(Vector3(-0.95, 0.7, 0.1), "DoorL")
	door_r = _make_door(Vector3(0.95, 0.7, 0.1), "DoorR")

func _make_door(pos: Vector3, nm: String) -> Node3D:
	var root := Node3D.new()
	root.name = nm
	root.position = pos
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.08, 0.85, 1.1)
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.14)
	mat.metallic = 0.5
	mat.roughness = 0.35
	mi.material_override = mat
	root.add_child(mi)
	add_child(root)
	return root

func open_doors() -> void:
	ensure_doors()
	_doors_open = true
	if door_l:
		door_l.rotation.y = deg_to_rad(-55)
	if door_r:
		door_r.rotation.y = deg_to_rad(55)

func close_doors() -> void:
	_doors_open = false
	if door_l:
		door_l.rotation.y = 0.0
	if door_r:
		door_r.rotation.y = 0.0

func apply_crash_damage(impact: float) -> void:
	_damage_level = clampf(_damage_level + impact * 0.02, 0.0, 1.0)
	_update_damage_visuals()

func _update_damage_visuals() -> void:
	var dirt := Color(0.25, 0.18, 0.12)
	var t := _damage_level
	for mi in find_children("*", "MeshInstance3D", true, false):
		if not (mi is MeshInstance3D):
			continue
		var mat := StandardMaterial3D.new()
		var base := Color(0.55, 0.55, 0.58)
		if mi.material_override is StandardMaterial3D:
			base = (mi.material_override as StandardMaterial3D).albedo_color
		mat.albedo_color = base.lerp(dirt, t * 0.85)
		mat.metallic = 0.25 * (1.0 - t)
		mat.roughness = 0.35 + t * 0.5
		mi.material_override = mat
