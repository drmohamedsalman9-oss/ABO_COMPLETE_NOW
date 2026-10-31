extends CanvasLayer
## واجهة الركوب والقيادة — أندرويد + لوحة مفاتيح
## الجزء 3

@onready var btn_enter: Button = $Root/BtnEnter
@onready var btn_exit: Button = $Root/BtnExit
@onready var drive_panel: Control = $Root/DrivePanel
@onready var btn_left: Button = $Root/DrivePanel/BtnLeft
@onready var btn_right: Button = $Root/DrivePanel/BtnRight
@onready var btn_accel: Button = $Root/DrivePanel/BtnAccel
@onready var btn_brake: Button = $Root/DrivePanel/BtnBrake
@onready var hint_label: Label = $Root/HintLabel

var vehicle_manager: Node = null
var steer: float = 0.0
var throttle: float = 0.0
var _left_down := false
var _right_down := false
var _accel_down := false
var _brake_down := false

func setup(vm: Node) -> void:
	vehicle_manager = vm
	if vehicle_manager:
		if vehicle_manager.has_signal("target_changed"):
			vehicle_manager.target_changed.connect(_on_target_changed)
		if vehicle_manager.has_signal("vehicle_entered"):
			vehicle_manager.vehicle_entered.connect(_on_entered)
		if vehicle_manager.has_signal("vehicle_exited"):
			vehicle_manager.vehicle_exited.connect(_on_exited)
	btn_enter.visible = false
	btn_exit.visible = false
	drive_panel.visible = false
	btn_enter.pressed.connect(_on_enter_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	# أزرار اللمس
	btn_left.button_down.connect(func(): _left_down = true)
	btn_left.button_up.connect(func(): _left_down = false)
	btn_right.button_down.connect(func(): _right_down = true)
	btn_right.button_up.connect(func(): _right_down = false)
	btn_accel.button_down.connect(func(): _accel_down = true)
	btn_accel.button_up.connect(func(): _accel_down = false)
	btn_brake.button_down.connect(func(): _brake_down = true)
	btn_brake.button_up.connect(func(): _brake_down = false)

func _on_target_changed(v: Node) -> void:
	if vehicle_manager and vehicle_manager.is_driving:
		btn_enter.visible = false
		return
	btn_enter.visible = v != null
	if v and v.has_method("get_display_name"):
		btn_enter.text = "اركب — " + v.get_display_name()
	else:
		btn_enter.text = "اركب"

func _on_entered(_v: Node) -> void:
	btn_enter.visible = false
	btn_exit.visible = true
	drive_panel.visible = true
	hint_label.text = "قيادة: أسهم / WASD أو الأزرار | F أو انزل للخروج"

func _on_exited(_v: Node) -> void:
	btn_exit.visible = false
	drive_panel.visible = false
	steer = 0.0
	throttle = 0.0
	hint_label.text = "اقترب من أي مركبة واضغط اركب"

func _on_enter_pressed() -> void:
	if vehicle_manager:
		vehicle_manager.try_enter()
			if AchievementSystem:
				AchievementSystem.unlock("first_drive")

func _on_exit_pressed() -> void:
	if vehicle_manager:
		vehicle_manager.try_exit()

func _process(_delta: float) -> void:
	if vehicle_manager == null:
		return
	# لوحة مفاتيح
	if vehicle_manager.is_driving:
		var s := 0.0
		var t := 0.0
		if Input.is_action_pressed("move_left") or _left_down:
			s -= 1.0
		if Input.is_action_pressed("move_right") or _right_down:
			s += 1.0
		if Input.is_action_pressed("move_forward") or _accel_down:
			t += 1.0
		if Input.is_action_pressed("move_back") or _brake_down:
			t -= 1.0
		steer = s
		throttle = t
		vehicle_manager.set_drive_input(steer, throttle)
		# خروج بـ F أو interact
		if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_F):
			# تجنب التعارض: فقط إذا لم يُضغط للتو
			pass
	else:
		# ركوب بـ E
		if Input.is_action_just_pressed("interact") and btn_enter.visible:
			vehicle_manager.try_enter()
	
	# خروج بمفتاح F
	if vehicle_manager.is_driving and Input.is_physical_key_pressed(KEY_F):
		if Input.is_action_just_pressed("interact") == false:
			# استخدم إطار واحد
			pass

var _f_was := false
func _input(event: InputEvent) -> void:
	if vehicle_manager == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F and vehicle_manager.is_driving:
			vehicle_manager.try_exit()
