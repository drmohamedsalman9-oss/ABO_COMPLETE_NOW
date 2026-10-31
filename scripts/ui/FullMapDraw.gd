extends Control
## رسم الخريطة الكاملة

var player: Node3D = null
var markers: Dictionary = {}
var map_range: float = 4000.0
var destination = null

func setup(p_player: Node3D, p_markers: Dictionary, p_range: float = 4000.0) -> void:
	player = p_player
	markers = p_markers
	map_range = p_range

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.06, 0.06, 0.09, 0.95))
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.85, 0.65, 0.15, 0.9), false, 2.0)
	# شبكة
	for i in range(1, 8):
		var x := s.x * i / 8.0
		draw_line(Vector2(x, 0), Vector2(x, s.y), Color(0.2, 0.2, 0.25, 0.5), 1.0)
		draw_line(Vector2(0, x), Vector2(s.x, x), Color(0.2, 0.2, 0.25, 0.5), 1.0)
	for id in markers:
		var data: Dictionary = markers[id]
		var pos: Vector3 = data.get("pos", Vector3.ZERO)
		var px := _w2m(pos)
		var col := _color(str(data.get("type", "")))
		draw_circle(px, 5.0, col)
	if destination != null:
		var dp := _w2m(destination)
		draw_circle(dp, 7.0, Color(1, 0.2, 0.2))
		draw_arc(dp, 10.0, 0, TAU, 16, Color(1, 0.4, 0.3), 2.0)
	if player and is_instance_valid(player):
		var pp := _w2m(player.global_position)
		draw_circle(pp, 6.0, Color(0.95, 0.85, 0.2))
		var dir := Vector2(sin(player.rotation.y), cos(player.rotation.y)) * 10.0
		draw_line(pp, pp - dir, Color(1, 0.9, 0.3), 2.0)

func _w2m(world_pos: Vector3) -> Vector2:
	var nx := (world_pos.x / map_range) + 0.5
	var nz := (world_pos.z / map_range) + 0.5
	return Vector2(nx * size.x, nz * size.y)

func _color(t: String) -> Color:
	match t:
		"garage": return Color(0.3, 0.6, 1.0)
		"mission", "quest_marker": return Color(1.0, 0.3, 0.3)
		"shop": return Color(1.0, 0.6, 0.2)
		"city", "activity", "plaza": return Color(0.95, 0.8, 0.2)
		"race": return Color(0.3, 1.0, 0.5)
		_: return Color(0.7, 0.7, 0.75)
