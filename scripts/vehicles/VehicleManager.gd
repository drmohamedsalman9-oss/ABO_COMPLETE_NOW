extends Node
## مدير المركبات — اكتشاف الأقرب + ركوب/نزول
## الجزء 3 — مملكة الصحاب

signal target_changed(vehicle: Node)
signal vehicle_entered(vehicle: Node)
signal vehicle_exited(vehicle: Node)

@export var default_interact_distance: float = 3.0

var player: Node3D = null
var current_vehicle: Node = null  # المركبة التي يقودها اللاعب
var target_vehicle: Node = null   # أقرب مركبة للركوب
var is_driving: bool = false

func setup(p_player: Node3D) -> void:
	player = p_player
	print("[VehicleManager] جاهز")

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if is_driving:
		target_vehicle = null
		return
	_update_nearest_vehicle()

func _update_nearest_vehicle() -> void:
	var nearest: Node = null
	var nearest_dist := 9999.0
	for v in get_tree().get_nodes_in_group("vehicles"):
		if v == null or not is_instance_valid(v):
			continue
		if not v.has_method("can_enter"):
			continue
		if not v.can_enter(player):
			continue
		var d: float = player.global_position.distance_to(v.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = v
	if nearest != target_vehicle:
		target_vehicle = nearest
		emit_signal("target_changed", target_vehicle)

func try_enter() -> bool:
	if is_driving or player == null:
		return false
	_update_nearest_vehicle()
	if target_vehicle == null:
		return false
	if target_vehicle.has_method("enter_vehicle"):
		if target_vehicle.enter_vehicle(player):
			current_vehicle = target_vehicle
			is_driving = true
			target_vehicle = null
			emit_signal("vehicle_entered", current_vehicle)
			return true
	return false

func try_exit() -> bool:
	if not is_driving or current_vehicle == null:
		return false
	if current_vehicle.has_method("exit_vehicle"):
		var p = current_vehicle.exit_vehicle()
		if p:
			player = p
		is_driving = false
		var exited := current_vehicle
		current_vehicle = null
		emit_signal("vehicle_exited", exited)
		return true
	return false

func set_drive_input(steer: float, throttle: float) -> void:
	if is_driving and current_vehicle and current_vehicle.has_method("set_drive_input"):
		current_vehicle.set_drive_input(steer, throttle, 1.0 if Input.is_key_pressed(KEY_SPACE) else 0.0)

func get_target_name() -> String:
	if target_vehicle and target_vehicle.has_method("get_display_name"):
		return target_vehicle.get_display_name()
	return ""
