extends Control
## رسم الخريطة المصغّرة
## الجزء 2

var player: Node3D = null
var markers: Dictionary = {}
const WORLD_SIZE := 4000.0  # عرض محلي للمدينة

func setup(p_player: Node3D, p_markers: Dictionary) -> void:
	player = p_player
	markers = p_markers
	set_process(true)

func _process(_d: float) -> void:
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("get_objective_marker_pos"):
		var pos = qm.get_objective_marker_pos()
		if pos != null:
			markers["quest_marker"] = {"pos": pos, "type": "quest_marker", "label": "هدف"}
		elif markers.has("quest_marker"):
			markers.erase("quest_marker")
	queue_redraw()

func _draw() -> void:
	var s := size
	# خلفية
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.05, 0.05, 0.08, 0.85))
	# إطار ذهبي
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.85, 0.65, 0.13, 0.9), false, 2.0)
	
	# شبكة طرق مبسطة
	var step := s.x / 6.0
	for i in range(1, 6):
		var x := i * step
		draw_line(Vector2(x, 0), Vector2(x, s.y), Color(0.25, 0.25, 0.28, 0.6), 1.0)
		draw_line(Vector2(0, x), Vector2(s.x, x), Color(0.25, 0.25, 0.28, 0.6), 1.0)
	
	# علامات
	for id in markers:
		var data: Dictionary = markers[id]
		var pos: Vector3 = data.get("pos", Vector3.ZERO)
		var px := _world_to_map(pos)
		var col := _type_color(data.get("type", ""))
		draw_circle(px, 4.0, col)
	
	# موقع اللاعب
	if player and is_instance_valid(player):
		var pp := _world_to_map(player.global_position)
		draw_circle(pp, 5.0, Color(0.95, 0.85, 0.2))
		# اتجاه تقريبي
		var dir := Vector2(sin(player.rotation.y), cos(player.rotation.y)) * 8.0
		draw_line(pp, pp - dir, Color(1, 0.9, 0.3), 2.0)

func _world_to_map(world_pos: Vector3) -> Vector2:
	var nx := (world_pos.x / WORLD_SIZE) + 0.5
	var nz := (world_pos.z / WORLD_SIZE) + 0.5
	return Vector2(nx * size.x, nz * size.y)

func _type_color(t: String) -> Color:
	match t:
		"city":
			return Color(1.0, 0.85, 0.2)
		"village":
			return Color(0.5, 0.9, 0.4)
		"garage":
			return Color(0.3, 0.6, 1.0)
		"activity", "plaza":
			return Color(0.95, 0.75, 0.2)
		"quest_marker":
			return Color(1.0, 0.2, 0.2)
		"mission":
			return Color(1.0, 0.35, 0.3)
		"race":
			return Color(0.3, 1.0, 0.5)
		"shop":
			return Color(1.0, 0.6, 0.2)
		"spawn":
			return Color(0.7, 0.7, 0.7)
		_:
			return Color(0.8, 0.8, 0.8)
