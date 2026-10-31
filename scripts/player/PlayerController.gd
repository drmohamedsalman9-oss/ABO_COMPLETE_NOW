extends CharacterBody3D
## تحكم اللاعب الكامل — حركة + كاميرا + تكامل مركبات
## الجزء 4 | مملكة الصحاب / أبو كردوم
## محمد ماهر

@export var walk_speed: float = 5.5
@export var run_speed: float = 9.5
@export var sprint_speed: float = 13.5
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var jump_velocity: float = 5.2
@export var rotation_speed: float = 12.0
@export var mouse_sensitivity: float = 0.0028
@export var touch_sensitivity: float = 0.006
@export var camera_min_pitch: float = -60.0
@export var camera_max_pitch: float = 45.0
@export var camera_distance: float = 5.0
@export var camera_height: float = 2.2

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var mesh_root: Node3D = $MeshRoot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var gravity: float = 18.0
var is_sprinting: bool = false
var move_input: Vector2 = Vector2.ZERO  # من لوحة أو جوستك
var look_input: Vector2 = Vector2.ZERO
var control_enabled: bool = true
var _anim: Node = null
var _yaw: float = 0.0
var _pitch: float = -10.0

func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.06
	collision_layer = 2
	collision_mask = 1 | 4  # عالم + مركبات

	# بناء الشكل إن لم يكن
	if mesh_root and mesh_root.get_child_count() == 0:
		var VisualScript: GDScript = load("res://scripts/player/PlayerVisual.gd")
		var visual: Node3D = VisualScript.new()
		visual.name = "PlayerVisual"
		mesh_root.add_child(visual)

	# رسوم متحركة
	var AnimScript: GDScript = load("res://scripts/player/PlayerAnimation.gd")
	_anim = AnimScript.new()
	_anim.name = "PlayerAnimation"
	add_child(_anim)
	if _anim.has_method("setup"):
		_anim.setup(self, mesh_root)

	# SpringArm للكاميرا
	if spring_arm:
		spring_arm.spring_length = camera_distance
		spring_arm.collision_mask = 1
		spring_arm.margin = 0.2

	if not GameManager.is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	print("[PlayerController] الجزء 4 جاهز")

func _physics_process(delta: float) -> void:
	if not control_enabled:
		return

	# جاذبية
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.5

	# قفز
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# إدخال الحركة (لوحة + جوستك خارجي عبر move_input)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_input.length() > 0.05:
		input_dir = move_input

	is_sprinting = Input.is_key_pressed(KEY_SHIFT) or is_sprinting
	# is_sprinting يمكن ضبطه من زر الجري في الموبايل

	var target_speed := walk_speed
	if input_dir.length() > 0.7 and is_sprinting:
		target_speed = sprint_speed
	elif input_dir.length() > 0.15:
		target_speed = run_speed if is_sprinting else walk_speed

	# اتجاه بالنسبة للكاميرا
	var cam_basis := camera_pivot.global_transform.basis if camera_pivot else transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	var direction := (forward * -input_dir.y + right * input_dir.x)
	if direction.length() > 1.0:
		direction = direction.normalized()

	var target_vel := direction * target_speed
	if direction.length() > 0.05:
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
		# دوران الجسم نحو الحركة
		var look_dir := Vector3(velocity.x, 0.0, velocity.z)
		if look_dir.length() > 0.3:
			var target_angle := atan2(look_dir.x, look_dir.z)
			var mesh_yaw := mesh_root.rotation.y if mesh_root else 0.0
			# ندور MeshRoot وليس الجسم كله (الكاميرا مستقلة)
			if mesh_root:
				mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_angle - rotation.y, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	move_and_slide()

	# رسوم متحركة
	var flat_speed := Vector3(velocity.x, 0, velocity.z).length()
	if _anim and _anim.has_method("update_anim"):
		_anim.update_anim(delta, is_on_floor(), flat_speed, is_sprinting, velocity.y)

func _input(event: InputEvent) -> void:
	if not control_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)
	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_look(yaw_delta: float, pitch_delta: float) -> void:
	rotate_y(yaw_delta)
	if camera_pivot:
		camera_pivot.rotate_x(pitch_delta)
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x,
			deg_to_rad(camera_min_pitch),
			deg_to_rad(camera_max_pitch)
		)

## يُستدعى من MobileControls
func set_move_input(vec: Vector2) -> void:
	move_input = vec.limit_length(1.0)

func set_sprint(active: bool) -> void:
	is_sprinting = active

func apply_touch_look(relative: Vector2) -> void:
	if not control_enabled:
		return
	_apply_look(-relative.x * touch_sensitivity, -relative.y * touch_sensitivity)

func request_jump() -> void:
	if control_enabled and is_on_floor():
		velocity.y = jump_velocity

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		velocity = Vector3.ZERO
		move_input = Vector2.ZERO
		is_sprinting = false

func get_save_data() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
		"rotation_y": rotation.y
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var p: Dictionary = data["position"]
		global_position = Vector3(p.get("x", 0), p.get("y", 1.5), p.get("z", 0))
	if data.has("rotation_y"):
		rotation.y = data["rotation_y"]
