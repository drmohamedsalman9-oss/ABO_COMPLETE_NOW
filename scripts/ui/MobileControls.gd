extends CanvasLayer
## أزرار لمس أندرويد — جوستك + جري + قفز + كاميرا
## الجزء 4

@onready var joystick_base: Control = $Root/JoystickBase
@onready var joystick_knob: Control = $Root/JoystickBase/Knob
@onready var btn_sprint: Button = $Root/BtnSprint
@onready var btn_jump: Button = $Root/BtnJump
@onready var look_zone: Control = $Root/LookZone

var player: Node = null
var _joy_active: bool = false
var _joy_touch_index: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _joy_radius: float = 70.0
var _look_touch_index: int = -1
var _look_last: Vector2 = Vector2.ZERO

func setup(p_player: Node) -> void:
	player = p_player
	_joy_center = joystick_base.position + joystick_base.size * 0.5
	btn_sprint.button_down.connect(func(): _set_sprint(true))
	btn_sprint.button_up.connect(func(): _set_sprint(false))
	btn_jump.pressed.connect(_on_jump)
	# إظهار على الموبايل دائماً للتجربة أيضاً
	visible = true

func _set_sprint(v: bool) -> void:
	if player and player.has_method("set_sprint"):
		player.set_sprint(v)

func _on_jump() -> void:
	if player and player.has_method("request_jump"):
		player.request_jump()

func _input(event: InputEvent) -> void:
	if player == null:
		return
	# تعطيل إن اللاعب لا يتحكم (يقود)
	if player.get("control_enabled") == false:
		if player.has_method("set_move_input"):
			player.set_move_input(Vector2.ZERO)
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var pos: Vector2 = event.position
	if event.pressed:
		# جوستك؟
		if _in_joystick_area(pos) and _joy_touch_index < 0:
			_joy_active = true
			_joy_touch_index = event.index
			_update_joystick(pos)
		# منطقة نظر (يمين الشاشة)؟
		elif _in_look_zone(pos) and _look_touch_index < 0:
			_look_touch_index = event.index
			_look_last = pos
	else:
		if event.index == _joy_touch_index:
			_joy_active = false
			_joy_touch_index = -1
			_reset_joystick()
			if player.has_method("set_move_input"):
				player.set_move_input(Vector2.ZERO)
		if event.index == _look_touch_index:
			_look_touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joy_touch_index and _joy_active:
		_update_joystick(event.position)
	elif event.index == _look_touch_index:
		var delta: Vector2 = event.position - _look_last
		_look_last = event.position
		if player.has_method("apply_touch_look"):
			player.apply_touch_look(delta)

func _in_joystick_area(pos: Vector2) -> bool:
	var rect := joystick_base.get_global_rect()
	rect = rect.grow(40.0)
	return rect.has_point(pos)

func _in_look_zone(pos: Vector2) -> bool:
	return look_zone.get_global_rect().has_point(pos)

func _update_joystick(pos: Vector2) -> void:
	var center := joystick_base.global_position + joystick_base.size * 0.5
	var offset: Vector2 = pos - center
	if offset.length() > _joy_radius:
		offset = offset.normalized() * _joy_radius
	joystick_knob.position = joystick_base.size * 0.5 + offset - joystick_knob.size * 0.5
	var dir := offset / _joy_radius
	# تحويل: y سالب = أمام
	if player.has_method("set_move_input"):
		player.set_move_input(Vector2(dir.x, dir.y))

func _reset_joystick() -> void:
	joystick_knob.position = (joystick_base.size - joystick_knob.size) * 0.5
