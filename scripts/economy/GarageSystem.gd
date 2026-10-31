extends Node
## مرآب: تخزين مركبات مملوكة + استدعاء + لون بسيط
## يتكامل مع EconomyManager.owned_vehicles

signal vehicle_stored(id: String)
signal vehicle_spawned(id: String)

var stored: Array[String] = []
var paint_colors := {
	"black": Color(0.08, 0.08, 0.1),
	"gold": Color(0.85, 0.68, 0.15),
	"white": Color(0.9, 0.9, 0.92),
	"red": Color(0.7, 0.12, 0.12),
}
var selected_paint := "black"

func _ready() -> void:
	add_to_group("garage")

func refresh_from_economy() -> void:
	stored.clear()
	if EconomyManager:
		for id in EconomyManager.owned_vehicles:
			stored.append(str(id))

func store_current_near_player(player: Node3D) -> bool:
	if player == null:
		return false
	for v in player.get_tree().get_nodes_in_group("vehicle"):
		if v is Node3D and player.global_position.distance_to(v.global_position) < 6.0:
			var id: String = str(v.get("vehicle_id")) if v.get("vehicle_id") else str(v.name)
			if id not in stored:
				stored.append(id)
			if EconomyManager and not EconomyManager.owned_vehicles.has(id):
				EconomyManager.owned_vehicles.append(id)
			emit_signal("vehicle_stored", id)
			v.queue_free()
			return true
	return false

func list_stored() -> Array:
	refresh_from_economy()
	return stored.duplicate()

func set_paint(name: String) -> void:
	if paint_colors.has(name):
		selected_paint = name

func apply_paint_to(vehicle: Node) -> void:
	if vehicle == null:
		return
	var col: Color = paint_colors.get(selected_paint, paint_colors["black"])
	_paint_meshes(vehicle, col)

func _paint_meshes(n: Node, col: Color) -> void:
	if n is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.metallic = 0.4
		mat.roughness = 0.35
		(n as MeshInstance3D).material_override = mat
	for c in n.get_children():
		_paint_meshes(c, col)
